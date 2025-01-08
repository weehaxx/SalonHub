import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/components/salon_container.dart';

class BookmarkedSalonsPage extends StatefulWidget {
  const BookmarkedSalonsPage({Key? key}) : super(key: key);

  @override
  State<BookmarkedSalonsPage> createState() => _BookmarkedSalonsPageState();
}

class _BookmarkedSalonsPageState extends State<BookmarkedSalonsPage> {
  List<Map<String, dynamic>> _bookmarkedSalons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookmarkedSalons();
  }

  Future<void> _fetchBookmarkedSalons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Fetch user bookmarks
      final userInteractionDoc = await FirebaseFirestore.instance
          .collection('user_interaction')
          .doc(userId)
          .get();

      if (!userInteractionDoc.exists ||
          userInteractionDoc['bookmarked_salons'] == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final List<String> bookmarkedSalonIds =
          List<String>.from(userInteractionDoc['bookmarked_salons']);
      final List<Map<String, dynamic>> bookmarkedSalons = [];

      // Fetch details of bookmarked salons
      for (final salonId in bookmarkedSalonIds) {
        final salonDoc = await FirebaseFirestore.instance
            .collection('salon')
            .doc(salonId)
            .get();

        if (salonDoc.exists) {
          final salonData = salonDoc.data()!;

          // Fetch reviews to calculate average rating
          final reviewsSnapshot = await FirebaseFirestore.instance
              .collection('salon')
              .doc(salonId)
              .collection('reviews')
              .get();

          double totalRating = 0.0;
          int reviewCount = reviewsSnapshot.docs.length;

          for (var reviewDoc in reviewsSnapshot.docs) {
            totalRating += (reviewDoc['rating'] ?? 0).toDouble();
          }

          double averageRating =
              reviewCount > 0 ? totalRating / reviewCount : 0.0;

          bookmarkedSalons.add({
            'salon_id': salonId,
            'salon_name': salonData['salon_name'] ?? 'Unknown Salon',
            'address': salonData['address'] ?? 'No Address Available',
            'image_url': salonData['image_url'] ?? '',
            'rating': averageRating, // Use the calculated average rating
            'open_time': salonData['open_time'] ?? 'Unknown',
            'close_time': salonData['close_time'] ?? 'Unknown',
          });
        }
      }

      setState(() {
        _bookmarkedSalons = bookmarkedSalons;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookmarked salons: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedSalons.isEmpty
              ? Center(
                  child: Text(
                    "No bookmarked salons found.",
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _bookmarkedSalons.length,
                  itemBuilder: (context, index) {
                    final salon = _bookmarkedSalons[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: SalonContainer(
                        key: UniqueKey(),
                        salonId: salon['salon_id'],
                        salon: salon,
                        rating: salon['rating'],
                        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                      ),
                    );
                  },
                ),
    );
  }
}
