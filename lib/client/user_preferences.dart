import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_page.dart'; // Import the Welcome Page

class UserPreferencesPage extends StatefulWidget {
  const UserPreferencesPage({Key? key}) : super(key: key);

  @override
  State<UserPreferencesPage> createState() => _UserPreferencesPageState();
}

class _UserPreferencesPageState extends State<UserPreferencesPage> {
  String? selectedGender;
  List<String> preferredServices = [];
  double preferredServiceRating = 4.0;
  double preferredSalonRating = 4.0;

  final List<Map<String, dynamic>> genders = [
    {'label': 'Male', 'icon': Icons.male},
    {'label': 'Female', 'icon': Icons.female},
    {'label': 'Other', 'icon': Icons.transgender},
  ];

  final List<String> services = [
    'Haircut',
    'Rebond',
    'Manicure',
    'Pedicure',
    'Massage',
    'Hair Coloring',
    'Facial',
    'Hair Spa',
    'Waxing',
    'Eyebrow Threading',
    'Hair Styling',
    'Nail Art',
    'Makeup',
    'Body Scrub',
    'Shaving',
    'Scalp Treatment',
    'Foot Spa',
    'Keratin Treatment',
    'Eyelash Extension',
    'Beard Trim',
    'Skin Whitening',
    'Hot Oil Treatment',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is logged in.')),
        );
        return;
      }

      final userId = user.uid;

      final userPreferencesSnapshot = await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(userId)
          .get();

      if (userPreferencesSnapshot.exists) {
        final userPreferences = userPreferencesSnapshot.data()!;

        setState(() {
          selectedGender = userPreferences['gender'];
          preferredServices =
              List<String>.from(userPreferences['preferred_services'] ?? []);
          preferredServiceRating =
              (userPreferences['preferred_service_rating'] ?? 4.0).toDouble();
          preferredSalonRating =
              (userPreferences['preferred_salon_rating'] ?? 4.0).toDouble();
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load preferences: $e')),
      );
    }
  }

  Future<void> _savePreferences() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is logged in.')),
        );
        return;
      }

      final userId = user.uid;

      await FirebaseFirestore.instance
          .collection('user_preferences')
          .doc(userId)
          .set({
        'user_id': userId,
        'gender': selectedGender,
        'preferred_services': preferredServices,
        'preferred_service_rating': preferredServiceRating,
        'preferred_salon_rating': preferredSalonRating,
        'updated_at': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save preferences: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Preferences',
          style: GoogleFonts.abel(color: Colors.white),
        ),
        backgroundColor: const Color(0xff355E3B),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Gender',
                style: GoogleFonts.abel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: genders.map((gender) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedGender = gender['label'];
                      });
                    },
                    icon: Icon(
                      gender['icon'],
                      color: selectedGender == gender['label']
                          ? Colors.white
                          : Colors.black54,
                    ),
                    label: Text(
                      gender['label'],
                      style: GoogleFonts.abel(
                        color: selectedGender == gender['label']
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGender == gender['label']
                          ? const Color(0xff355E3B)
                          : Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Preferred Services',
                style: GoogleFonts.abel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: services.map((service) {
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (preferredServices.contains(service)) {
                          preferredServices.remove(service);
                        } else {
                          preferredServices.add(service);
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: preferredServices.contains(service)
                          ? const Color(0xff355E3B)
                          : Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    child: Text(
                      service,
                      style: GoogleFonts.abel(
                        color: preferredServices.contains(service)
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Preferred Service Rating',
                style: GoogleFonts.abel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(5, (index) {
                  double rating = index + 1.0;
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        preferredServiceRating = rating;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: preferredServiceRating == rating
                          ? const Color(0xff355E3B)
                          : Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    child: Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.abel(
                        color: preferredServiceRating == rating
                            ? Colors.white
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Preferred Salon Rating',
                style: GoogleFonts.abel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(5, (index) {
                  double rating = index + 1.0;
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        preferredSalonRating = rating;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: preferredSalonRating == rating
                          ? const Color(0xff355E3B)
                          : Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    child: Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.abel(
                        color: preferredSalonRating == rating
                            ? Colors.white
                            : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff355E3B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save Preferences',
                    style: GoogleFonts.abel(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
