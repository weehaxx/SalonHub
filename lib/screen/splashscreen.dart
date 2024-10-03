import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/owner/welcomepage_owner.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Fade in after 1 second
    Timer(const Duration(seconds: 1), () {
      setState(() {
        _opacity = 1.0; // Start fade-in
      });
    });

    // After 3 seconds, start fading out
    Timer(const Duration(seconds: 5), () {
      setState(() {
        _opacity = 0.0; // Start fade-out
      });
    });

    // Navigate to the Welcome Page after 5 seconds (giving time for fade-out)
    Timer(const Duration(seconds: 7), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WelcomepageOwner(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff355E3B), // Background color
      body: Center(
        child: AnimatedOpacity(
          opacity:
              _opacity, // The current opacity (for both fade-in and fade-out)
          duration: const Duration(
              seconds: 2), // Duration for both fade-in and fade-out
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Image
              Image.asset(
                'assets/images/logo.png', // Replace with your logo path
                width: 200,
                height: 200,
              ),
              Column(
                children: [
                  Text(
                    'Salon Hub', // App name or Logo text
                    style: GoogleFonts.aboreto(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your Beauty Companion',
                    style: GoogleFonts.aboreto(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
