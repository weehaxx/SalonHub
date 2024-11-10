import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'walkin_review.dart'; // Import the WalkinReview page

class ClientFeedbackPage extends StatefulWidget {
  final String salonId;
  final List<Map<String, dynamic>> services;
  final String userId; // Add userId to track the upvoter

  const ClientFeedbackPage({
    super.key,
    required this.salonId,
    required this.services,
    required this.userId, // Pass the userId from the parent widget
  });

  @override
  _ClientFeedbackPageState createState() => _ClientFeedbackPageState();
}

class _ClientFeedbackPageState extends State<ClientFeedbackPage> {
  double _averageAppointmentRating = 0.0;
  double _averageWalkinRating = 0.0;
  int _totalAppointmentReviews = 0;
  int _totalWalkinReviews = 0;
  List<Map<String, dynamic>> _reviews = [];
  String _selectedReviewType = 'Appointments';
  int? _selectedStarFilter; // Star rating filter variable
  Set<String> _upvotedReviews = {}; // Track upvoted reviews by ID

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _fetchUserUpvotedReviews(); // Fetch user's upvoted reviews
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
        double totalAppointmentRating = 0.0;
        double totalWalkinRating = 0.0;
        int appointmentCount = 0;
        int walkinCount = 0;

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          var timestamp = (data['timestamp'] as Timestamp).toDate().toLocal();
          var formattedDate =
              '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}' ??
                  '';

          String service = '';
          if (data['isAppointmentReview'] == true) {
            if (data['services'] != null && data['services'] is List) {
              List servicesList = data['services'];
              service = servicesList.join(', ');
            } else {
              service = 'N/A';
            }
            totalAppointmentRating += data['rating'];
            appointmentCount++;
          } else {
            service = data['service'] ?? 'N/A';
            totalWalkinRating += data['rating'];
            walkinCount++;
          }

          fetchedReviews.add({
            'id': doc.id,
            'name': data['userName'],
            'rating': data['rating'],
            'review': data['review'],
            'date': formattedDate,
            'service': service,
            'isAppointmentReview': data['isAppointmentReview'],
            'upvotes': data['upvotes'] ?? 0,
          });
        }

        setState(() {
          _reviews = fetchedReviews;
          _totalAppointmentReviews = appointmentCount;
          _totalWalkinReviews = walkinCount;
          _averageAppointmentRating = appointmentCount > 0
              ? totalAppointmentRating / appointmentCount
              : 0.0;
          _averageWalkinRating =
              walkinCount > 0 ? totalWalkinRating / walkinCount : 0.0;
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
  }

  // Fetch upvoted reviews by the current user
  Future<void> _fetchUserUpvotedReviews() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userSnapshot.exists) {
        var data = userSnapshot.data() as Map<String, dynamic>;
        if (data.containsKey('upvotedReviews')) {
          setState(() {
            _upvotedReviews = Set<String>.from(data['upvotedReviews']);
          });
        }
      }
    } catch (e) {
      print('Error fetching upvoted reviews: $e');
    }
  }

  // Method to handle upvote/un-upvote functionality
  Future<void> _toggleUpvoteReview(String reviewId) async {
    bool hasUpvoted = _upvotedReviews.contains(reviewId);
    int voteChange = hasUpvoted ? -1 : 1;

    try {
      DocumentReference reviewRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews')
          .doc(reviewId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(reviewRef);

        if (!snapshot.exists) {
          throw Exception("Review does not exist!");
        }

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        int currentUpvotes = data.containsKey('upvotes') ? data['upvotes'] : 0;

        transaction.update(reviewRef, {'upvotes': currentUpvotes + voteChange});
      });

      // Update user's upvote list
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(widget.userId);

      if (hasUpvoted) {
        await userRef.update({
          'upvotedReviews': FieldValue.arrayRemove([reviewId]),
        });
        _upvotedReviews.remove(reviewId);
      } else {
        await userRef.update({
          'upvotedReviews': FieldValue.arrayUnion([reviewId]),
        });
        _upvotedReviews.add(reviewId);
      }

      setState(() {});
      await _fetchReviews();
    } catch (e) {
      print('Error toggling upvote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upvote the review: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _filteredReviews() {
    List<Map<String, dynamic>> filtered = _reviews;

    // Filter by review type (Appointments or Walk-ins)
    if (_selectedReviewType == 'Appointments') {
      filtered = filtered
          .where((review) => review['isAppointmentReview'] == true)
          .toList();
    } else if (_selectedReviewType == 'Walk-ins') {
      filtered = filtered
          .where((review) => review['isAppointmentReview'] == false)
          .toList();
    }

    // Filter by rating ranges based on the selected filter
    if (_selectedStarFilter != null) {
      switch (_selectedStarFilter) {
        case 1: // 1–2 stars: Low-rated
          filtered = filtered
              .where((review) => review['rating'] >= 1 && review['rating'] < 2)
              .toList();
          break;
        case 2: // 2–3 stars: Average ratings
          filtered = filtered
              .where((review) => review['rating'] >= 2 && review['rating'] < 3)
              .toList();
          break;
        case 3: // 3–4 stars: Above average
          filtered = filtered
              .where((review) => review['rating'] >= 3 && review['rating'] < 4)
              .toList();
          break;
        case 4: // 4–5 stars: Highly rated
          filtered = filtered
              .where((review) => review['rating'] >= 4 && review['rating'] <= 5)
              .toList();
          break;
      }
    }

    return filtered;
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
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReviews = _filteredReviews();
    int maxUpvotes = filteredReviews.isNotEmpty
        ? filteredReviews
            .map((review) => review['upvotes'])
            .reduce((value, element) => value > element ? value : element)
        : 0;
    final mostUpvotedReviews = filteredReviews
        .where((review) => review['upvotes'] == maxUpvotes)
        .toList();
    final recentReviews = filteredReviews
        .where((review) => !mostUpvotedReviews.contains(review))
        .toList();

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
              ElevatedButton(
                onPressed: _showFilterBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff355E3B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Filter Reviews',
                    style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              _buildReviewTypeButtons(),
              const SizedBox(height: 20),

              // Display average rating for Appointments
              if (_selectedReviewType == 'Appointments') ...[
                _buildAverageRatingSection(
                    _averageAppointmentRating, _totalAppointmentReviews),
                const SizedBox(height: 30),
              ],

              // Display average rating for Walk-ins
              if (_selectedReviewType == 'Walk-ins') ...[
                _buildAverageRatingSection(
                    _averageWalkinRating, _totalWalkinReviews),
                const SizedBox(height: 30),
              ],

              // Display active filter if any
              if (_selectedStarFilter != null)
                Text(
                  '${_selectedStarFilter == 1 ? "1-2 Stars: Low-rated" : _selectedStarFilter == 2 ? "2-3 Stars: Average ratings" : _selectedStarFilter == 3 ? "3-4 Stars: Above average" : "4-5 Stars: Highly rated"} Reviews',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

              const SizedBox(height: 20),

              // Display most upvoted reviews
              if (mostUpvotedReviews.isNotEmpty) ...[
                const Text(
                  'Most Upvoted Review(s)',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mostUpvotedReviews.length,
                  itemBuilder: (context, index) {
                    final review = mostUpvotedReviews[index];
                    return _buildReviewItem(review);
                  },
                ),
                const SizedBox(height: 30),
              ],

              // Display recent reviews
              if (recentReviews.isNotEmpty) ...[
                const Text(
                  'Recent Reviews',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentReviews.length,
                  itemBuilder: (context, index) {
                    final review = recentReviews[index];
                    return _buildReviewItem(review);
                  },
                ),
              ],
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

  Widget _buildStarFilterButtons() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedStarFilter = 1;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedStarFilter == 1
                ? const Color(0xff355E3B)
                : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            '1–2 Stars: Low-rated',
            style: GoogleFonts.abel(
              textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedStarFilter = 2;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedStarFilter == 2
                ? const Color(0xff355E3B)
                : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            '2–3 Stars: Average ratings',
            style: GoogleFonts.abel(
              textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedStarFilter = 3;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedStarFilter == 3
                ? const Color(0xff355E3B)
                : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            '3–4 Stars: Above average',
            style: GoogleFonts.abel(
              textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selectedStarFilter = 4;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedStarFilter == 4
                ? const Color(0xff355E3B)
                : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            '4–5 Stars: Highly rated',
            style: GoogleFonts.abel(
              textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ]..insert(
          0,
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedStarFilter = null; // Reset filter to show all reviews
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedStarFilter == null
                  ? const Color(0xff355E3B)
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'All',
              style: GoogleFonts.abel(
                textStyle: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          )),
    );
  }

  Widget _buildAverageRatingSection(double averageRating, int totalReviews) {
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
            '${averageRating.toStringAsFixed(1)} out of 5 stars based on $totalReviews reviews',
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

  Widget _buildReviewItem(Map<String, dynamic> review) {
    bool hasUpvoted = _upvotedReviews.contains(review['id']);
    String comment = review['review'];

    // Determine font size based on comment length
    double fontSize = _getFontSizeForComment(comment.length);

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        color: hasUpvoted ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () => _toggleUpvoteReview(review['id']),
                    ),
                    Text('${review['upvotes']}'),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    comment,
                    style: GoogleFonts.abel(
                      textStyle: TextStyle(
                        fontSize: fontSize, // Adjust font size based on length
                        color: Colors.black87,
                      ),
                    ),
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// A function to calculate font size based on comment length
  double _getFontSizeForComment(int length) {
    if (length < 50) {
      return 16.0; // Large font for short comments
    } else if (length < 100) {
      return 14.0; // Medium font for moderate comments
    } else {
      return 12.0; // Smaller font for long comments
    }
  }
}
