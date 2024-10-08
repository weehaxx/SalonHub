import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalkInReviewPage extends StatefulWidget {
  final String salonId;

  const WalkInReviewPage({
    super.key,
    required this.salonId,
  });

  @override
  _WalkInReviewPageState createState() => _WalkInReviewPageState();
}

class _WalkInReviewPageState extends State<WalkInReviewPage> {
  double _rating = 3.0; // Default rating
  final TextEditingController _reviewController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<String> _getUserName() async {
    if (_currentUser != null) {
      String? email = _currentUser!.email;

      if (email != null) {
        try {
          // Query Firestore using the email to get the user document
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1) // Limit to one document
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // Fetch the username from the document if it exists
            DocumentSnapshot userDoc = querySnapshot.docs.first;
            String? username = userDoc.data().toString().contains('username')
                ? userDoc.get('username')
                : null;
            return username ?? "Anonymous";
          }
        } catch (e) {
          print('Error fetching user document: $e');
        }
      }
    }
    return "Anonymous"; // Default if no user or no name found
  }

  Future<void> _submitReview() async {
    try {
      // Fetch the current user's name
      String userName = await _getUserName();
      String userId = _currentUser?.uid ?? "unknown_user";

      // Ensure the review is not empty
      if (_reviewController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please write a review before submitting.')),
          );
        }
        return;
      }

      // Add the review to Firestore
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('walkin_reviews')
          .add({
        'userName': userName,
        'userId': userId,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'timestamp': Timestamp.now(),
        'service': 'Walk-in Service',
      });

      // Show a success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error submitting review: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Walk-in Review'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate your experience:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Write your review:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your review here...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Center(
                child: Text(
                  'Submit Review',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
