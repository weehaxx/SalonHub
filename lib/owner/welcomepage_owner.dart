import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomepageOwner extends StatefulWidget {
  const WelcomepageOwner({super.key});

  @override
  State<WelcomepageOwner> createState() => _WelcomepageOwnerState();
}

class _WelcomepageOwnerState extends State<WelcomepageOwner> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff355E3B), // Background color
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image
              Image.asset(
                'assets/images/logo.png', // Replace with your logo asset
                width: 200,
                height: 200,
              ),

              // Welcome Texts
              Text(
                'Welcome to Salon Hub!',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 30,
                    color: Color.fromARGB(255, 243, 243, 243),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Manage your salon effortlessly and efficiently',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 243, 243, 243),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Start Button
              ElevatedButton(
                onPressed: () {
                  // Add navigation or functionality when button is pressed
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xff355E3B), // Button background color
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 15), // Button size
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded button
                    side: const BorderSide(color: Colors.white), // Border color
                  ),
                ),
                child: Text(
                  'Get Started',
                  style: GoogleFonts.aboreto(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
