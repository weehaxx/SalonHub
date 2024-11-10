import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:salon_hub/client/components/full_map_page.dart';
import 'package:salon_hub/client/salondetails_client.dart';
import 'package:intl/intl.dart';

class ServiceSalonContainer extends StatelessWidget {
  final String salonId;
  final String salonName;
  final String salonAddress;
  final double rating;
  final String serviceName;
  final String servicePrice;
  final String imageUrl;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> stylists;
  final String openTime;
  final String closeTime;
  final String userId;
  final String status; // Status from database, can be overridden by time check

  const ServiceSalonContainer({
    Key? key,
    required this.salonId,
    required this.salonName,
    required this.salonAddress,
    required this.rating,
    required this.serviceName,
    required this.servicePrice,
    required this.imageUrl,
    required this.services,
    required this.stylists,
    required this.openTime,
    required this.closeTime,
    required this.userId,
    required this.status,
  }) : super(key: key);

  bool _isSalonOpen(String openTime, String closeTime) {
    try {
      final now = DateTime.now();
      final dateFormat = DateFormat("h:mm a");
      final parsedOpenTime = dateFormat.parse(openTime);
      final parsedCloseTime = dateFormat.parse(closeTime);

      // Adjust the parsed times to today's date for comparison
      final todayOpenTime = DateTime(now.year, now.month, now.day,
          parsedOpenTime.hour, parsedOpenTime.minute);
      final todayCloseTime = DateTime(now.year, now.month, now.day,
          parsedCloseTime.hour, parsedCloseTime.minute);

      // Handle cases where close time is past midnight (e.g., open at 8 PM, close at 2 AM)
      if (parsedCloseTime.isBefore(parsedOpenTime)) {
        final tomorrowCloseTime = todayCloseTime.add(Duration(days: 1));
        return now.isAfter(todayOpenTime) && now.isBefore(tomorrowCloseTime);
      }

      return now.isAfter(todayOpenTime) && now.isBefore(todayCloseTime);
    } catch (e) {
      print('Error parsing times: $e');
      return false; // Assume closed if parsing fails
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

  Future<List<Map<String, dynamic>>> fetchServices(String salonId) async {
    QuerySnapshot servicesSnapshot = await FirebaseFirestore.instance
        .collection('salon')
        .doc(salonId)
        .collection('services')
        .get();

    return servicesSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchStylists(String salonId) async {
    QuerySnapshot stylistsSnapshot = await FirebaseFirestore.instance
        .collection('salon')
        .doc(salonId)
        .collection('stylists')
        .get();

    return stylistsSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    bool isOpen = _isSalonOpen(
        openTime, closeTime); // Check if salon is open based on current time

    return SizedBox(
      width: 200,
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
                    // Display "OPEN NOW" or "CLOSED" based on time check with color
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
                    const SizedBox(height: 6),
                    if (serviceName.isNotEmpty && servicePrice.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service: $serviceName',
                            style: GoogleFonts.abel(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Price: PHP $servicePrice',
                            style: GoogleFonts.abel(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
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
                            onPressed: () async {
                              List<Map<String, dynamic>> servicesData =
                                  await fetchServices(salonId);
                              List<Map<String, dynamic>> stylistsData =
                                  await fetchStylists(salonId);

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
