import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:salon_hub/client/components/full_map_page.dart';
import 'package:salon_hub/client/salonDetails_client.dart';
import 'package:intl/intl.dart'; // For parsing and formatting time

class SalonContainer extends StatelessWidget {
  final String salonId;
  final double rating;
  final Map<String, dynamic> salon;
  final String userId; // Add userId here
  final double? distance; // Add the distance parameter

  const SalonContainer({
    required Key key,
    required this.salonId,
    required this.rating,
    required this.salon,
    required this.userId, // Pass userId here
    this.distance, // Add distance here
  }) : super(key: key);

  bool _isSalonOpen(String openTime, String closeTime) {
    final DateFormat dateFormat = DateFormat('h:mm a');
    try {
      DateTime now = DateTime.now();
      DateTime open = dateFormat.parse(openTime);
      DateTime close = dateFormat.parse(closeTime);

      open = DateTime(now.year, now.month, now.day, open.hour, open.minute);
      close = DateTime(now.year, now.month, now.day, close.hour, close.minute);

      // Handle overnight closing time (e.g., 11:00 PM to 4:00 AM)
      if (close.isBefore(open)) {
        close = close.add(Duration(days: 1));
      }

      return now.isAfter(open) && now.isBefore(close);
    } catch (e) {
      print('Error parsing open/close time: $e');
      return false;
    }
  }

  Future<void> _handleLocationPermission(BuildContext context) async {
    if (await Permission.location.request().isGranted) {
      try {
        // Get user's current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Fetch salon location and name from Firestore
        DocumentSnapshot salonData = await FirebaseFirestore.instance
            .collection('salon')
            .doc(
                salonId) // Ensure this matches the UID used in `form_owner.dart`
            .get();

        if (salonData.exists) {
          // Retrieve latitude, longitude, and salon name from Firestore
          double? salonLatitude = salonData['latitude'];
          double? salonLongitude = salonData['longitude'];
          String salonName = salonData['salon_name'] ?? 'Unknown Salon';

          if (salonLatitude != null && salonLongitude != null) {
            // Navigate to FullMapPage with user's and salon's location
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullMapPage(
                  userLocation: LatLng(position.latitude, position.longitude),
                  salonLocation: LatLng(salonLatitude, salonLongitude),
                  salonName: salonName, // Pass the salon name here
                ),
              ),
            );
          } else {
            print('Error: Latitude or longitude is missing for salon $salonId');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Salon location is incomplete')),
            );
          }
        } else {
          print('Error: No salon document found for ID $salonId');
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
        const SnackBar(
            content: Text('Location permission is required to continue')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final salonName = salon['salon_name'] ?? 'Unknown Salon';
    final salonAddress = salon['address'] ?? 'No Address Available';
    final openTime = salon['open_time'] ?? 'Unknown';
    final closeTime = salon['close_time'] ?? 'Unknown';
    final imageUrl = salon['image_url'];

    // Ensure services and stylists are properly cast to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> services = (salon['services'] ?? [])
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    final List<Map<String, dynamic>> stylists = (salon['stylists'] ?? [])
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    bool isOpen = _isSalonOpen(openTime, closeTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          rating.toStringAsFixed(1),
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
                                fontWeight: FontWeight.bold),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (distance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_walk,
                              color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${distance!.toStringAsFixed(2)} km away',
                            style: GoogleFonts.abel(
                              textStyle: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              // Fetch the salon document
                              final salonDoc = await FirebaseFirestore.instance
                                  .collection('salon')
                                  .doc(salonId)
                                  .get();

                              if (salonDoc.exists) {
                                // Extract stylist data
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

                                // Navigate to salon details
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SalondetailsClient(
                                      salonId: salon['salon_id'],
                                      salonName: salon['salon_name'],
                                      address: salon['address'],
                                      services: salon['services'] ?? [],
                                      stylists: stylists, // Pass stylists here
                                      openTime: salon['open_time'],
                                      closeTime: salon['close_time'],
                                      userId: FirebaseAuth
                                              .instance.currentUser?.uid ??
                                          '',
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
                              print('Error fetching salon or stylists: $e');
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
