import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/components/custom_drawer.dart';
import 'package:salon_hub/client/components/nearby_salon_container.dart';
import 'package:salon_hub/client/components/salon_container.dart';
import 'package:salon_hub/client/review_experience_page.dart';
import 'package:salon_hub/client/salonFiltering_page.dart';
import 'package:salon_hub/pages/login_page.dart';
import 'package:geolocator/geolocator.dart'; // Import for geolocation
import 'dart:math'; // Import for KNN-based distance calculations
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class SalonhomepageClient extends StatefulWidget {
  const SalonhomepageClient({super.key});

  @override
  State<SalonhomepageClient> createState() => _SalonhomepageClientState();
}

class _SalonhomepageClientState extends State<SalonhomepageClient> {
  String? _userName;
  String? _userEmail;
  String? _profileImageUrl;
  String? _userId;
  List<Map<String, dynamic>> _salons = [];
  List<Map<String, dynamic>> _personalizedSalons = [];
  List<Map<String, dynamic>> _nearbySalons = [];
  bool _isLoadingPersonalized =
      true; // To track loading of personalized recommendations
  bool _isLoadingNearby = true; // To track loading of nearby salons
  int _selectedIndex = 0; // For Bottom Navigation

  @override
  void initState() {
    super.initState();
    _checkAndLoadUserName(); // Load or prompt for user name
    _fetchSalons(); // Fetch salons from Firestore
    _fetchPersonalizedSalons(); // Fetch personalized recommendations
    _fetchNearbySalons(); // Fetch nearby salons
  }

  Future<void> _checkAndLoadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Save userId
      setState(() {
        _userId = user.uid;
      });

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
          'address':
              doc['address'] ?? 'No Address Available', // Fix for address
          'latitude': doc['latitude'], // Add latitude
          'longitude': doc['longitude'], // Add longitude
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

  Future<void> _fetchPersonalizedSalons() async {
    setState(() {
      _isLoadingPersonalized = true; // Set loading state
    });

    try {
      // Fetch user's past appointments for relevance
      QuerySnapshot pastAppointmentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .get();

      List<String> pastSalonIds = pastAppointmentsSnapshot.docs
          .map((doc) => doc['salon_id'] as String)
          .toList();

      // Initialize personalized salons list
      List<Map<String, dynamic>> personalizedSalons = _salons.map((salon) {
        // Safely get salon rating and reviews with default values
        double rating = (salon['rating'] != null)
            ? (salon['rating'] as num).toDouble() // Convert to double safely
            : 0.0; // Default to 0.0 if null

        int reviews = (salon['total_reviews'] != null)
            ? (salon['total_reviews'] as num).toInt() // Convert to int safely
            : 0; // Default to 0 if null

        // Check if the salon has been visited before (from past appointments)
        bool isPastAppointment = pastSalonIds.contains(salon['salon_id']);

        // Assign scores based on rating, reviews, and past appointments
        double score = _calculateScore(rating, reviews, isPastAppointment);

        return {
          ...salon,
          'score': score, // Include the score in the salon data
        };
      }).toList();

      // Sort salons by their score (highest score first)
      personalizedSalons.sort((a, b) => b['score'].compareTo(a['score']));

      setState(() {
        _personalizedSalons = personalizedSalons;
        _isLoadingPersonalized = false; // Done loading
      });
    } catch (e) {
      print("Error fetching personalized salons: $e");
      setState(() {
        _isLoadingPersonalized = false; // Done loading
      });
    }
  }

// Helper function to calculate the score
  double _calculateScore(double rating, int reviews, bool isPastAppointment) {
    double score = rating * 10; // Higher weight for rating
    score += reviews; // Add reviews as a smaller weight
    if (isPastAppointment) {
      score += 50; // Give a large bonus for past appointments
    }
    return score;
  }

  Future<void> _fetchNearbySalons() async {
    setState(() {
      _isLoadingNearby = true; // Set loading state
    });

    const double maxDistance = 5.0; // Define max distance as 5 kilometers

    try {
      Position userLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Map<String, dynamic>> nearbySalons = _salons.where((salon) {
        double salonLat = salon['latitude'];
        double salonLon = salon['longitude'];

        // Calculate the distance between user and salon
        double distance = _calculateDistance(
            userLocation.latitude, userLocation.longitude, salonLat, salonLon);

        // Filter salons based on the maximum distance
        return distance <= maxDistance; // Only include salons within 5 km
      }).map((salon) {
        double salonLat = salon['latitude'];
        double salonLon = salon['longitude'];

        // Calculate the distance between user and salon
        double distance = _calculateDistance(
            userLocation.latitude, userLocation.longitude, salonLat, salonLon);

        return {
          ...salon,
          'distance': distance // Include distance in salon data
        };
      }).toList();

      // Sort based on the closest distance
      nearbySalons.sort((a, b) {
        return a['distance'].compareTo(b['distance']);
      });

      setState(() {
        _nearbySalons = nearbySalons;
        _isLoadingNearby = false; // Done loading
      });
    } catch (e) {
      print("Error fetching nearby salons: $e");
      setState(() {
        _isLoadingNearby = false; // Done loading
      });
    }
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius of Earth in kilometers
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index; // Update selected index for BottomNavigation
    });
  }

  Future<void> _handleRefresh() async {
    await _fetchPersonalizedSalons(); // Refresh the personalized salons
    await _fetchNearbySalons(); // Refresh nearby salons
    await _fetchSalons(); // Refresh all salons as well
  }

  Future<bool> _showLogoutConfirmation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Logout',
              style: GoogleFonts.abel(fontWeight: FontWeight.bold),
            ),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // Dismiss the dialog, don't log out
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _logout(); // Call logout method
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false; // Return false if the dialog is dismissed without any selection
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _titles = [
      'Recommended For You',
      'Nearby Salons',
      'Filter Salons',
    ];

    return WillPopScope(
      onWillPop: _showLogoutConfirmation,
      child: Scaffold(
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
        body: Container(
          color: Color(0xfffaf9f6),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 30, left: 0, right: 0),
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
                    Text(
                      _titles[_selectedIndex],
                      style: GoogleFonts.abel(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.notifications, color: Colors.black),
                      onPressed: () {
                        // Handle notifications
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _selectedIndex == 0
                    ? _buildRecommendationsPage()
                    : _selectedIndex == 1
                        ? _buildNearbyPage()
                        : _buildFilterPage(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.white,
          color: const Color(0xff355E3B),
          height: 60,
          animationDuration: const Duration(milliseconds: 300),
          onTap: _onTabSelected,
          items: const <Widget>[
            Icon(Icons.star, size: 30, color: Colors.white), // Recommendations
            Icon(Icons.near_me, size: 30, color: Colors.white), // Nearby Salons
            Icon(Icons.filter_list,
                size: 30, color: Colors.white), // Filter Salons
          ],
        ),
      ),
    );
  }

// Build the recommendations page
  Widget _buildRecommendationsPage() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Container(
        color: Color(0xfffaf9f6), // Set the background color to white
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _isLoadingPersonalized
                  ? const Center(
                      child:
                          CircularProgressIndicator()) // Show loading spinner
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _personalizedSalons.length,
                      itemBuilder: (context, index) {
                        final salon = _personalizedSalons[index];

                        // Safely get rating
                        final double rating = salon.containsKey('rating')
                            ? (salon['rating'] ?? 0.0)
                                .toDouble() // Default to 0.0
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: SalonContainer(
                            key: UniqueKey(),
                            salonId: salon['salon_id'],
                            rating: rating,
                            salon: salon,
                            userId: _userId ?? '',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

// Build the nearby salons page
  Widget _buildNearbyPage() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _isLoadingNearby
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _nearbySalons.length,
                    itemBuilder: (context, index) {
                      final salon = _nearbySalons[index];
                      final double rating = salon.containsKey('rating')
                          ? salon['rating'].toDouble()
                          : 0.0;
                      final double distance = salon['distance'];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: NearbySalonContainer(
                          key: UniqueKey(),
                          salonId: salon['salon_id'],
                          rating: rating,
                          salon: salon,
                          userId: _userId ?? '',
                          distance: distance,
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

  Widget _buildCurvedBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff355E3B),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          topLeft: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        showSelectedLabels: true,
        showUnselectedLabels: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Recommendations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.near_me),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'All Salons',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_list),
            label: 'Filter',
          ),
        ],
      ),
    );
  }
}
