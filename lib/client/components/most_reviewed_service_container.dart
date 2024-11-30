import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/salondetails_client.dart';
import 'package:intl/intl.dart'; // For parsing and formatting time

class MostReviewedServiceContainer extends StatelessWidget {
  final String salonId;
  final String salonName;
  final String salonAddress;
  final double rating;
  final String popularServiceName;
  final String imageUrl;
  final String openTime;
  final String closeTime;
  final String userId;
  final String status; // Added status parameter

  const MostReviewedServiceContainer({
    Key? key,
    required this.salonId,
    required this.salonName,
    required this.salonAddress,
    required this.rating,
    required this.popularServiceName,
    required this.imageUrl,
    required this.openTime,
    required this.closeTime,
    required this.userId,
    required this.status, // Initialize the status parameter
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

      // Debugging: Print fetched data
      print("Fetched Services: $servicesData");
      print("Fetched Stylists: $stylistsData");

      // Navigate to SalondetailsClient with fetched data
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
                    // Display status with respective color
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
                    const SizedBox(height: 8),
                    Text(
                      'Popular Service: $popularServiceName',
                      style: GoogleFonts.abel(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () async {
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
