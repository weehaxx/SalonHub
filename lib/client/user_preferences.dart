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
          style: GoogleFonts.abel(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
                  color: const Color(0xff355E3B),
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
                  color: const Color(0xff355E3B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: services.map((service) {
                  return ChoiceChip(
                    label: Text(
                      service,
                      style: GoogleFonts.abel(
                        color: preferredServices.contains(service)
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ),
                    selected: preferredServices.contains(service),
                    selectedColor: const Color(0xff355E3B),
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          preferredServices.add(service);
                        } else {
                          preferredServices.remove(service);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Preferred Service Rating',
                style: GoogleFonts.abel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff355E3B),
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: preferredServiceRating,
                onChanged: (value) {
                  setState(() {
                    preferredServiceRating = value;
                  });
                },
                divisions: 5,
                min: 1.0,
                max: 5.0,
                label: preferredServiceRating.toString(),
                activeColor: const Color(0xff355E3B),
                inactiveColor: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Preferred Salon Rating',
                style: GoogleFonts.abel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff355E3B),
                ),
              ),
              const SizedBox(height: 8),
              Slider(
                value: preferredSalonRating,
                onChanged: (value) {
                  setState(() {
                    preferredSalonRating = value;
                  });
                },
                divisions: 5,
                min: 1.0,
                max: 5.0,
                label: preferredSalonRating.toString(),
                activeColor: const Color(0xff355E3B),
                inactiveColor: Colors.grey[300],
              ),
              const SizedBox(height: 80), // Spacing for floating button
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _savePreferences,
        backgroundColor: const Color(0xff355E3B),
        label: Text(
          'Save Preferences',
          style: GoogleFonts.abel(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.save, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
