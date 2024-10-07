// ReviewExperiencePage.dart

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewExperiencePage extends StatefulWidget {
  const ReviewExperiencePage({super.key});

  @override
  State<ReviewExperiencePage> createState() => _ReviewExperiencePageState();
}

class _ReviewExperiencePageState extends State<ReviewExperiencePage> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _currentUserName = 'Anonymous';

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
  }

  Future<void> _fetchCurrentUserName() async {
    if (_currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists && userDoc['name'] != null) {
          setState(() {
            _currentUserName = userDoc['name'];
          });
        }
      } catch (e) {
        print('Error fetching user name: $e');
      }
    }
  }

  void _submitReview() async {
    if (_rating == 0) {
      _showSnackbar('Please select a rating before submitting your review.');
      return;
    }

    if (_reviewController.text.isEmpty) {
      _showSnackbar('Please write a review before submitting.');
      return;
    }

    final reviewData = {
      'rating': _rating,
      'review': _reviewController.text,
      'userId': _currentUser?.uid,
      'userName': _currentUserName,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('reviews')
          .add(reviewData);

      _showSnackbar('Review submitted successfully!', isSuccess: true);
      setState(() {
        _rating = 0;
        _reviewController.clear();
      });
      Navigator.pop(context);
    } catch (e) {
      _showSnackbar('Failed to submit review: $e');
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Your Experience'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Rate your experience'),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              itemCount: 5,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: 'Write your review...',
              ),
            ),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
