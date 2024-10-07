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
  Map<String, dynamic>? _appointmentToReview; // Store the appointment to review

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
    _fetchPendingReview(); // Fetch the appointment to review
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

  Future<void> _fetchPendingReview() async {
    if (_currentUser != null) {
      try {
        QuerySnapshot appointmentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('appointments')
            .where('status',
                isEqualTo: 'Done') // Find appointments marked as "Done"
            .where('isReviewed',
                isEqualTo: false) // Filter by unreviewed appointments
            .get();

        if (appointmentsSnapshot.docs.isNotEmpty) {
          setState(() {
            _appointmentToReview =
                appointmentsSnapshot.docs.first.data() as Map<String, dynamic>;
          });
        }
      } catch (e) {
        print('Error fetching pending reviews: $e');
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
      'appointmentId': _appointmentToReview?['id'], // Link to the appointment
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Save the review
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser?.uid)
          .collection('reviews')
          .add(reviewData);

      // Mark the appointment as reviewed
      if (_appointmentToReview != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser?.uid)
            .collection('appointments')
            .doc(_appointmentToReview?['id'])
            .update({'isReviewed': true});
      }

      _showSnackbar('Review submitted successfully!', isSuccess: true);
      setState(() {
        _rating = 0;
        _reviewController.clear();
        _appointmentToReview = null; // Clear the appointment after review
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
      body: _appointmentToReview == null
          ? const Center(
              child: Text(
                'No appointments available for review.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate your experience with ${_appointmentToReview?['stylist'] ?? 'the stylist'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                  const SizedBox(height: 30),
                  const Text(
                    'Write Your Review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff355E3B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff355E3B),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
