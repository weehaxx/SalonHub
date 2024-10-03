import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewsClient extends StatefulWidget {
  final String salonId;
  final List<Map<String, dynamic>> services; // List of available services

  const ReviewsClient({
    super.key,
    required this.salonId,
    required this.services, // Pass the list of services
  });

  @override
  State<ReviewsClient> createState() => _ReviewsClientState();
}

class _ReviewsClientState extends State<ReviewsClient> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _currentUserName = 'Anonymous';
  String? _selectedService; // For selecting the service

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
    _checkExistingReview(); // Check if user has already submitted a review
  }

  Future<void> _fetchCurrentUserName() async {
    if (_currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
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
          .collection('reviews')
          .where('userId', isEqualTo: _currentUser.uid)
          .get();

      if (reviewSnapshot.docs.isNotEmpty) {
        var existingReview = reviewSnapshot.docs.first;
        setState(() {
          _rating = existingReview['rating'];
          _reviewController.text = existingReview['review'];
          _selectedService = existingReview['service'];
        });
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

    if (_selectedService == null || _selectedService!.isEmpty) {
      _showSnackbar('Please select a service before submitting.');
      return;
    }

    final reviewData = {
      'rating': _rating,
      'review': _reviewController.text,
      'userId': _currentUser?.uid,
      'userName': _currentUserName,
      'userEmail': _currentUser?.email ?? 'N/A',
      'service': _selectedService, // Store selected service
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      QuerySnapshot existingReviewSnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews')
          .where('userId', isEqualTo: _currentUser?.uid)
          .get();

      if (existingReviewSnapshot.docs.isNotEmpty) {
        var existingReviewDocId = existingReviewSnapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('salon')
            .doc(widget.salonId)
            .collection('reviews')
            .doc(existingReviewDocId)
            .update(reviewData);
      } else {
        await FirebaseFirestore.instance
            .collection('salon')
            .doc(widget.salonId)
            .collection('reviews')
            .add(reviewData);
      }

      _showSnackbar('Review submitted successfully!', isSuccess: true);
      setState(() {
        _rating = 0;
        _reviewController.clear();
        _selectedService = null;
      });

      Navigator.pop(context); // Go back after submitting the review
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
        title: const Text(
          'Write a Review',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
              ),
              value: _selectedService,
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
              'Rate Your Experience',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: RatingBar.builder(
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
              child: SizedBox(
                width: double.infinity,
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
            ),
          ],
        ),
      ),
    );
  }
}
