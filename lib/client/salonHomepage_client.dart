import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/components/custom_drawer.dart';
import 'package:salon_hub/client/components/salon_container.dart';
import 'package:salon_hub/client/review_experience_page.dart';
import 'package:salon_hub/client/salonFiltering_page.dart';
import 'package:salon_hub/pages/login_page.dart';

class SalonhomepageClient extends StatefulWidget {
  const SalonhomepageClient({super.key});

  @override
  State<SalonhomepageClient> createState() => _SalonhomepageClientState();
}

class _SalonhomepageClientState extends State<SalonhomepageClient> {
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  List<Map<String, dynamic>> _salons = [];
  int _selectedIndex = 0; // For Bottom Navigation

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

  void _promptForUserName() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dialog from closing on outside tap
      builder: (BuildContext context) {
        return Stack(
          children: [
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

        QuerySnapshot servicesSnapshot =
            await doc.reference.collection('services').get();
        services = servicesSnapshot.docs
            .map((serviceDoc) => serviceDoc.data() as Map<String, dynamic>)
            .toList();

        QuerySnapshot stylistsSnapshot =
            await doc.reference.collection('stylists').get();
        stylists = stylistsSnapshot.docs
            .map((stylistDoc) => stylistDoc.data() as Map<String, dynamic>)
            .toList();

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

        return {
          'salon_id': doc.id,
          'salon_name': doc['salon_name'] ?? 'Unknown Salon',
          'address': doc['address'] ?? 'No Address Available',
          'open_time': doc['open_time'] ?? 'Unknown',
          'close_time': doc['close_time'] ?? 'Unknown',
          'image_url': doc['image_url'] ?? '',
          'services': services,
          'stylists': stylists,
          'rating': averageRating,
          'total_reviews': totalReviews
        };
      }).toList());

      setState(() {
        _salons = salons;
      });
    } catch (e) {
      print("Error fetching salons: $e");
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index for BottomNavigation
    });
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
        onReviewExperience: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReviewExperiencePage(),
            ),
          );
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Removed the extra drawer icon here
            Center(
              child: Image.asset(
                'assets/images/logo2.png', // Replace with your logo asset path
                height: 35,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black),
              onPressed: () {
                // Handle notifications onPressed
              },
            ),
          ],
        ),
        elevation: 0, // Removes shadow for a clean look
      ),
      body: _selectedIndex == 0
          ? _buildRecommendationsPage()
          : _buildFilterPage(), // Conditionally render based on selected tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected, // Call method to change tabs
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Recommendations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_list),
            label: 'Services Filter',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsPage() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello ${_userName ?? 'User'},',
                  style: GoogleFonts.abel(fontSize: 20, color: Colors.black),
                ),
                const SizedBox(height: 5),
                Text(
                  'Welcome to SALON HUB!',
                  style: GoogleFonts.abel(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
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
        ],
      ),
    );
  }

  Widget _buildFilterPage() {
    return SalonFilterPage(
      onFilterApplied: (filteredSalons) {
        setState(() {
          _salons = filteredSalons; // Update the state with the filtered salons
        });
      },
    );
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
}
