import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class PersonalizedSalonRecommendations {
  // Haversine distance function to calculate location-based distance between two points.
  double _haversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in kilometers
    var dLat = _degreesToRadians(lat2 - lat1);
    var dLon = _degreesToRadians(lon2 - lon1);
    var a = sin(dLat / 2) * sin(dLon / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Fetch the user's current location.
  Future<Position> _getUserLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Fetch all salon data and reviews from Firestore.
  Future<List<Map<String, dynamic>>> _fetchSalons() async {
    QuerySnapshot salonSnapshot =
        await FirebaseFirestore.instance.collection('salon').get();

    List<Map<String, dynamic>> salons =
        await Future.wait(salonSnapshot.docs.map((doc) async {
      List<Map<String, dynamic>> services = [];
      double averageRating = 0;
      int totalReviews = 0;

      // Fetch reviews
      QuerySnapshot reviewsSnapshot =
          await doc.reference.collection('reviews').get();
      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (var reviewDoc in reviewsSnapshot.docs) {
          double rating = reviewDoc['rating'].toDouble();
          totalRating += rating;
        }
        averageRating = totalRating / reviewsSnapshot.docs.length;
        totalReviews = reviewsSnapshot.docs.length;
      }

      return {
        'salon_id': doc.id,
        'salon_name': doc['salon_name'] ?? 'Unknown Salon',
        'latitude': doc['latitude'],
        'longitude': doc['longitude'],
        'average_rating': averageRating,
        'total_reviews': totalReviews,
        'services': doc['services'],
      };
    }).toList());

    return salons;
  }

  // Apply the KNN algorithm to get personalized recommendations.
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations(
      String userId, int k) async {
    Position userLocation =
        await _getUserLocation(); // Get user's current location
    List<Map<String, dynamic>> salons =
        await _fetchSalons(); // Fetch salons data

    // Fetch user reviews
    QuerySnapshot userReviewsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('reviews')
        .get();

    List preferredServices =
        userReviewsSnapshot.docs.map((doc) => doc['service']).toList();

    // Apply KNN - Calculate distance and service match score
    List<Map<String, dynamic>> sortedSalons = salons.map((salon) {
      double salonLat = salon['latitude'];
      double salonLon = salon['longitude'];
      double distance = _haversineDistance(
          userLocation.latitude, userLocation.longitude, salonLat, salonLon);

      // Add extra weight to salons with preferred services
      int serviceMatchScore = preferredServices
          .where((service) => salon['services'].contains(service))
          .length;

      return {
        ...salon,
        'distance': distance,
        'serviceMatchScore': serviceMatchScore,
      };
    }).toList();

    // Sort by distance and service match score
    sortedSalons.sort((a, b) {
      if (a['serviceMatchScore'] == b['serviceMatchScore']) {
        return a['distance'].compareTo(b['distance']);
      } else {
        return b['serviceMatchScore'].compareTo(a['serviceMatchScore']);
      }
    });

    return sortedSalons.take(k).toList(); // Return top K salons
  }
}
