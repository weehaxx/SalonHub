import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/components/salon_container.dart';

class PersonalizedSalonsPage extends StatefulWidget {
  const PersonalizedSalonsPage({Key? key}) : super(key: key);

  @override
  State<PersonalizedSalonsPage> createState() => _PersonalizedSalonsPageState();
}

class _PersonalizedSalonsPageState extends State<PersonalizedSalonsPage> {
  List<Map<String, dynamic>> _personalizedSalons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPersonalizedSalons();
  }

  Future<void> _fetchPersonalizedSalons() async {
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
      final int preferredSalonRating =
          userPreferences['preferred_salon_rating'] ?? 0;
      final int preferredServiceRating =
          userPreferences['preferred_service_rating'] ?? 0;
      final List<dynamic> preferredServices =
          userPreferences['preferred_services'] ?? [];

      // Fetch salons
      final salonSnapshot =
          await FirebaseFirestore.instance.collection('salon').get();

      final personalizedSalons = <Map<String, dynamic>>[];

      for (final salonDoc in salonSnapshot.docs) {
        final salonData = salonDoc.data();
        final salonRating = salonData['rating'] ?? 0;
        final servicesSnapshot =
            await salonDoc.reference.collection('services').get();

        final matchingServices = servicesSnapshot.docs.where((serviceDoc) {
          final serviceData = serviceDoc.data();
          final serviceRating = serviceData['rating'] ?? 0;
          final serviceName = serviceData['name'] ?? '';

          return serviceRating >= preferredServiceRating &&
              preferredServices.contains(serviceName);
        }).toList();

        if (salonRating >= preferredSalonRating &&
            matchingServices.isNotEmpty) {
          personalizedSalons.add({
            'salon_id': salonDoc.id,
            'salon_name': salonData['salon_name'] ?? 'Unknown Salon',
            'address': salonData['address'] ?? 'No Address Available',
            'image_url': salonData['image_url'] ?? '',
            'rating': salonRating,
            'services': matchingServices.map((doc) => doc.data()).toList(),
          });
        }
      }

      setState(() {
        _personalizedSalons = personalizedSalons;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching personalized salons: $e");
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
          : _personalizedSalons.isEmpty
              ? const Center(
                  child: Text(
                    "No salons match your preferences",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _personalizedSalons.length,
                  itemBuilder: (context, index) {
                    final salon = _personalizedSalons[index];
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
