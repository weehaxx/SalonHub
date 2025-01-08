import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsClient extends StatefulWidget {
  final String salonId;
  final String appointmentId;
  final List<String> services;
  final bool isAppointmentReview;
  final String mainCategory; // Male or Female
  final String stylist; // Stylist name

  const ReviewsClient({
    super.key,
    required this.salonId,
    required this.appointmentId,
    required this.services,
    required this.isAppointmentReview,
    required this.mainCategory,
    required this.stylist,
  });

  @override
  _ReviewsClientState createState() => _ReviewsClientState();
}

class _ReviewsClientState extends State<ReviewsClient> {
  double _rating = 3.0;
  final TextEditingController _reviewController = TextEditingController();

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a review.')),
      );
      return;
    }

    try {
      // Get the current user ID
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch the user's name from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Retrieve the username from the document, or use a default value if not found
      final userName = userDoc.data()?['name'] ?? 'Client';

      // Get a reference to the Firestore collection
      final reviewsRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews');

      // Add the review with additional fields
      await reviewsRef.add({
        'appointmentId': widget.appointmentId,
        'services': widget.services,
        'rating': _rating,
        'review': _reviewController.text,
        'timestamp': Timestamp.now(),
        'isAppointmentReview': widget.isAppointmentReview,
        'main_category': widget.mainCategory, // Save gender category
        'stylist': widget.stylist, // Save stylist name
        'userId': userId,
        'userName': userName,
      });

      // Update the appointment document to mark it as reviewed
      final appointmentRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('appointments')
          .doc(widget.appointmentId);

      await appointmentRef.update({'isReviewed': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );

      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Appointment'),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Services: ${widget.services.join(', ')}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Category: ${widget.mainCategory}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Stylist: ${widget.stylist}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Rate your experience:',
              style: TextStyle(fontSize: 16),
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
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your review here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff355E3B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Submit Review',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
