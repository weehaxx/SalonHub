import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_hub/client/components/salon_container.dart';

class PersonalizedSalonsPage extends StatefulWidget {
  const PersonalizedSalonsPage({Key? key}) : super(key: key);

  @override
  State<PersonalizedSalonsPage> createState() => _PersonalizedSalonsPageState();
}

class _PersonalizedSalonsPageState extends State<PersonalizedSalonsPage> {
  List<Map<String, dynamic>> _matchedPreferenceSalons = [];
  List<Map<String, dynamic>> _matchedInteractionSalons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatchedSalons();
  }

  Future<void> _fetchMatchedSalons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Fetch current user's preferences
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

      // Fetch all user interactions
      final userInteractionsSnapshot =
          await FirebaseFirestore.instance.collection('user_interaction').get();

      final Set<String> matchedSalonIds = {};
      final matchedInteractionSalons = <Map<String, dynamic>>[];

      for (final interactionDoc in userInteractionsSnapshot.docs) {
        final interactionData = interactionDoc.data();
        final List<String> bookmarkedSalons =
            List<String>.from(interactionData['bookmarked_salons'] ?? []);
        final List<dynamic> reviewedServices =
            List<dynamic>.from(interactionData['reviewed_services'] ?? []);

        // Match current user's preferences with bookmarked or reviewed salons
        for (final bookmarkedSalon in bookmarkedSalons) {
          matchedSalonIds.add(bookmarkedSalon);
        }

        for (final reviewedService in reviewedServices) {
          final String serviceName = reviewedService['serviceName'] ?? '';
          final String mainCategory = reviewedService['main_category'] ?? '';

          if (preferredServices.contains(serviceName) &&
              (preferredGender == null || preferredGender == mainCategory)) {
            matchedSalonIds.add(reviewedService['salonId']);
          }
        }
      }

      // Fetch salons
      final salonSnapshot =
          await FirebaseFirestore.instance.collection('salon').get();

      final matchedPreferenceSalons = <Map<String, dynamic>>[];

      for (final salonDoc in salonSnapshot.docs) {
        final salonData = salonDoc.data();
        final salonId = salonDoc.id;

        // Skip banned salons
        if (salonData['isBanned'] == true) continue;

        // Calculate salon average rating from reviews
        final reviewsSnapshot =
            await salonDoc.reference.collection('reviews').get();
        double totalSalonRating = 0;
        for (final review in reviewsSnapshot.docs) {
          totalSalonRating += (review['rating'] ?? 0).toDouble();
        }
        final double salonRating = reviewsSnapshot.docs.isNotEmpty
            ? totalSalonRating / reviewsSnapshot.docs.length
            : 0;

        // Fetch services and check if at least one matches the preferred services with a valid rating
        final servicesSnapshot =
            await salonDoc.reference.collection('services').get();

        bool hasMatchingPreferredService = false;

        for (final serviceDoc in servicesSnapshot.docs) {
          final serviceData = serviceDoc.data();
          final String serviceName = serviceData['name'] ?? '';
          final String mainCategory = serviceData['main_category'] ?? '';

          if (preferredServices.contains(serviceName) &&
              (preferredGender == null || preferredGender == mainCategory)) {
            // Calculate the average rating of the service
            final serviceReviewsSnapshot = await salonDoc.reference
                .collection('reviews')
                .where('serviceId', isEqualTo: serviceDoc.id)
                .get();

            double totalServiceRating = 0;
            for (final review in serviceReviewsSnapshot.docs) {
              totalServiceRating += (review['rating'] ?? 0).toDouble();
            }
            final double averageServiceRating =
                serviceReviewsSnapshot.docs.isNotEmpty
                    ? totalServiceRating / serviceReviewsSnapshot.docs.length
                    : 0;

            // Check if the average service rating meets the user's preference
            if (averageServiceRating >= preferredServiceRating &&
                averageServiceRating < (preferredServiceRating + 1)) {
              hasMatchingPreferredService = true;
              break;
            }
          }
        }

        // Check if the salon matches user's preferred rating and has a matching service
        if (salonRating >= preferredSalonRating &&
            salonRating < (preferredSalonRating + 1) &&
            hasMatchingPreferredService) {
          final salonInfo = {
            'salon_id': salonId,
            'salon_name': salonData['salon_name'] ?? 'Unknown Salon',
            'address': salonData['address'] ?? 'No Address Available',
            'image_url': salonData['image_url'] ?? '',
            'rating': salonRating,
            'open_time': salonData['open_time'] ?? 'Unknown',
            'close_time': salonData['close_time'] ?? 'Unknown',
          };

          // Add to matched preference salons
          matchedPreferenceSalons.add(salonInfo);

          // Add to matched interaction salons if it matches the interaction
          if (matchedSalonIds.contains(salonId)) {
            matchedInteractionSalons.add(salonInfo);
          }
        }
      }

      setState(() {
        _matchedPreferenceSalons = matchedPreferenceSalons;
        _matchedInteractionSalons = matchedInteractionSalons;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching matched salons: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
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
                    height: 310,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _matchedPreferenceSalons.length,
                      itemBuilder: (context, index) {
                        final salon = _matchedPreferenceSalons[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            width: 300,
                            child: SalonContainer(
                              key: UniqueKey(),
                              salonId: salon['salon_id'],
                              salon: salon,
                              rating: salon['rating'],
                              userId:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (_matchedInteractionSalons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Salons Matching Preferences & Interactions",
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 310,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _matchedInteractionSalons.length,
                      itemBuilder: (context, index) {
                        final salon = _matchedInteractionSalons[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            width: 300,
                            child: SalonContainer(
                              key: UniqueKey(),
                              salonId: salon['salon_id'],
                              salon: salon,
                              rating: salon['rating'],
                              userId:
                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                if (_matchedPreferenceSalons.isEmpty &&
                    _matchedInteractionSalons.isEmpty)
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
    );
  }
}
