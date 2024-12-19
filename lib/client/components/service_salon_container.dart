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
  final List<Map<String, dynamic>> services; // Ensure this parameter exists
  final List<Map<String, dynamic>> stylists; // Ensure this parameter exists
  final String servicePrice;
  final String imageUrl;
  final String openTime;
  final String closeTime;
  final String userId;
  final String status;

  const ServiceSalonContainer({
    Key? key,
    required this.salonId,
    required this.salonName,
    required this.salonAddress,
    required this.rating,
    required this.serviceName,
    required this.servicePrice,
    required this.services,
    required this.stylists,
    required this.imageUrl,
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

      final todayOpenTime = DateTime(now.year, now.month, now.day,
          parsedOpenTime.hour, parsedOpenTime.minute);
      final todayCloseTime = DateTime(now.year, now.month, now.day,
          parsedCloseTime.hour, parsedCloseTime.minute);

      if (parsedCloseTime.isBefore(parsedOpenTime)) {
        final tomorrowCloseTime = todayCloseTime.add(const Duration(days: 1));
        return now.isAfter(todayOpenTime) && now.isBefore(tomorrowCloseTime);
      }

      return now.isAfter(todayOpenTime) && now.isBefore(todayCloseTime);
    } catch (e) {
      print('Error parsing times: $e');
      return false; // Assume closed if parsing fails
    }
  }

  Future<void> _navigateToSalonDetails(BuildContext context) async {
    try {
      // Fetch services and stylists dynamically
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

  Future<int> _fetchReviewCount(String salonId, String serviceName) async {
    try {
      // Fetch reviews for the specific service
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('reviews')
          .where('service', isEqualTo: serviceName)
          .get();

      // Debugging logs to verify the query results
      print(
          'Service Name: $serviceName, Review Count: ${snapshot.docs.length}');
      return snapshot.docs.length; // Return the count of reviews
    } catch (e) {
      print('Error fetching review count for service $serviceName: $e');
      return 0; // Return 0 if there's an error
    }
  }

  Future<Map<String, dynamic>> _fetchServiceRatingAndReviews(
      String salonId, String serviceName) async {
    try {
      // Fetch reviews for the specific service
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('reviews')
          .where('service', isEqualTo: serviceName)
          .get();

      // Calculate the rating for the specific service
      double totalRating = 0.0;
      int reviewCount = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        totalRating += (doc['rating'] ?? 0.0);
      }

      double averageRating = reviewCount > 0 ? totalRating / reviewCount : 0.0;

      return {
        'averageRating': averageRating,
        'reviewCount': reviewCount,
      };
    } catch (e) {
      print('Error fetching service rating for $serviceName: $e');
      return {
        'averageRating': 0.0,
        'reviewCount': 0,
      }; // Default values in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isOpen = _isSalonOpen(openTime, closeTime);

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
                      const SizedBox(height: 4),
                      if (serviceName.isNotEmpty && servicePrice.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              serviceName,
                              style: GoogleFonts.abel(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.green.shade700, width: 1),
                                  ),
                                  child: Text(
                                    'PHP $servicePrice',
                                    style: GoogleFonts.abel(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF388e3c),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FutureBuilder<Map<String, dynamic>>(
                                  future: _fetchServiceRatingAndReviews(
                                      salonId, serviceName),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.waiting ||
                                        !snapshot.hasData) {
                                      return const CircularProgressIndicator(
                                          strokeWidth: 1.5);
                                    }
                                    final data = snapshot.data!;
                                    final serviceRating =
                                        data['averageRating'] as double;
                                    final reviewCount =
                                        data['reviewCount'] as int;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.yellow.shade700,
                                            width: 1),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: Colors.yellow, size: 14),
                                          const SizedBox(width: 2),
                                          Text(
                                            serviceRating.toStringAsFixed(1),
                                            style: GoogleFonts.abel(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.yellow.shade800,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.person,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 2),
                                          Text(
                                            '$reviewCount',
                                            style: GoogleFonts.abel(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
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
                              // Handle location permission and navigation
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
        ));
  }
}
