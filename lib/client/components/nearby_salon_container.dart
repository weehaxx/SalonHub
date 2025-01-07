import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/components/full_map_page.dart';
import 'package:salon_hub/client/salonDetails_client.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // For time formatting and parsing

class NearbySalonContainer extends StatelessWidget {
  final String salonId;
  final double rating;
  final Map<String, dynamic> salon;
  final String userId;
  final double? distance;

  const NearbySalonContainer({
    required Key key,
    required this.salonId,
    required this.rating,
    required this.salon,
    required this.userId,
    this.distance,
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

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullMapPage(
              userLocation: LatLng(position.latitude, position.longitude),
              salonLocation: LatLng(
                salon['latitude'],
                salon['longitude'],
              ),
              salonName: salon['salon_name'] ?? 'Unknown Salon',
            ),
          ),
        );
      } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final salonName = salon['salon_name']?.toString() ?? 'Unknown Salon';
    final salonAddress = salon['address']?.toString() ?? 'No Address Available';
    final openTime = salon['open_time']?.toString() ?? '9:00 AM';
    final closeTime = salon['close_time']?.toString() ?? '9:00 PM';
    final services = (salon['services'] ?? [])
        .map<Map<String, dynamic>>((service) =>
            Map<String, dynamic>.from(service as Map<String, dynamic>))
        .toList();
    final stylists = (salon['stylists'] ?? [])
        .map<Map<String, dynamic>>((stylist) =>
            Map<String, dynamic>.from(stylist as Map<String, dynamic>))
        .toList();
    final imageUrl = salon['image_url']?.toString();
    final double? distanceKm = distance;

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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${distanceKm.toStringAsFixed(2)} km away',
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SalondetailsClient(
                                  salonId: salonId,
                                  salonName: salonName,
                                  address: salonAddress,
                                  services: services,
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
                      )
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
