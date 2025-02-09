import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_hub/client/components/salon_container.dart';
import 'package:geolocator/geolocator.dart';

class PersonalizedSalonsPage extends StatefulWidget {
  const PersonalizedSalonsPage({Key? key}) : super(key: key);

  @override
  State<PersonalizedSalonsPage> createState() => _PersonalizedSalonsPageState();
}

class _PersonalizedSalonsPageState extends State<PersonalizedSalonsPage> {
  List<Map<String, dynamic>> _matchedPreferenceSalons = [];
  List<Map<String, dynamic>> _otherUserPreferenceSalons = [];
  bool _isLoading = true;
  Position? _userLocation;

  @override
  void initState() {
    super.initState();
    _fetchMatchedSalons();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Equivalent to the previous setting
      distanceFilter: 10, // Minimum distance (in meters) before an update
    );

    _userLocation =
        await Geolocator.getCurrentPosition(locationSettings: locationSettings);

    print('Fetching client location...');
    print(
        'Client Location: Latitude ${_userLocation?.latitude}, Longitude ${_userLocation?.longitude}');
  }

  Future<void> _fetchMatchedSalons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Fetch current user's preferences
      print('Retrieving client preferences...');
      final userPreferenceDoc = await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(userId)
          .get();

      if (!userPreferenceDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userPreferences = userPreferenceDoc.data()!;
      final String? preferredGender = userPreferences['gender'];
      final double preferredSalonRating =
          (userPreferences['preferred_salon_rating'] ?? 0).toDouble();
      final double preferredServiceRating =
          (userPreferences['preferred_service_rating'] ?? 0).toDouble();
      final List<String> preferredServices =
          List<String>.from(userPreferences['preferred_services'] ?? []);

      print('Preferred Gender: $preferredGender');
      print('Preferred Salon Rating: $preferredSalonRating');
      print('Preferred Service Rating: $preferredServiceRating');
      print('Preferred Services: ${preferredServices.join(", ")}');

      // Fetch all user interactions
      final userInteractionsSnapshot =
          await FirebaseFirestore.instance.collection('user_interaction').get();

      final Set<String> matchedSalonIds = {};
      final otherUserPreferenceSalons = <Map<String, dynamic>>[];

      for (final interactionDoc in userInteractionsSnapshot.docs) {
        final interactionData = interactionDoc.data();
        final List<String> bookmarkedSalons =
            List<String>.from(interactionData['bookmarked_salons'] ?? []);
        final List<dynamic> reviewedServices =
            List<dynamic>.from(interactionData['reviewed_services'] ?? []);

        matchedSalonIds.addAll(bookmarkedSalons);

        for (final reviewedService in reviewedServices) {
          final String serviceName = reviewedService['serviceName'] ?? '';
          final String mainCategory = reviewedService['main_category'] ?? '';

          if (preferredServices.contains(serviceName) &&
              (preferredGender == null || preferredGender == mainCategory)) {
            matchedSalonIds.add(reviewedService['salonId']);
          }
        }
      }

      final salonSnapshot =
          await FirebaseFirestore.instance.collection('salon').get();

      final matchedPreferenceSalons = <Map<String, dynamic>>[];

      for (final salonDoc in salonSnapshot.docs) {
        final salonData = salonDoc.data();
        final salonId = salonDoc.id;

        if (salonData['isBanned'] == true) continue;

        final reviewsSnapshot =
            await salonDoc.reference.collection('reviews').get();
        double totalSalonRating = 0;
        for (final review in reviewsSnapshot.docs) {
          totalSalonRating += (review['rating'] ?? 0).toDouble();
        }
        final double salonRating = reviewsSnapshot.docs.isNotEmpty
            ? totalSalonRating / reviewsSnapshot.docs.length
            : 0;

        final servicesSnapshot =
            await salonDoc.reference.collection('services').get();

        bool hasMatchingPreferredService = false;

        for (final serviceDoc in servicesSnapshot.docs) {
          final serviceData = serviceDoc.data();
          final String serviceName = serviceData['name'] ?? '';
          final String mainCategory = serviceData['main_category'] ?? '';

          if (preferredServices.contains(serviceName) &&
              (preferredGender == null || preferredGender == mainCategory)) {
            hasMatchingPreferredService = true;
          }
        }

        final salonInfo = {
          'salon_id': salonId,
          'salon_name': salonData['salon_name'] ?? 'Unknown Salon',
          'address': salonData['address'] ?? 'No Address Available',
          'image_url': salonData['image_url'] ?? '',
          'rating': salonRating,
          'open_time': salonData['open_time'] ?? 'Unknown',
          'close_time': salonData['close_time'] ?? 'Unknown',
          'specialization': salonData['specialization'] ?? 'General',
          'latitude': salonData['latitude'] ?? 0.0,
          'longitude': salonData['longitude'] ?? 0.0,
        };

        if (salonRating >= preferredSalonRating ||
            hasMatchingPreferredService) {
          matchedPreferenceSalons.add(salonInfo);
        }

        if (matchedSalonIds.contains(salonId)) {
          otherUserPreferenceSalons.add(salonInfo);
        }
      }

      print('Identifying closer salon locations using KNN...');
      print('Total salons retrieved: ${matchedPreferenceSalons.length}');

      if (_userLocation != null) {
        matchedPreferenceSalons.sort((a, b) {
          final distanceA = _calculateDistance(_userLocation!.latitude,
              _userLocation!.longitude, a['latitude'], a['longitude']);
          final distanceB = _calculateDistance(_userLocation!.latitude,
              _userLocation!.longitude, b['latitude'], b['longitude']);
          return distanceA.compareTo(distanceB);
        });

        print('KNN Results: Recommended Salons Based on Client Preferences');
        for (int i = 0; i < 3 && i < matchedPreferenceSalons.length; i++) {
          final salon = matchedPreferenceSalons[i];
          final distance = _calculateDistance(
            _userLocation!.latitude,
            _userLocation!.longitude,
            salon['latitude'],
            salon['longitude'],
          ).toStringAsFixed(2);

          print(
              'Rank ${i + 1}: ${salon['salon_name']} | Distance: $distance km');
        }
      }

      if (_otherUserPreferenceSalons.isNotEmpty) {
        print('Listing salons that align with other clients’ preferences:');
        for (final salon in _otherUserPreferenceSalons) {
          print('- ${salon['salon_name']} | Rating: ${salon['rating']}');
        }
      } else {
        print('No salons found that match other clients’ preferences.');
      }

      setState(() {
        _matchedPreferenceSalons = matchedPreferenceSalons;
        _otherUserPreferenceSalons = otherUserPreferenceSalons;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching matched salons: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distance / 1000; // Convert to kilometers
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchMatchedSalons,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  if (_matchedPreferenceSalons.isNotEmpty) ...[
                    Text(
                      "Salons Matching Your Preferences",
                      style: GoogleFonts.abel(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 340,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _matchedPreferenceSalons.length,
                        itemBuilder: (context, index) {
                          final salon = _matchedPreferenceSalons[index];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: SizedBox(
                              width: 300,
                              child: SalonContainer(
                                key: UniqueKey(),
                                salonId: salon['salon_id'],
                                salon: salon,
                                rating: salon['rating'],
                                userId:
                                    FirebaseAuth.instance.currentUser?.uid ??
                                        '',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_otherUserPreferenceSalons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Salons Matching Other Users' Preferences",
                      style: GoogleFonts.abel(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 340,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _otherUserPreferenceSalons.length,
                        itemBuilder: (context, index) {
                          final salon = _otherUserPreferenceSalons[index];
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: SizedBox(
                              width: 300,
                              child: SalonContainer(
                                key: UniqueKey(),
                                salonId: salon['salon_id'],
                                salon: salon,
                                rating: salon['rating'],
                                userId:
                                    FirebaseAuth.instance.currentUser?.uid ??
                                        '',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_matchedPreferenceSalons.isEmpty &&
                      _otherUserPreferenceSalons.isEmpty)
                    Center(
                      child: Text(
                        "No matched salons found.",
                        style: GoogleFonts.abel(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
