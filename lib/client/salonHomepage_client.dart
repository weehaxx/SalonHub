import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/components/custom_drawer.dart';
import 'package:salon_hub/client/editUserPreference.dart';
import 'package:salon_hub/client/nearbysalon_page';

import 'package:salon_hub/client/personalizedSalonsPage.dart';
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
    // Initialize user data here if required
  }

  Future<void> _logout() async {
    // Perform logout
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
    // Define pages dynamically inside the build method
    final List<Widget> _pages = [
      const PersonalizedSalonsPage(), // Display personalized salons on the homepage
      const NearbySalonsPage(),
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
          _selectedIndex == 0 ? "Home" : "Nearby Salons",
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
        ],
      ),
    );
  }
}
