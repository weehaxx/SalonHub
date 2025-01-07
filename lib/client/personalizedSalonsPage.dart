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
  List<Map<String, dynamic>> _matchedSalons = [];
  List<Map<String, dynamic>> _unmatchedSalons = [];
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

      // Fetch user preferences
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

      // Fetch salons
      final salonSnapshot =
          await FirebaseFirestore.instance.collection('salon').get();

      final matchedSalons = <Map<String, dynamic>>[];
      final unmatchedSalons = <Map<String, dynamic>>[];

      for (final salonDoc in salonSnapshot.docs) {
        final salonData = salonDoc.data();
        final reasonsForUnmatch = <String>[];

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

        if (salonRating < preferredSalonRating) {
          reasonsForUnmatch.add(
              "Salon rating (${salonRating.toStringAsFixed(1)}) is below preferred rating ($preferredSalonRating).");
        }

        // Check services and match with preferences
        final servicesSnapshot =
            await salonDoc.reference.collection('services').get();

        bool hasAtLeastOneMatchingService = false;

        for (final preferredService in preferredServices) {
          bool serviceMatched = false; // Track if this specific service matches

          for (final serviceDoc in servicesSnapshot.docs) {
            final serviceData = serviceDoc.data();
            final String? serviceGender = serviceData['main_category'];
            final String serviceName = serviceData['name'] ?? '';
            final String serviceId = serviceDoc.id;

            if (preferredService == serviceName) {
              // Calculate service average rating
              final serviceReviewsSnapshot = await salonDoc.reference
                  .collection('reviews')
                  .where('serviceId', isEqualTo: serviceId)
                  .get();
              double totalServiceRating = 0.0;
              for (final review in serviceReviewsSnapshot.docs) {
                totalServiceRating += (review['rating'] ?? 0).toDouble();
              }
              final double serviceRating =
                  serviceReviewsSnapshot.docs.isNotEmpty
                      ? totalServiceRating / serviceReviewsSnapshot.docs.length
                      : 0;

              if (serviceRating >= preferredServiceRating) {
                if (preferredGender == null ||
                    preferredGender == serviceGender) {
                  serviceMatched = true;
                  hasAtLeastOneMatchingService = true;
                  break; // No need to check further for this preferred service
                } else {
                  reasonsForUnmatch.add(
                      "Service gender (${serviceGender ?? 'Unknown'}) does not match preferred gender ($preferredGender).");
                }
              } else {
                reasonsForUnmatch.add(
                    "Service rating (${serviceRating.toStringAsFixed(1)}) for '$serviceName' is below preferred rating ($preferredServiceRating).");
              }
            }
          }

          if (!serviceMatched) {
            reasonsForUnmatch.add(
                "Preferred service '$preferredService' does not match any salon services.");
          }
        }

        if (hasAtLeastOneMatchingService) {
          matchedSalons.add({
            'salon_id': salonDoc.id,
            'salon_name': salonData['salon_name'] ?? 'Unknown Salon',
            'address': salonData['address'] ?? 'No Address Available',
            'image_url': salonData['image_url'] ?? '',
            'rating': salonRating,
          });
        } else {
          unmatchedSalons.add({
            'salon_id': salonDoc.id,
            'salon_name': salonData['salon_name'] ?? 'Unknown Salon',
            'address': salonData['address'] ?? 'No Address Available',
            'image_url': salonData['image_url'] ?? '',
            'rating': salonRating,
            'reasons': reasonsForUnmatch,
          });
        }
      }

      setState(() {
        _matchedSalons = matchedSalons;
        _unmatchedSalons = unmatchedSalons;
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
      appBar: AppBar(
        title: Text(
          "Personalized Salons",
          style: GoogleFonts.abel(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                ..._matchedSalons.map((salon) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: SalonContainer(
                      key: UniqueKey(),
                      salonId: salon['salon_id'],
                      salon: salon,
                      rating: salon['rating'],
                      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                  );
                }).toList(),
                if (_unmatchedSalons.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      "Unmatched Salons",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  ),
                ..._unmatchedSalons.map((salon) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SalonContainer(
                          key: UniqueKey(),
                          salonId: salon['salon_id'],
                          salon: salon,
                          rating: salon['rating'],
                          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text(
                            "Reasons:",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...List.generate(
                          salon['reasons'].length,
                          (index) => Padding(
                            padding:
                                const EdgeInsets.only(left: 12.0, top: 4.0),
                            child: Text(
                              "- ${salon['reasons'][index]}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
