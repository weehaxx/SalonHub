import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/components/custom_drawer.dart';
import 'package:salon_hub/client/components/salon_container.dart';
import 'package:salon_hub/pages/login_page.dart';

class SalonhomepageClient extends StatefulWidget {
  const SalonhomepageClient({super.key});

  @override
  State<SalonhomepageClient> createState() => SalonhomepageClientState();
}

class SalonhomepageClientState extends State<SalonhomepageClient> {
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  List<Map<String, dynamic>> _salons = [];

  @override
  void initState() {
    super.initState();
    _checkAndLoadUserName(); // Load or prompt for user name
    _fetchSalons(); // Fetch salons from Firestore
  }

  Future<void> _checkAndLoadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? ''; // Check if the name exists
          _userEmail = user.email;
          _profileImageUrl = user.photoURL;
        });

        // Check if the 'name' field is missing or empty
        if (_userName == null || _userName!.isEmpty) {
          Future.delayed(Duration.zero, _promptForUserName); // Prompt for name
        }
      }
    }
  }

  // Method to prompt the user for their name if it's not set
  void _promptForUserName() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Blur background
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            Center(
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'Enter Your Name',
                  style: GoogleFonts.abel(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Your Name',
                        hintStyle: GoogleFonts.abel(),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please enter your name to continue.',
                      style: GoogleFonts.abel(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xff355E3B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      String name = nameController.text.trim();
                      if (name.isNotEmpty) {
                        await _saveUserName(name);
                        setState(() {
                          _userName = name;
                        });
                        Navigator.of(context).pop();
                      } else {
                        // Show error if name is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Name cannot be empty.'),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Save',
                      style: GoogleFonts.abel(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Save the entered name to Firestore
  Future<void> _saveUserName(String name) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'name': name,
        });
      } catch (e) {
        // Handle Firestore update errors
        print('Error saving name: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save your name. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _fetchSalons() async {
    try {
      QuerySnapshot salonSnapshot =
          await FirebaseFirestore.instance.collection('salon').get();

      List<Map<String, dynamic>> salons =
          await Future.wait(salonSnapshot.docs.map((doc) async {
        List<Map<String, dynamic>> services = [];
        List<Map<String, dynamic>> stylists = [];
        double averageRating = 0;
        int totalReviews = 0;

        // Fetch services
        QuerySnapshot servicesSnapshot =
            await doc.reference.collection('services').get();
        services = servicesSnapshot.docs
            .map((serviceDoc) => serviceDoc.data() as Map<String, dynamic>)
            .toList();

        // Fetch stylists
        QuerySnapshot stylistsSnapshot =
            await doc.reference.collection('stylists').get();
        stylists = stylistsSnapshot.docs
            .map((stylistDoc) => stylistDoc.data() as Map<String, dynamic>)
            .toList();

        // Fetch reviews and calculate the average rating
        QuerySnapshot reviewsSnapshot =
            await doc.reference.collection('reviews').get();
        if (reviewsSnapshot.docs.isNotEmpty) {
          double totalRating = 0;
          for (var reviewDoc in reviewsSnapshot.docs) {
            double rating = reviewDoc['rating'].toDouble();
            totalRating += rating;
          }
          averageRating = totalRating / reviewsSnapshot.docs.length;
          totalReviews = reviewsSnapshot.docs.length;
        }

        // Map the document fields to our salon structure
        return {
          'salon_id': doc.id,
          'salon_name': doc['salon_name'] ?? 'Unknown Salon',
          'address': doc['address'] ?? 'No Address Available',
          'open_time': doc['open_time'] ?? 'Unknown',
          'close_time': doc['close_time'] ?? 'Unknown',
          'image_url': doc['image_url'] ?? '',
          'services': services, // Add services list
          'stylists': stylists, // Add stylists list
          'rating': averageRating, // Add average rating
          'total_reviews': totalReviews // Number of reviews
        };
      }).toList());

      setState(() {
        _salons = salons;
      });
    } catch (e) {
      print("Error fetching salons: $e");
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await _fetchSalons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CustomDrawer(
        userName: _userName,
        userEmail: _userEmail,
        profileImageUrl: _profileImageUrl,
        onLogout: _logout,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh, // This will be called when user pulls down
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed AppBar layout
            Container(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) {
                      return IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      );
                    },
                  ),
                  Center(
                    child: Image.asset(
                      'assets/images/logo2.png',
                      height: 35,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // Greeting section
            Padding(
              padding: const EdgeInsets.only(left: 15, bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello ${_userName ?? 'User'},',
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Welcome to SALON HUB!',
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search bar section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: SizedBox(
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Search',
                      labelStyle: GoogleFonts.abel(
                        textStyle: const TextStyle(
                          fontSize: 15,
                          color: Color.fromARGB(255, 170, 165, 165),
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color.fromARGB(255, 170, 165, 165),
                        size: 20,
                      ),
                    ),
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Salon container section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'Top Salons',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Scrollable List of Salons
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: ListView.builder(
                  padding: EdgeInsets.zero, // No extra padding
                  itemCount: _salons.length,
                  itemBuilder: (context, index) {
                    final salon = _salons[index];
                    final double rating = salon.containsKey('rating')
                        ? salon['rating'].toDouble()
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: SalonContainer(
                        key: UniqueKey(),
                        salonId: salon['salon_id'],
                        rating: rating,
                        salon: salon,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
