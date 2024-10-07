import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewsClient extends StatefulWidget {
  final String salonId;
  final List<Map<String, dynamic>> services;

  const ReviewsClient({
    super.key,
    required this.salonId,
    required this.services,
  });

  @override
  State<ReviewsClient> createState() => _ReviewsClientState();
}

class _ReviewsClientState extends State<ReviewsClient> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _currentUserName = 'Anonymous';
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserName();
    _fetchSalonReviews(); // Fetch reviews for the salon
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

  Future<void> _fetchSalonReviews() async {
    try {
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews')
          .get();

      List<Map<String, dynamic>> reviews = reviewsSnapshot.docs.map((doc) {
        return {
          'rating': doc['rating'],
          'review': doc['review'],
          'userName': doc['userName'],
          'timestamp': doc['timestamp'],
          'service': doc['service'],
        };
      }).toList();

      setState(() {
        _reviews = reviews;
      });
    } catch (e) {
      print('Error fetching salon reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reviews',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _reviews.isEmpty
          ? const Center(
              child: Text(
                'No reviews available.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['userName'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        RatingBarIndicator(
                          rating: review['rating'].toDouble(),
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 20.0,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          review['review'],
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Service: ${review['service']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Date: ${review['timestamp'].toDate()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
