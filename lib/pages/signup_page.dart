import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/signup_client.dart';
import 'package:salon_hub/owner/signup_owner.dart'; // Import the signup_owner page

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Image.asset(
                "assets/images/register.png",
                width: 200.0,
                height: 200.0,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Register as',
              style: GoogleFonts.aboreto(
                textStyle: const TextStyle(
                  fontSize: 25,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xff355E3B),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignupClient()),
                  );
                },
                child: Text(
                  'Client',
                  style: GoogleFonts.aboreto(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 300,
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 253, 253, 253),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const SignupOwner()), // Navigate to SignupOwner
                  );
                },
                child: Text(
                  'Salon Owner',
                  style: GoogleFonts.aboreto(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
