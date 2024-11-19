import 'dart:ui';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:salon_hub/client/components/custom_drawer.dart';
import 'package:salon_hub/client/components/nearby_salon_container.dart';
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
  String? _userId;
  List<Map<String, dynamic>> _salons = [];
  List<Map<String, dynamic>> _personalizedSalons = [];
  List<Map<String, dynamic>> _nearbySalons = [];
  List<Map<String, dynamic>> _filteredSalons = [];
  bool _isLoadingPersonalized = true;
  bool _isLoadingNearby = true;
  int _selectedIndex = 0;

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _searchController.addListener(_applySearchFilter);
  }

  void _applySearchFilter() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (_selectedIndex == 1) {
        _filteredSalons = _personalizedSalons
            .where((salon) =>
                salon['salon_name'].toString().toLowerCase().contains(query))
            .toList();
      } else if (_selectedIndex == 2) {
        _filteredSalons = _nearbySalons
            .where((salon) =>
                salon['salon_name'].toString().toLowerCase().contains(query))
            .toList();
      } else {
        _filteredSalons = _salons
            .where((salon) =>
                salon['salon_name'].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoadingPersonalized = true;
      _isLoadingNearby = true;
    });
    await _checkAndLoadUserName();
    await _fetchSalons();
    await _fetchPersonalizedSalons();
    await _fetchNearbySalons();
    setState(() {
      _isLoadingPersonalized = false;
      _isLoadingNearby = false;
    });
    _applySearchFilter();
  }

  Future<void> _checkAndLoadUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['name'] ?? '';
          _userEmail = user.email;
          _profileImageUrl = user.photoURL;
        });

        if (_userName == null || _userName!.isEmpty) {
          Future.delayed(Duration.zero, _promptForUserName);
        }
      }
    }
  }

  void _promptForUserName() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
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
          'latitude': doc['latitude'],
          'longitude': doc['longitude'],
          'open_time': doc['open_time'] ?? 'Unknown',
          'close_time': doc['close_time'] ?? 'Unknown',
          'image_url': doc['image_url'] ?? '',
          'services': services,
          'stylists': stylists,
          'rating': averageRating,
          'total_reviews': totalReviews
        };
      }).toList());

      if (!mounted) return;
      setState(() {
        _salons = salons;
      });
    } catch (e) {
      print("Error fetching salons: $e");
    }
  }

  Future<void> _fetchPersonalizedSalons() async {
    setState(() {
      _isLoadingPersonalized = true;
    });

    try {
      QuerySnapshot pastAppointmentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('appointments')
          .get();

      List<String> pastSalonIds = pastAppointmentsSnapshot.docs
          .map((doc) => doc['salon_id'] as String)
          .toList();

      List<Map<String, dynamic>> filteredSalons = _salons.where((salon) {
        double rating = salon.containsKey('rating')
            ? (salon['rating'] as num).toDouble()
            : 0.0;
        int totalReviews = salon.containsKey('total_reviews')
            ? (salon['total_reviews'] as num).toInt()
            : 0;

        return (rating >= 4.0) || (totalReviews >= 5);
      }).toList();

      List<Map<String, dynamic>> personalizedSalons =
          filteredSalons.map((salon) {
        double rating = (salon['rating'] != null)
            ? (salon['rating'] as num).toDouble()
            : 0.0;
        int reviews = (salon['total_reviews'] != null)
            ? (salon['total_reviews'] as num).toInt()
            : 0;
        bool isPastAppointment = pastSalonIds.contains(salon['salon_id']);
        double score = _calculateScore(rating, reviews, isPastAppointment);

        return {
          ...salon,
          'score': score,
        };
      }).toList();

      personalizedSalons.sort((a, b) => b['score'].compareTo(a['score']));

      if (!mounted) return;
      setState(() {
        _personalizedSalons = personalizedSalons;
        _isLoadingPersonalized = false;
      });
    } catch (e) {
      print("Error fetching personalized salons: $e");
      if (!mounted) return;
      setState(() {
        _isLoadingPersonalized = false;
      });
    }
  }

  double _calculateScore(double rating, int reviews, bool isPastAppointment) {
    double score = rating * 10;
    score += reviews;
    if (isPastAppointment) {
      score += 50;
    }
    return score;
  }

  Future<void> _fetchNearbySalons() async {
    setState(() {
      _isLoadingNearby = true;
    });

    const double maxDistance = 5.0;

    try {
      Position userLocation = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Map<String, dynamic>> nearbySalons = _salons.where((salon) {
        double salonLat = salon['latitude'];
        double salonLon = salon['longitude'];

        double distance = _calculateDistance(
            userLocation.latitude, userLocation.longitude, salonLat, salonLon);

        return distance <= maxDistance;
      }).map((salon) {
        double salonLat = salon['latitude'];
        double salonLon = salon['longitude'];

        double distance = _calculateDistance(
            userLocation.latitude, userLocation.longitude, salonLat, salonLon);

        return {...salon, 'distance': distance};
      }).toList();

      nearbySalons.sort((a, b) {
        return a['distance'].compareTo(b['distance']);
      });

      if (!mounted) return;
      setState(() {
        _nearbySalons = nearbySalons;
        _isLoadingNearby = false;
      });
    } catch (e) {
      print("Error fetching nearby salons: $e");
      setState(() {
        _isLoadingNearby = false;
      });
    }
  }

  void _searchSalon(String query) {
    final filteredSalons = _salons.where((salon) {
      final salonName = salon['salon_name'].toLowerCase();
      final searchQuery = query.toLowerCase();

      return salonName.contains(searchQuery);
    }).toList();

    setState(() {
      _filteredSalons = filteredSalons;
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
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
      _selectedIndex = index;
    });
    _applySearchFilter(); // Apply search filter whenever tab changes
  }

  Future<void> _handleRefresh() async {
    await _fetchPersonalizedSalons();
    await _fetchNearbySalons();
    await _fetchSalons();
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
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _logout();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildRecommendationsPage() {
    return _isLoadingPersonalized
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _handleRefresh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (query) => _searchSalon(
                                query), // Call search on text change
                            style: GoogleFonts.abel(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Search Salons',
                              labelStyle: GoogleFonts.abel(
                                  fontSize: 14, color: Colors.grey),
                              prefixIcon: const Icon(Icons.search,
                                  size: 18, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Color(0xff355E3B), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildAllSalonsPage(),
                ),
              ],
            ),
          );
  }

  Widget _buildNearbyPage() {
    List<Map<String, dynamic>> displaySalons =
        _searchController.text.isNotEmpty ? _filteredSalons : _nearbySalons;

    return _isLoadingNearby
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: displaySalons.length,
              itemBuilder: (context, index) {
                final salon = displaySalons[index];
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
          );
  }

  Widget _buildAllSalonsPage() {
    // Use the full list (_salons) when the search field is empty,
    // otherwise, use the filtered list (_filteredSalons)
    final displaySalons =
        _searchController.text.isNotEmpty ? _filteredSalons : _salons;

    return displaySalons.isEmpty
        ? const Center(
            child: Text(
              "No salons found",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: displaySalons.length,
            itemBuilder: (context, index) {
              final salon = displaySalons[index];
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
                  userId: _userId ?? '',
                ),
              );
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

  @override
  Widget build(BuildContext context) {
    final List<String> _titles = [
      'Find Service',
      'Salons',
      'Nearby Salons',
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
                    ? _buildFilterPage()
                    : _selectedIndex == 1
                        ? _buildRecommendationsPage()
                        : _buildNearbyPage(),
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
            Icon(Icons.cut, size: 30, color: Colors.white),
            Icon(Icons.holiday_village, size: 30, color: Colors.white),
            Icon(Icons.near_me, size: 30, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPage() {
    return SalonFilterPage(
      onFilterApplied: (filteredSalons) {
        setState(() {
          _salons = filteredSalons.map((salon) {
            return {
              'salon_id': salon['salon_id'] ?? 'Unknown ID',
              'salon_name': salon['salon_name'] ?? 'Unknown Salon',
              'address': salon['address'] ?? 'No Address Available',
              'latitude': salon['latitude'] ?? 0.0,
              'longitude': salon['longitude'] ?? 0.0,
              'open_time': salon['open_time'] ?? 'N/A',
              'close_time': salon['close_time'] ?? 'N/A',
              'image_url': salon['image_url'] ?? '',
              'services': salon['services'] ?? [],
              'stylists': salon['stylists'] ?? [],
              'rating': salon['rating'] ?? 0.0,
              'total_reviews': salon['total_reviews'] ?? 0,
            };
          }).toList();
        });
      },
    );
  }
}
