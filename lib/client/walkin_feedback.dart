import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/client_feedback_page.dart';
import 'package:salon_hub/client/walkin_review.dart'; // Import the new review page

class WalkInFeedbackPage extends StatefulWidget {
  final String salonId;
  final List<dynamic> services;

  const WalkInFeedbackPage({
    super.key,
    required this.salonId,
    required this.services,
  });

  @override
  _WalkInFeedbackPageState createState() => _WalkInFeedbackPageState();
}

class _WalkInFeedbackPageState extends State<WalkInFeedbackPage> {
  double _averageRating = 0.0;
  int _totalReviews = 0;
  List<Map<String, dynamic>> _reviews = [];

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
          .collection('walkin_reviews') // Fetch from walkin_reviews collection
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> fetchedReviews = [];
        double totalRating = 0.0;

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          var timestamp = (data['timestamp'] as Timestamp).toDate().toLocal();
          var formattedDate = "${timestamp.toLocal().toString().split(' ')[0]}";

          fetchedReviews.add({
            'name': data['userName'],
            'rating': data['rating'],
            'review': data['review'],
            'date': formattedDate,
            'service': data['service'],
          });

          totalRating += data['rating'];
        }

        setState(() {
          _reviews = fetchedReviews;
          _totalReviews = fetchedReviews.length;
          _averageRating = totalRating / _totalReviews;
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
        title: const Text('Walk-in Feedback'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAverageRatingSection(),
                  const SizedBox(height: 30),
                  _buildButtonsSection(),
                  const SizedBox(height: 30),
                  _buildReviewsSection(),
                ],
              ),
            ),
          ),
          _buildCreateReviewButton(), // Button placed at the bottom center
        ],
      ),
    );
  }

  Widget _buildAverageRatingSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Rating',
            style: GoogleFonts.abel(
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),
          RatingBar.builder(
            initialRating: _averageRating,
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
          const SizedBox(height: 10),
          Text(
            '${_averageRating.toStringAsFixed(1)} out of 5 stars based on $_totalReviews reviews',
            style: GoogleFonts.abel(
              textStyle: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews from Clients (Walk-in)',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        _reviews.isEmpty
            ? const Center(
                child: Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final review = _reviews[index];
                  return _buildReviewItem(review);
                },
              ),
      ],
    );
  }

  Widget _buildButtonsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            // Navigate back to the ClientFeedbackPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ClientFeedbackPage(
                  salonId: widget.salonId,
                  services: widget.services,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Appointment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WalkInFeedbackPage(
                  salonId: widget.salonId,
                  services: widget.services,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Walk-in',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateReviewButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WalkInReviewPage(
                salonId: widget.salonId,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          minimumSize: const Size(double.infinity, 50), // Full width button
        ),
        child: const Text(
          'Create a Review',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
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
            if (review.containsKey('service') && review['service'] != null)
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
              initialRating: review['rating'].toDouble(),
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
          ],
        ),
      ),
    );
  }
}
