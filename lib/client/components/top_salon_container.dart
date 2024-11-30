import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:salon_hub/client/components/full_map_page.dart';
import 'package:salon_hub/client/salondetails_client.dart';
import 'package:intl/intl.dart';

class TopSalonContainer extends StatelessWidget {
  final String salonId;
  final String salonName;
  final String salonAddress;
  final double rating;
  final String imageUrl;
  final List<Map<String, dynamic>> services; // Ensure this parameter exists
  final List<Map<String, dynamic>> stylists; // Ensure this parameter exists
  final String openTime;
  final String closeTime;
  final String userId;
  final String status;

  const TopSalonContainer({
    Key? key,
    required this.salonId,
    required this.salonName,
    required this.salonAddress,
    required this.rating,
    required this.imageUrl,
    required this.openTime,
    required this.services,
    required this.stylists,
    required this.closeTime,
    required this.userId,
    required this.status,
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
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        DocumentSnapshot salonData = await FirebaseFirestore.instance
            .collection('salon')
            .doc(salonId)
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

  Future<void> _navigateToSalonDetails(BuildContext context) async {
    try {
      // Fetch services and stylists from Firestore
      List<Map<String, dynamic>> servicesData = await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('services')
          .get()
          .then((snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList());

      List<Map<String, dynamic>> stylistsData = await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('stylists')
          .get()
          .then((snapshot) => snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList());

      // Print fetched data for debugging
      print("Salon ID: $salonId");
      print("Services: $servicesData");
      print("Stylists: $stylistsData");

      // Navigate to SalonDetailsClient
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SalondetailsClient(
            salonId: salonId,
            salonName: salonName,
            address: salonAddress,
            services: servicesData,
            stylists: stylistsData,
            openTime: openTime,
            closeTime: closeTime,
            userId: userId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load salon details')),
      );
      print('Error navigating to details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOpen = _isSalonOpen(openTime, closeTime);

    return SizedBox(
      width: 217,
      child: Padding(
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
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/default_salon.jpg',
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/default_salon.jpg',
                            height: 100,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.yellow, size: 14),
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
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salonName,
                      style: GoogleFonts.abel(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOpen
                          ? 'OPEN NOW - $openTime - $closeTime'
                          : 'CLOSED - $openTime - $closeTime',
                      style: GoogleFonts.abel(
                        fontSize: 10,
                        color: isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.grey, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            salonAddress,
                            style: GoogleFonts.abel(
                              fontSize: 10,
                              color: Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.location_on,
                            color: Color(0xff355E3B),
                            size: 18,
                          ),
                          onPressed: () {
                            _handleLocationPermission(context);
                          },
                        ),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () {
                              _navigateToSalonDetails(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff355E3B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.remove_red_eye,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'SEE DETAILS',
                                  style: GoogleFonts.abel(
                                    fontSize: 12,
                                    color: Colors.white,
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
      ),
    );
  }
}
