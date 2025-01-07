import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/salonHomepage_client.dart';
// Replace with your actual Salon Homepage import

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SalonhomepageClient()),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xff355E3B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline, // Use any icon you like
              size: 120, // Big icon size
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            Text(
              'Your account is ready!',
              style: GoogleFonts.abel(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
