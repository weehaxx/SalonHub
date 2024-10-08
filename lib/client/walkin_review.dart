import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_hub/client/walkin_feedback.dart'; // Import the WalkInFeedbackPage

class WalkInReviewPage extends StatefulWidget {
  final String salonId;
  final List<Map<String, dynamic>> services;

  const WalkInReviewPage({
    super.key,
    required this.salonId,
    required this.services,
  });

  @override
  _WalkInReviewPageState createState() => _WalkInReviewPageState();
}

class _WalkInReviewPageState extends State<WalkInReviewPage> {
  double _rating = 3.0; // Default rating
  final TextEditingController _reviewController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _currentUserName = 'Anonymous';
  String? _selectedService; // For selecting the service

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
    _checkExistingReview();
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

  Future<void> _checkExistingReview() async {
    if (_currentUser != null) {
      QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('walkin_reviews')
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();

      if (reviewSnapshot.docs.isNotEmpty) {
        var existingReview = reviewSnapshot.docs.first;
        String service = existingReview['service'];
        setState(() {
          _rating = existingReview['rating'];
          _reviewController.text = existingReview['review'];
          _selectedService = widget.services
                  .map((service) => service['name'])
                  .contains(service)
              ? service
              : null;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      _showSnackbar('Please select a rating before submitting your review.');
      return;
    }

    if (_reviewController.text.isEmpty) {
      _showSnackbar('Please write a review before submitting.');
      return;
    }

    if (_selectedService == null || _selectedService!.isEmpty) {
      _showSnackbar('Please select a service before submitting.');
      return;
    }

    final reviewData = {
      'rating': _rating,
      'review': _reviewController.text.trim(),
      'userId': _currentUser?.uid,
      'userName': _currentUserName,
      'service': _selectedService,
      'timestamp': Timestamp.now(),
    };

    try {
      QuerySnapshot existingReviewSnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('walkin_reviews')
          .where('userId', isEqualTo: _currentUser?.uid)
          .get();

      if (existingReviewSnapshot.docs.isNotEmpty) {
        var existingReviewDocId = existingReviewSnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('salon')
            .doc(widget.salonId)
            .collection('walkin_reviews')
            .doc(existingReviewDocId)
            .update(reviewData);
      } else {
        await FirebaseFirestore.instance
            .collection('salon')
            .doc(widget.salonId)
            .collection('walkin_reviews')
            .add(reviewData);
      }

      _showSnackbar('Review submitted successfully!', isSuccess: true);
      if (mounted) {
        // Navigate back to WalkInFeedbackPage with updated display
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WalkInFeedbackPage(
              salonId: widget.salonId,
              services: widget.services,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackbar('Error submitting review: $e');
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
        title: const Text('Submit Walk-in Review'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Service',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedService,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: widget.services.map((service) {
                return DropdownMenuItem<String>(
                  value: service['name'],
                  child: Text(service['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedService = value;
                });
              },
              hint: const Text("Select a service"),
            ),
            const SizedBox(height: 20),
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
