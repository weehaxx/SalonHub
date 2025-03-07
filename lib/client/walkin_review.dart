import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final TextEditingController _reviewController = TextEditingController();
  String? _reviewId; // ID of the existing review
  String? _selectedServiceId; // Selected service ID
  String? _selectedMainCategory; // Selected main category (Male/Female)
  double _currentRating = 0.0; // Current star rating
  List<Map<String, dynamic>> _services =
      []; // List of services for the selected category

  @override
  void initState() {
    super.initState();
    _fetchServices(); // Fetch all services initially
  }

  // Fetch services from Firestore
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
              'main_category': data['main_category'] ?? 'Unknown',
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

  // Filter services based on selected category (Male/Female)
  List<Map<String, dynamic>> _filterServicesByCategory(String? category) {
    if (category == null) return [];
    return _services
        .where((service) => service['main_category'] == category)
        .toList();
  }

  Future<void> _fetchReviewForService(String serviceId) async {
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
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .get();

      if (reviewQuery.docs.isNotEmpty) {
        final existingReview = reviewQuery.docs.first;
        final data = existingReview.data();

        setState(() {
          _reviewId = existingReview.id;
          _reviewController.text = data['review'] ?? '';
          _currentRating = data['rating']?.toDouble() ?? 0.0;
        });
      } else {
        // Clear only the review-related fields, not the category or service
        setState(() {
          _reviewId = null;
          _reviewController.clear();
          _currentRating = 0.0;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching review: $e')),
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

      // Validate that a service and category are selected
      if (_selectedMainCategory == null || _selectedServiceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a category and service.')),
        );
        return;
      }

      // Fetch the user's details
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Anonymous';

      // Reference for the salon reviews collection
      final reviewsRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews');

      // Prepare review data
      final reviewData = {
        'review': _reviewController.text,
        'rating': _currentRating,
        'timestamp': Timestamp.now(),
        'userId': user.uid,
        'userName': userName,
        'serviceId': _selectedServiceId,
        'service': _services.firstWhere(
            (service) => service['id'] == _selectedServiceId)['name'],
        'main_category': _selectedMainCategory,
        'isAppointmentReview': false,
        'upvotes': 0,
      };

      if (_reviewId != null) {
        // Update existing review
        await reviewsRef.doc(_reviewId).update(reviewData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully!')),
        );
      } else {
        // Add a new review
        await reviewsRef.add(reviewData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }

      // Update `user_interaction` document
      final userInteractionRef = FirebaseFirestore.instance
          .collection('user_interaction')
          .doc(user.uid);

      final interactionData = {
        'salonId': widget.salonId,
        'serviceId': _selectedServiceId,
        'serviceName': _services.firstWhere(
            (service) => service['id'] == _selectedServiceId)['name'],
        'main_category': _selectedMainCategory,
        'rating': _currentRating,
      };

      // Merge the review into `reviewed_services` array in `user_interaction`
      await userInteractionRef.set({
        'reviewed_services': FieldValue.arrayUnion([interactionData])
      }, SetOptions(merge: true));

      Navigator.pop(context, true); // Close the review page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = _filterServicesByCategory(_selectedMainCategory);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Submit Walk-in Review',
          style: GoogleFonts.abel(color: Colors.white),
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
                'Select category:',
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
                value: _selectedMainCategory,
                hint: const Text('Select Male or Female'),
                items: const [
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male Services'),
                  ),
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female Services'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedMainCategory = value;
                    _selectedServiceId = null; // Reset selected service
                  });
                },
              ),
              const SizedBox(height: 20),
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
                items: filteredServices.map((service) {
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
                  if (value != null) {
                    _fetchReviewForService(value);
                  }
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
                  onPressed: _selectedServiceId == null ||
                          _selectedMainCategory == null
                      ? null
                      : _submitReview,
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
