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

      // Filter out banned salons
      final filteredSalonDocs = salonSnapshot.docs.where((doc) {
        final data = doc.data();
        return data['isBanned'] == null || data['isBanned'] == false;
      }).toList();

      final matchedSalons = <Map<String, dynamic>>[];

      for (final salonDoc in filteredSalonDocs) {
        final salonData = salonDoc.data();

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

        // Check if the salon meets the rating preference
        if (salonRating < preferredSalonRating) {
          continue;
        }

        // Check services and match with preferences
        final servicesSnapshot =
            await salonDoc.reference.collection('services').get();

        bool hasAtLeastOneMatchingService = false;

        for (final preferredService in preferredServices) {
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
                  hasAtLeastOneMatchingService = true;
                  break; // Stop checking further for this preferred service
                }
              }
            }
          }
          if (hasAtLeastOneMatchingService) break;
        }

        // Add to matched salons if there is at least one matching service
        if (hasAtLeastOneMatchingService) {
          matchedSalons.add({
            'salon_id': salonDoc.id,
            'salon_name': salonData['salon_name'] ?? 'Unknown Salon',
            'address': salonData['address'] ?? 'No Address Available',
            'image_url': salonData['image_url'] ?? '',
            'rating': salonRating,
            'open_time': salonData['open_time'] ?? 'Unknown',
            'close_time': salonData['close_time'] ?? 'Unknown',
          });
        }
      }

      setState(() {
        _matchedSalons = matchedSalons;
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
          : _matchedSalons.isEmpty
              ? Center(
                  child: Text(
                    "No salons available.",
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _matchedSalons.length,
                  itemBuilder: (context, index) {
                    final salon = _matchedSalons[index];
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
                  },
                ),
    );
  }
}
