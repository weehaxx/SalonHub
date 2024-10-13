import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
  double _rating = 3.0;
  final TextEditingController _reviewController = TextEditingController();
  String? _reviewId; // To store the ID of the existing review if any
  String? _selectedService; // To store the selected service
  List<String> _services = []; // List of services to display in the dropdown

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _checkIfReviewed();
  }

  Future<void> _fetchServices() async {
    try {
      // Fetch services from Firestore for the specific salon
      final servicesRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('services');

      final snapshot = await servicesRef.get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _services = snapshot.docs.map((doc) {
            final data = doc.data();
            return (data['name'] ?? 'Unnamed Service') as String;
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching services: $e')),
      );
    }
  }

  Future<void> _checkIfReviewed() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;

      // Check if user is authenticated
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not logged in.')),
        );
        return;
      }

      // Query the reviews collection for a review by this user
      final reviewsRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews');

      final querySnapshot = await reviewsRef
          .where('userId', isEqualTo: user.uid)
          .where('isAppointmentReview',
              isEqualTo: false) // Only walk-in reviews
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // If a review exists, pre-fill the form fields with the existing data
        final existingReview = querySnapshot.docs.first;
        _reviewId = existingReview.id;
        _rating = existingReview['rating'];
        _reviewController.text = existingReview['review'];
        _selectedService = existingReview['service'];

        setState(() {}); // Refresh the UI with the pre-filled data
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking for existing review: $e')),
      );
    }
  }

  Future<void> _submitReview() async {
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;

      // Check if user is authenticated
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not logged in.')),
        );
        return;
      }

      // Fetch the user's document from Firestore to get their name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String userName =
          userDoc.exists ? userDoc['name'] ?? 'Anonymous' : 'Anonymous';

      // Get a reference to the Firestore collection for reviews
      final reviewsRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews');

      if (_reviewId != null) {
        // If an existing review is found, update it
        await reviewsRef.doc(_reviewId).update({
          'rating': _rating,
          'review': _reviewController.text,
          'timestamp': Timestamp.now(),
          'service': _selectedService,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully!')),
        );
      } else {
        // If no existing review, create a new one
        await reviewsRef.add({
          'rating': _rating,
          'review': _reviewController.text,
          'timestamp': Timestamp.now(),
          'isAppointmentReview': false, // Indicate it's a walk-in review
          'userId': user.uid,
          'userName': userName,
          'service': _selectedService,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }

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
        title: const Text('Submit Walk-in Review'),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate your walk-in experience:',
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
              'Select a service:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedService,
              hint: const Text('Choose a service'),
              items: _services.map((service) {
                return DropdownMenuItem<String>(
                  value: service,
                  child: Text(service),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedService = value;
                });
              },
            ),
            const SizedBox(height: 20),
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
                onPressed: _selectedService == null
                    ? null
                    : _submitReview, // Disable the button if no service is selected
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
