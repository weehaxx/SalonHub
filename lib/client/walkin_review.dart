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
  List<Map<String, dynamic>> _reviews = [];
  int? _selectedStarFilter; // Star rating filter variable
  String _selectedUpvoteFilter = 'Most Upvoted'; // Upvote filter variable

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _checkIfReviewed(); // Check if the user has already reviewed
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

  List<Map<String, dynamic>> _filteredReviews() {
    List<Map<String, dynamic>> filtered = _reviews;

    // Filter by star rating
    if (_selectedStarFilter != null) {
      filtered = filtered
          .where((review) => review['rating'] == _selectedStarFilter)
          .toList();
    }

    // Filter by upvotes
    if (_selectedUpvoteFilter == 'Most Upvoted') {
      filtered.sort((a, b) => b['upvotes'].compareTo(a['upvotes']));
    } else if (_selectedUpvoteFilter == 'Least Upvoted') {
      filtered.sort((a, b) => a['upvotes'].compareTo(b['upvotes']));
    }

    return filtered;
  }

  // Check if the user has already reviewed for the walk-in
  Future<void> _checkIfReviewed() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not logged in.')),
        );
        return;
      }

      // Query to check if user already has a review for the walk-in
      final reviewQuery = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .where('isAppointmentReview', isEqualTo: false) // Walk-in review
          .limit(1)
          .get();

      if (reviewQuery.docs.isNotEmpty) {
        final existingReview = reviewQuery.docs.first;
        _reviewId = existingReview.id;
        final data = existingReview.data();

        // Prefill the rating and review text with the existing review details
        setState(() {
          _rating = data['rating'];
          _reviewController.text = data['review'];
          _selectedService = data['service'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking review: $e')),
      );
    }
  }

  Future<void> _fetchReviews() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews')
          .where('isAppointmentReview', isEqualTo: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> fetchedReviews = [];

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          var timestamp = (data['timestamp'] as Timestamp).toDate().toLocal();
          var formattedDate =
              '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

          fetchedReviews.add({
            'id': doc.id,
            'name': data['userName'] ?? 'Anonymous',
            'rating': data['rating'] ?? 0.0,
            'review': data['review'] ?? '',
            'date': formattedDate,
            'service': data['service'] ?? 'Unknown Service',
            'upvotes': data['upvotes'] ?? 0,
          });
        }

        setState(() {
          _reviews = fetchedReviews;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reviews: $e')),
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

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String userName =
          userDoc.exists ? userDoc['name'] ?? 'Anonymous' : 'Anonymous';

      final reviewsRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId) // Add the salonId here
          .collection('reviews');

      if (_reviewId != null) {
        // Update the existing review if the user has already reviewed
        await reviewsRef.doc(_reviewId).update({
          'rating': _rating,
          'review': _reviewController.text,
          'timestamp': Timestamp.now(),
          'service': _selectedService ?? 'Unknown Service',
          'salonId': widget.salonId, // Ensure salonId is included
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review updated successfully!')),
        );
      } else {
        // Add a new review if no review exists
        await reviewsRef.add({
          'rating': _rating,
          'review': _reviewController.text,
          'timestamp': Timestamp.now(),
          'isAppointmentReview': false,
          'userId': user.uid,
          'userName': userName,
          'service': _selectedService ?? 'Unknown Service',
          'salonId': widget.salonId, // Ensure salonId is included
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('Filter by Star Rating:'),
              const SizedBox(height: 10),
              _buildStarFilterButtons(),
              const SizedBox(height: 20),
              const Text('Filter by Upvotes:'),
              const SizedBox(height: 10),
              _buildUpvoteFilterButtons(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReviews = _filteredReviews();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Walk-in Review'),
        backgroundColor: const Color(0xff355E3B),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
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
                onPressed: _selectedService == null ? null : _submitReview,
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
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredReviews.length,
                itemBuilder: (context, index) {
                  final review = filteredReviews[index];
                  return ListTile(
                    title: Text(review['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rating: ${review['rating']}'),
                        Text('Service: ${review['service']}'),
                        Text('Review: ${review['review']}'),
                        Text('Upvotes: ${review['upvotes']}'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedStarFilter = index + 1;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedStarFilter == index + 1
                  ? const Color(0xff355E3B)
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              '${index + 1} Star',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildUpvoteFilterButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedUpvoteFilter = 'Most Upvoted';
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedUpvoteFilter == 'Most Upvoted'
                ? const Color(0xff355E3B)
                : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Most Upvoted',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedUpvoteFilter = 'Least Upvoted';
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedUpvoteFilter == 'Least Upvoted'
                ? const Color(0xff355E3B)
                : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Least Upvoted',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
