import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salon_hub/main.dart';
import 'package:salon_hub/pages/login_page.dart'; // Import the login screen or main app entry point

class FlaggingSystem {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to flag user and block them if conditions are met
  Future<void> flagAndBlockUser(BuildContext context, String userId) async {
    try {
      // Fetch user's flag data from Firestore
      DocumentReference flagRef =
          _firestore.collection('user_flags').doc(userId);
      DocumentSnapshot flagDoc = await flagRef.get();

      int cancelCount = 0;
      if (flagDoc.exists) {
        // If the document exists, get the current count
        cancelCount = flagDoc['cancelCount'] ?? 0;
      }

      // Increment the cancel count
      cancelCount++;

      // Update the flag count in Firestore
      await flagRef.set({'cancelCount': cancelCount});

      // If the cancel count is 3 or more in a day, disable the user
      if (cancelCount >= 3) {
        // Disable the user account in Firebase Authentication
        await _auth.currentUser
            ?.updateDisplayName("Blocked"); // Optional: Tag the display name
        await _auth.currentUser?.reload(); // Ensure the changes are reflected

        await _auth.signOut(); // Sign out the blocked user

        // Navigate the user back to the login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Login(), // Replace with your login screen
          ),
        );

        // Show a message indicating the user has been blocked
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Account Blocked'),
            content: const Text(
                'You have canceled 3 accepted appointments today. Your account has been blocked.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Inform the user about the cancellation count
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'You have canceled $cancelCount accepted appointments today.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error flagging user: $e')),
      );
    }
  }
}
