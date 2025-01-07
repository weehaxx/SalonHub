import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_hub/client/salonHomepage_client.dart';
import 'package:salon_hub/owner/banned_page.dart';
import 'package:salon_hub/owner/dashboard_owner.dart';
import 'pages/login_page.dart';
import 'package:salon_hub/owner/form_owner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salon Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Login(), // Always start with the Login page
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<void> _navigateBasedOnAuthState(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Navigate to Login if no user is logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } else {
      try {
        // Check if the logged-in user is banned
        final salonDoc = await FirebaseFirestore.instance
            .collection('salon')
            .doc(user.uid)
            .get();

        if (salonDoc.exists) {
          final salonData = salonDoc.data() as Map<String, dynamic>?;

          if (salonData?['isBanned'] == true) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BannedPage()),
            );
            return;
          }

          // Check if the profile is complete
          if (salonData?['profileComplete'] == null ||
              salonData?['profileComplete'] == false) {
            // Redirect to FormOwner if profile is incomplete
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const FormOwner()),
            );
            return;
          }
        }

        // Navigate based on user role
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          final role = userData?['role'];

          if (role == 'client') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SalonhomepageClient(),
              ),
            );
          } else if (role == 'owner') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardOwner(),
              ),
            );
          } else {
            // Logout if role is invalid or undefined
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
        } else {
          // If user document is not found, log out
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }
      } catch (e) {
        // Handle unexpected errors by logging out
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check authentication and navigate after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      _navigateBasedOnAuthState(context);
    });

    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
