import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_hub/client/reviews_client.dart';
import 'package:google_fonts/google_fonts.dart';

class ClientFeedbackPage extends StatefulWidget {
  final String salonId;
  final List<Map<String, dynamic>> services;

  const ClientFeedbackPage({
    super.key,
    required this.salonId,
    required this.services,
  });

  @override
  _ClientFeedbackPageState createState() => _ClientFeedbackPageState();
}

class _ClientFeedbackPageState extends State<ClientFeedbackPage> {
  double overallRating = 0.0;
  int totalReviews = 0;
  List<Map<String, dynamic>> reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        List<Map<String, dynamic>> fetchedReviews = [];

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          totalRating += data['rating'];

          // Format the timestamp to include date and time
          var timestamp = (data['timestamp'] as Timestamp).toDate().toLocal();
          var formattedDateTime =
              "${timestamp.toLocal().toString().split(' ')[0]} ${timestamp.toLocal().toString().split(' ')[1].substring(0, 5)}";

          fetchedReviews.add({
            'name': data['userName'],
            'rating': data['rating'],
            'review': data['review'],
            'date': formattedDateTime, // Updated to show both date and time
            'image': 'https://via.placeholder.com/50',
            'service': data['service'], // Service associated with review
          });
        }

        setState(() {
          reviews = fetchedReviews;
          totalReviews = reviews.length;
          overallRating = totalRating / totalReviews;
        });
      } else {
        setState(() {
          reviews = [];
          totalReviews = 0;
          overallRating = 0.0;
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Feedback'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallRatingSection(),
            const SizedBox(height: 20),
            Expanded(
              child: reviews.isNotEmpty
                  ? ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return _buildReviewItem(review);
                      },
                    )
                  : const Center(
                      child: Text(
                        'No reviews yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            _buildWriteReviewButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallRatingSection() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Rating',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            overallRating.toStringAsFixed(1),
            style: GoogleFonts.abel(
              textStyle: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          RatingBar.builder(
            initialRating: overallRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 30,
            ignoreGestures: true,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (_) {},
          ),
          const SizedBox(height: 5),
          Text(
            'Based on $totalReviews reviews',
            style: GoogleFonts.abel(
              textStyle: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: NetworkImage(review['image']),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        review['date'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  if (review.containsKey('service') &&
                      review['service'] != null)
                    Text(
                      'Service: ${review['service']}',
                      style: GoogleFonts.abel(
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 5),
                  RatingBar.builder(
                    initialRating: review['rating'],
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 20,
                    ignoreGestures: true,
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (_) {},
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review['review'],
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWriteReviewButton() {
    return Center(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewsClient(
                  salonId: widget.salonId,
                  services: widget.services,
                ),
              ),
            ).then((_) {
              _fetchReviews(); // Refresh the reviews after returning
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff355E3B),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: Colors.black45,
            elevation: 5,
          ),
          child: const Text(
            'Write a review',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
