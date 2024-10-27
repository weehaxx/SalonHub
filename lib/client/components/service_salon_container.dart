import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/salondetails_client.dart';

class ServiceSalonContainer extends StatelessWidget {
  final String salonId;
  final String salonName;
  final String salonAddress;
  final double rating;
  final String serviceName;
  final String servicePrice;
  final String imageUrl;
  final List<Map<String, dynamic>> services; // Ensure services are passed
  final List<Map<String, dynamic>> stylists;
  final String openTime;
  final String closeTime;
  final String userId;

  const ServiceSalonContainer({
    Key? key,
    required this.salonId,
    required this.salonName,
    required this.salonAddress,
    required this.rating,
    required this.serviceName,
    required this.servicePrice,
    required this.imageUrl,
    required this.services, // Ensure services are passed
    required this.stylists,
    required this.openTime,
    required this.closeTime,
    required this.userId,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        height: 320,
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
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    salonName,
                    style: GoogleFonts.abel(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Use dynamic open and close times
                  Text(
                    'OPEN NOW - $openTime - $closeTime',
                    style: GoogleFonts.abel(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey, size: 12),
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
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
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
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.location_on,
                      color: Color(0xff355E3B),
                      size: 18,
                    ),
                    onPressed: () {
                      // Location action here
                    },
                  ),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () async {
                        List<Map<String, dynamic>> servicesData =
                            await fetchServices(salonId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SalondetailsClient(
                              salonId: salonId,
                              salonName: salonName,
                              address: salonAddress,
                              services: servicesData, // Pass fetched services
                              stylists: stylists,
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
            ),
          ],
        ),
      ),
    );
  }
}
