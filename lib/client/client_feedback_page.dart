import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'walkin_review.dart'; // Import the WalkinReview page

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
  double _averageRating = 0.0;
  int _totalReviews = 0;
  List<Map<String, dynamic>> _reviews = [];
  String _selectedReviewType = 'Appointments';

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
        List<Map<String, dynamic>> fetchedReviews = [];
        double totalRating = 0.0;

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          var timestamp = (data['timestamp'] as Timestamp).toDate().toLocal();
          var formattedDate =
              '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

          // Determine how to handle services based on review type
          String service = '';
          if (data['isAppointmentReview'] == true) {
            // If it's an appointment review, services might be a list
            if (data['services'] != null && data['services'] is List) {
              List servicesList = data['services'];
              service = servicesList.join(', ');
            } else {
              service = 'N/A';
            }
          } else {
            // For walk-in reviews, service is a single string
            service = data['service'] ?? 'N/A';
          }

          fetchedReviews.add({
            'name': data['userName'],
            'rating': data['rating'],
            'review': data['review'],
            'date': formattedDate,
            'service': service,
            'isAppointmentReview': data['isAppointmentReview'],
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

  List<Map<String, dynamic>> _filteredReviews() {
    if (_selectedReviewType == 'Appointments') {
      return _reviews
          .where((review) => review['isAppointmentReview'] == true)
          .toList();
    } else if (_selectedReviewType == 'Walk-ins') {
      return _reviews
          .where((review) => review['isAppointmentReview'] == false)
          .toList();
    }
    return _reviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Client Feedback',
          style: GoogleFonts.abel(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: const Color(0xff355E3B),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReviews,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildReviewTypeButtons(),
              const SizedBox(height: 20),
              _buildAverageRatingSection(),
              const SizedBox(height: 30),
              _buildReviewsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _selectedReviewType == 'Walk-ins'
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff355E3B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                child: Text(
                  'Add Review',
                  style: GoogleFonts.abel(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildReviewTypeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton('Appointments'),
        const SizedBox(width: 20),
        _buildButton('Walk-ins'),
      ],
    );
  }

  Widget _buildButton(String type) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedReviewType = type;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _selectedReviewType == type ? const Color(0xff355E3B) : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        type,
        style: GoogleFonts.abel(
          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildAverageRatingSection() {
    final filteredReviews = _filteredReviews();
    final averageRating = filteredReviews.isEmpty
        ? 0.0
        : filteredReviews.map((r) => r['rating']).reduce((a, b) => a + b) /
            filteredReviews.length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffDFF6DD),
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
            initialRating: averageRating,
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
            '${averageRating.toStringAsFixed(1)} out of 5 stars based on ${filteredReviews.length} reviews',
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
    final filteredReviews = _filteredReviews();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews from Clients',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        filteredReviews.isEmpty
            ? const Center(
                child: Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReviews.length,
                itemBuilder: (context, index) {
                  final review = filteredReviews[index];
                  return _buildReviewItem(review);
                },
              ),
      ],
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
