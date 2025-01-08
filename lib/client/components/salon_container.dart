import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:salon_hub/client/components/full_map_page.dart';
import 'package:salon_hub/client/salonDetails_client.dart';
import 'package:intl/intl.dart';

class SalonContainer extends StatefulWidget {
  final String salonId;
  final double rating;
  final Map<String, dynamic> salon;
  final String userId;
  final double? distance;

  const SalonContainer({
    required Key key,
    required this.salonId,
    required this.rating,
    required this.salon,
    required this.userId,
    this.distance,
  }) : super(key: key);

  @override
  State<SalonContainer> createState() => _SalonContainerState();
}

class _SalonContainerState extends State<SalonContainer> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked();
  }

  Future<void> _checkIfBookmarked() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user_interaction')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final bookmarkedSalons =
            List<String>.from(userDoc.data()?['bookmarked_salons'] ?? []);
        setState(() {
          _isBookmarked = bookmarkedSalons.contains(widget.salonId);
        });
      }
    } catch (e) {
      print("Error checking bookmark status: $e");
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('user_interaction')
          .doc(widget.userId);

      if (_isBookmarked) {
        await userDocRef.update({
          'bookmarked_salons': FieldValue.arrayRemove([widget.salonId]),
        });
      } else {
        await userDocRef.set({
          'bookmarked_salons': FieldValue.arrayUnion([widget.salonId]),
        }, SetOptions(merge: true));
      }

      setState(() {
        _isBookmarked = !_isBookmarked;
      });
    } catch (e) {
      print("Error toggling bookmark: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update bookmark.')),
      );
    }
  }

  Future<void> _handleLocationPermission(BuildContext context) async {
    if (await Permission.location.request().isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        DocumentSnapshot salonData = await FirebaseFirestore.instance
            .collection('salon')
            .doc(widget.salonId)
            .get();

        if (salonData.exists) {
          double? salonLatitude = salonData['latitude'];
          double? salonLongitude = salonData['longitude'];
          String salonName = salonData['salon_name'] ?? 'Unknown Salon';

          if (salonLatitude != null && salonLongitude != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullMapPage(
                  userLocation: LatLng(position.latitude, position.longitude),
                  salonLocation: LatLng(salonLatitude, salonLongitude),
                  salonName: salonName,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Salon location is incomplete')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Salon location not found')),
          );
        }
      } catch (e) {
        print('Error fetching salon data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retrieve salon location')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
    }
  }

  bool _isSalonOpen(String openTime, String closeTime) {
    final DateFormat dateFormat = DateFormat('h:mm a');
    try {
      DateTime now = DateTime.now();
      DateTime open = dateFormat.parse(openTime);
      DateTime close = dateFormat.parse(closeTime);

      open = DateTime(now.year, now.month, now.day, open.hour, open.minute);
      close = DateTime(now.year, now.month, now.day, close.hour, close.minute);

      if (close.isBefore(open)) {
        close = close.add(const Duration(days: 1));
      }

      return now.isAfter(open) && now.isBefore(close);
    } catch (e) {
      print('Error parsing open/close time: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely handle salon fields with default values
    final salonName = widget.salon['salon_name']?.toString() ?? 'Unknown Salon';
    final salonAddress =
        widget.salon['address']?.toString() ?? 'No Address Available';
    final openTime = widget.salon['open_time']?.toString() ?? 'Unknown';
    final closeTime = widget.salon['close_time']?.toString() ?? 'Unknown';
    final imageUrl = widget.salon['image_url']?.toString();
    final distance = widget.distance?.toStringAsFixed(2) ?? 'Unknown';

    bool isOpen = _isSalonOpen(openTime, closeTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/default_salon.jpg',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/default_salon.jpg',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          widget.rating.toStringAsFixed(1),
                          style: GoogleFonts.abel(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOpen
                        ? 'OPEN NOW - $openTime - $closeTime'
                        : 'CLOSED - $openTime - $closeTime',
                    style: GoogleFonts.abel(
                      textStyle: TextStyle(
                        color: isOpen ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    salonName,
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          salonAddress,
                          style: GoogleFonts.abel(
                            textStyle: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.distance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$distance km away',
                        style: GoogleFonts.abel(
                          textStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.location_on,
                              color: Color(0xff355E3B),
                            ),
                            onPressed: () {
                              _handleLocationPermission(context);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _isBookmarked
                                  ? Colors.black
                                  : const Color(0xff355E3B),
                            ),
                            onPressed: _toggleBookmark,
                          ),
                        ],
                      ),
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final salonDoc = await FirebaseFirestore.instance
                                  .collection('salon')
                                  .doc(widget.salonId)
                                  .get();

                              if (salonDoc.exists) {
                                final stylistsSnapshot = await salonDoc
                                    .reference
                                    .collection('stylists')
                                    .get();

                                final stylists =
                                    stylistsSnapshot.docs.map((doc) {
                                  final data = doc.data();
                                  return {
                                    'id': doc.id,
                                    'name': data['name'] ?? 'Unknown Stylist',
                                    'specialization':
                                        data['specialization'] ?? 'N/A',
                                    'status': data['status'] ?? 'Unavailable',
                                  };
                                }).toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SalondetailsClient(
                                      salonId: widget.salonId,
                                      salonName: salonName,
                                      address: salonAddress,
                                      services: widget.salon['services'] ?? [],
                                      stylists: stylists,
                                      openTime: openTime,
                                      closeTime: closeTime,
                                      userId: widget.userId,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Salon not found')),
                                );
                              }
                            } catch (e) {
                              print('Error fetching salon details: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Failed to fetch salon details')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff355E3B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.remove_red_eye,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'SEE DETAILS',
                                style: GoogleFonts.abel(
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
