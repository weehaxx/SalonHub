import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/components/custom_drawer.dart';
import 'package:salon_hub/client/editUserPreference.dart';
import 'package:salon_hub/client/nearbysalon_page';

import 'package:salon_hub/client/personalizedSalonsPage.dart';
import 'package:salon_hub/client/bookmarkedSalonsPage.dart'; // Import the BookmarkedSalonsPage
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
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() {
            _userName = userData?['name'] ?? 'User';
            _userEmail = userData?['email'] ?? '';
            _profileImageUrl = userData?['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
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

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const PersonalizedSalonsPage(),
      const NearbySalonsPage(),
      const BookmarkedSalonsPage(), // Add the BookmarkedSalonsPage here
    ];

    return Scaffold(
      drawer: CustomDrawer(
        userName: _userName,
        userEmail: _userEmail,
        profileImageUrl: _profileImageUrl,
        onLogout: _logout,
      ),
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "Home"
              : _selectedIndex == 1
                  ? "Nearby Salons"
                  : "Bookmarked Salons",
          style: GoogleFonts.abel(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            tooltip: 'Edit Preferences',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditUserPreference(),
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        selectedItemColor: const Color(0xff355E3B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.near_me),
            label: "Nearby",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark), // Add the bookmark icon
            label: "Bookmarks", // Label for the bookmarks tab
          ),
        ],
      ),
    );
  }
}
