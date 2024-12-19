import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Add this dependency

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
  final TextEditingController _reviewController = TextEditingController();
  String? _reviewId;
  String? _selectedServiceId;
  double _currentRating = 0.0; // Holds the current star rating
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _checkIfReviewed();
  }

  Future<void> _fetchServices() async {
    try {
      final servicesRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('services');

      final snapshot = await servicesRef.get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _services = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unnamed Service',
            };
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
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not logged in.')),
        );
        return;
      }

      final reviewQuery = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .where('isAppointmentReview', isEqualTo: false)
          .limit(1)
          .get();

      if (reviewQuery.docs.isNotEmpty) {
        final existingReview = reviewQuery.docs.first;
        _reviewId = existingReview.id;
        final data = existingReview.data();

        setState(() {
          _reviewController.text = data['review'];
          _selectedServiceId = data['serviceId'];
          _currentRating = data['rating'] ?? 0.0; // Load existing rating
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking review: $e')),
      );
    }
  }

  Future<void> _submitReview() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not logged in.')),
        );
        return;
      }

      final reviewsRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews');

      // Prepare the review data
      final reviewData = {
        'review': _reviewController.text,
        'rating': _currentRating,
        'timestamp': Timestamp.now(),
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous', // Add the userName
        'serviceId': _selectedServiceId,
        'service': _services.firstWhere(
            (service) => service['id'] == _selectedServiceId)['name'],
        'isAppointmentReview': false, // Set to false for walk-in reviews
        'upvotes': 0, // Initialize upvotes to 0
      };

      if (_reviewId != null) {
        // Update existing review
        await reviewsRef.doc(_reviewId).update(reviewData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully!')),
        );
      } else {
        // Add new review
        await reviewsRef.add(reviewData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }

      Navigator.pop(context, true); // Close the review page
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
        title: Text(
          'Submit Walk-in Review',
          style: GoogleFonts.abel(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff355E3B),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a service:',
                style:
                    GoogleFonts.abel(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 15,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                value: _selectedServiceId,
                hint: const Text('Choose a service'),
                items: _services.map((service) {
                  return DropdownMenuItem<String>(
                    value: service['id'],
                    child: Text(
                      service['name'],
                      style: GoogleFonts.abel(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServiceId = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Rate your experience:',
                style:
                    GoogleFonts.abel(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Center(
                child: RatingBar.builder(
                  initialRating: _currentRating,
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
                      _currentRating = rating;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Write your review:',
                style:
                    GoogleFonts.abel(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _selectedServiceId == null ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff355E3B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Submit Review',
                    style: GoogleFonts.abel(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
