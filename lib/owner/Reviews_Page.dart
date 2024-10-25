import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  String? _salonDocId;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _reviews = [];
  String _filter = "All"; // Default filter for appointment/walk-ins
  int? _starFilter; // Star rating filter (rounded)

  @override
  void initState() {
    super.initState();
    _retrieveReviews();
  }

  Future<void> _retrieveReviews() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot salonSnapshot = await _firestore
            .collection('salon')
            .where('owner_uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (salonSnapshot.docs.isNotEmpty) {
          setState(() {
            _salonDocId = salonSnapshot.docs.first.id;
          });

          // Fetch the reviews for the salon
          QuerySnapshot reviewSnapshot = await _firestore
              .collection('salon')
              .doc(_salonDocId)
              .collection('reviews')
              .get();

          setState(() {
            _reviews = reviewSnapshot.docs;
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error retrieving reviews: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Filter reviews based on selected filters
  List<QueryDocumentSnapshot> _getFilteredReviews() {
    List<QueryDocumentSnapshot> filteredReviews = _reviews;

    // Filter by appointment/walk-ins
    if (_filter == "Appointments") {
      filteredReviews = filteredReviews
          .where((review) =>
              (review.data() as Map<String, dynamic>)['isAppointmentReview'] ==
              true)
          .toList();
    } else if (_filter == "Walk-ins") {
      filteredReviews = filteredReviews
          .where((review) =>
              (review.data() as Map<String, dynamic>)['isAppointmentReview'] ==
              false)
          .toList();
    }

    // Filter by star rating (round down the decimal values)
    if (_starFilter != null) {
      filteredReviews = filteredReviews
          .where((review) =>
              (review.data() as Map<String, dynamic>)['rating'].floor() ==
              _starFilter)
          .toList();
    }

    return filteredReviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Reviews', style: GoogleFonts.abel()),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Filter by Appointments/Walk-ins
                      Expanded(
                        child: _buildFilterDropdown(
                          value: _filter,
                          icon: const Icon(Icons.filter_list),
                          items:
                              ['All', 'Appointments', 'Walk-ins'].map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter, style: GoogleFonts.abel()),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _filter = value ?? "All";
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filter by Star Ratings
                      Expanded(
                        child: _buildFilterDropdown(
                          value: _starFilter != null
                              ? _starFilter.toString()
                              : "All",
                          icon: const Icon(Icons.star),
                          items: ['All', '5', '4', '3', '2', '1'].map((rating) {
                            return DropdownMenuItem(
                              value: rating,
                              child: Row(
                                children: [
                                  Text(rating == "All"
                                      ? "All Ratings"
                                      : '$rating Stars'),
                                  const SizedBox(width: 5),
                                  if (rating != "All")
                                    Icon(Icons.star,
                                        color: Colors.amber[700], size: 18),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              if (value == "All") {
                                _starFilter = null;
                              } else {
                                _starFilter = int.tryParse(value!);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _getFilteredReviews().isEmpty
                      ? Center(
                          child: Text(
                            'No reviews found',
                            style: GoogleFonts.abel(
                              textStyle: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _getFilteredReviews().length,
                          itemBuilder: (context, index) {
                            final review = _getFilteredReviews()[index];
                            final data = review.data() as Map<String, dynamic>;
                            final upvotes = data['upvotes'] ?? 0;

                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          data['userName'] ?? 'Anonymous',
                                          style: GoogleFonts.abel(
                                            textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Icon(Icons.star,
                                            color: Colors.amber[700], size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Review Comment:',
                                      style: GoogleFonts.abel(
                                        textStyle: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      data['review'] ?? '',
                                      style: GoogleFonts.abel(),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Rating: ${data['rating'].toStringAsFixed(1)}/5',
                                      style: GoogleFonts.abel(
                                          textStyle: const TextStyle(
                                              color: Colors.green)),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Service: ${data['service']}',
                                      style: GoogleFonts.abel(),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      data['isAppointmentReview'] == true
                                          ? 'Review Type: Appointment'
                                          : 'Review Type: Walk-in',
                                      style: GoogleFonts.abel(
                                          textStyle: const TextStyle(
                                              fontStyle: FontStyle.italic)),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Timestamp: ${DateFormat.yMMMd().add_jm().format((data['timestamp'] as Timestamp).toDate())}',
                                      style: GoogleFonts.abel(
                                          textStyle: const TextStyle(
                                              fontStyle: FontStyle.italic)),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Upvotes: $upvotes',
                                      style: GoogleFonts.abel(
                                          textStyle: const TextStyle(
                                              color: Colors.blueGrey,
                                              fontSize: 14)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Custom dropdown widget for filters
  Widget _buildFilterDropdown<T>({
    required T value,
    required Icon icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        underline: Container(), // Remove default underline
        icon: icon,
        dropdownColor: Colors.white,
      ),
    );
  }
}
