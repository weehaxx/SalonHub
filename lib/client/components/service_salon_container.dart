import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ServiceSalonContainer extends StatelessWidget {
  final String salonId;
  final String salonName;
  final String salonAddress; // Correct field name for address
  final double rating;
  final String serviceName;
  final String servicePrice;
  final String imageUrl;

  const ServiceSalonContainer({
    Key? key,
    required this.salonId,
    required this.salonName,
    required this.salonAddress,
    required this.rating,
    required this.serviceName,
    required this.servicePrice,
    required this.imageUrl,
    required address,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        width: 200,
        height: 320, // Adjusted width to fit horizontally
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
            // Salon Image Section with Rating at the upper right
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
                          height: 100, // Adjusted height for image
                          width: double.infinity,
                          fit: BoxFit
                              .cover, // Ensure the image fits the container
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/default_salon.jpg',
                              height: 100, // Same height for fallback image
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/default_salon.jpg',
                          height: 100, // Set height for default image
                          width: double.infinity,
                          fit: BoxFit
                              .cover, // Fit the image inside the container
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8, // Move rating to the upper right
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
            // Salon Name and Open Hours Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                      height: 8), // Added spacing between image and text
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
                    'OPEN NOW - 8:00 AM - 5:30 PM',
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
            // Salon Address
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
            // Service and Price Information
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
            // Action Buttons Section (Location and See Details)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.location_on,
                      color: Color(0xff355E3B),
                      size: 18, // Smaller icon size
                    ),
                    onPressed: () {
                      // Add location action here if necessary
                    },
                  ),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement the navigation logic for details
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff355E3B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8), // Adjust padding
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white,
                            size: 12, // Smaller icon
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'SEE DETAILS',
                            style: GoogleFonts.abel(
                              fontSize: 12, // Smaller text size
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
