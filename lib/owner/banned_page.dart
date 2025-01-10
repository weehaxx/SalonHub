import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:salon_hub/pages/login_page.dart';

class BannedPage extends StatefulWidget {
  const BannedPage({super.key});

  @override
  State<BannedPage> createState() => _BannedPageState();
}

class _BannedPageState extends State<BannedPage> {
  String? banEndDate;
  Stream<DocumentSnapshot>? salonStream;

  @override
  void initState() {
    super.initState();
    _setupSalonStream();
  }

  void _setupSalonStream() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      salonStream = FirebaseFirestore.instance
          .collection('salon')
          .doc(user.uid)
          .snapshots();

      salonStream?.listen((snapshot) {
        if (snapshot.exists) {
          Map<String, dynamic>? salonData =
              snapshot.data() as Map<String, dynamic>?;
          if (salonData != null && salonData['banEndDate'] != null) {
            setState(() {
              banEndDate = salonData['banEndDate'];
            });
          }
        }
      });
    }
  }

  Future<void> _logoutAndRedirect(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error logging out: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedBanEndDate = banEndDate != null
        ? DateFormat('MMMM dd, yyyy hh:mm a')
            .format(DateTime.parse(banEndDate!))
        : 'Fetching...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Banned'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 100, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Your account has been banned.',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              banEndDate != null
                  ? 'Your ban will end on: $formattedBanEndDate'
                  : 'Fetching ban details...',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _logoutAndRedirect(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
