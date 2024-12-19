import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_hub/client/components/most_reviewed_service_container.dart';
import 'package:salon_hub/client/components/service_salon_container.dart';
import 'package:salon_hub/client/components/top_salon_container.dart';
import 'dart:math';

class SalonFilterPage extends StatefulWidget {
  const SalonFilterPage({
    Key? key,
    required Null Function(dynamic filteredSalons) onFilterApplied,
  }) : super(key: key);

  @override
  _SalonFilterPageState createState() => _SalonFilterPageState();
}

class _SalonFilterPageState extends State<SalonFilterPage> {
  String? _selectedPriceRange;
  TextEditingController _serviceSearchController = TextEditingController();
  bool _hasSearched = false;
  bool _isLoadingSearchResults = false; // Loading state for search results
  bool _isLoadingTopSalons = true;

  List<Map<String, dynamic>> filteredSalons = [];
  List<Map<String, dynamic>> salonsWithPopularService = [];
  List<Map<String, dynamic>> topSalons = [];

  List<String> priceRanges = [
    "50 - 100",
    "100 - 200",
    "200 - 300",
    "300 - 400",
    "400 - 500",
    "500 - 1000",
  ];

  Future<void> _fetchKNNRecommendedSalons(String serviceSearch) async {
    if (serviceSearch.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a service to search.")),
      );
      return;
    }

    setState(() {
      _isLoadingSearchResults = true;
      _hasSearched = true;
    });

    try {
      QuerySnapshot salonsSnapshot =
          await FirebaseFirestore.instance.collection('salon').get();
      List<Map<String, dynamic>> salonResults = [];

      for (var salonDoc in salonsSnapshot.docs) {
        QuerySnapshot servicesSnapshot =
            await salonDoc.reference.collection('services').get();

        for (var serviceDoc in servicesSnapshot.docs) {
          Map<String, dynamic> serviceData =
              serviceDoc.data() as Map<String, dynamic>;

          String serviceName = (serviceData['name'] ?? 'Unknown').toLowerCase();
          double servicePrice =
              double.tryParse(serviceData['price'].toString()) ?? 0.0;

          if (serviceName.contains(serviceSearch.toLowerCase())) {
            bool matchesPriceRange = _selectedPriceRange != null
                ? _isWithinPriceRange(servicePrice, _selectedPriceRange!)
                : true;

            if (matchesPriceRange) {
              QuerySnapshot reviewsSnapshot = await salonDoc.reference
                  .collection('reviews')
                  .where('service', isEqualTo: serviceData['name'])
                  .get();

              if (reviewsSnapshot.docs.isNotEmpty) {
                double totalRating = 0;
                int reviewCount = 0;

                for (var reviewDoc in reviewsSnapshot.docs) {
                  totalRating +=
                      (reviewDoc['rating'] as num?)?.toDouble() ?? 0.0;
                  reviewCount++;
                }

                double averageServiceRating =
                    reviewCount > 0 ? totalRating / reviewCount : 0.0;

                salonResults.add({
                  'salonId': salonDoc.id,
                  'salonName': salonDoc['salon_name'] ?? 'Unknown Salon',
                  'salonAddress':
                      salonDoc['address'] ?? 'Address not available',
                  'serviceName': serviceData['name'] ?? 'Unknown Service',
                  'servicePrice': servicePrice,
                  'averageServiceRating': averageServiceRating,
                  'reviewCount': reviewCount,
                  'imageUrl': salonDoc['image_url'] ?? 'default_image_url',
                  'openTime': salonDoc['open_time'] ?? 'N/A',
                  'closeTime': salonDoc['close_time'] ?? 'N/A',
                });
              }
            }
          }
        }
      }

      // Apply KNN logic
      List<Map<String, dynamic>> recommendedSalons =
          _applyKNNAlgorithm(serviceSearch, salonResults);

      setState(() {
        filteredSalons = recommendedSalons;
        _isLoadingSearchResults = false;
      });
    } catch (e) {
      print("Error fetching salons: $e");
      setState(() {
        _isLoadingSearchResults = false;
      });
    }
  }

  List<Map<String, dynamic>> _applyKNNAlgorithm(
      String searchQuery, List<Map<String, dynamic>> salons) {
    // Placeholder user preferences (could come from user profile)
    Map<String, dynamic> userPreferences = {
      'preferredPrice': 200.0,
      'preferredRating': 4.0,
    };

    // Calculate distances based on price and rating
    for (var salon in salons) {
      double servicePrice =
          salon['servicePrice'] ?? 0.0; // Default to 0.0 if null
      double rating =
          salon['averageServiceRating'] ?? 0.0; // Default to 0.0 if null

      double priceDifference =
          (servicePrice - (userPreferences['preferredPrice'] ?? 200.0)).abs();
      double ratingDifference =
          (rating - (userPreferences['preferredRating'] ?? 4.0)).abs();

      // Distance metric: Euclidean distance
      salon['distance'] =
          sqrt(pow(priceDifference, 2) + pow(ratingDifference, 2));
    }

    // Sort salons by distance
    salons.sort((a, b) => a['distance'].compareTo(b['distance']));

    // Return top-K recommendations (e.g., top 5)
    return salons.take(5).toList();
  }

  bool _isWithinPriceRange(double price, String priceRange) {
    try {
      List<String> range = priceRange.split(' - ');
      double minPrice = double.tryParse(range[0]) ?? 0.0;
      double maxPrice = double.tryParse(range[1]) ?? double.infinity;

      return price >= minPrice && price <= maxPrice;
    } catch (e) {
      print("Error in _isWithinPriceRange: $e");
      return false; // Return false if there's an error
    }
  }

  Future<void> _fetchTopSalons() async {
    setState(() {
      _isLoadingTopSalons = true;
    });

    QuerySnapshot salonSnapshot =
        await FirebaseFirestore.instance.collection('salon').get();
    List<Map<String, dynamic>> topSalonResults = [];

    for (var salonDoc in salonSnapshot.docs) {
      double totalRating = 0;
      int reviewCount = 0;

      QuerySnapshot reviewsSnapshot =
          await salonDoc.reference.collection('reviews').get();
      for (var reviewDoc in reviewsSnapshot.docs) {
        totalRating += reviewDoc['rating'] as double;
        reviewCount++;
      }

      if (reviewCount > 0) {
        double averageRating = totalRating / reviewCount;
        if (averageRating >= 4.0) {
          topSalonResults.add({
            'salonId': salonDoc.id,
            'salonName': salonDoc['salon_name'] ?? 'Unknown Salon',
            'salonAddress': salonDoc['address'] ?? 'Address not available',
            'rating': averageRating,
            'imageUrl': salonDoc['image_url'] ?? 'default_image_url',
            'openTime': salonDoc['open_time'] ?? 'N/A',
            'closeTime': salonDoc['close_time'] ?? 'N/A',
            'status': salonDoc['status'] ?? 'Closed',
          });
        }
      }
    }

    setState(() {
      topSalons = topSalonResults;
      _isLoadingTopSalons = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchSalonsWithPopularService();
    _fetchTopSalons();
  }

  Future<void> _fetchSalonsWithPopularService() async {
    try {
      // Fetch salons collection
      QuerySnapshot salonSnapshot =
          await FirebaseFirestore.instance.collection('salon').get();

      List<Map<String, dynamic>> salonResults = [];

      for (var salonDoc in salonSnapshot.docs) {
        QuerySnapshot reviewsSnapshot =
            await salonDoc.reference.collection('reviews').get();

        // Ensure there are reviews to process
        if (reviewsSnapshot.docs.isNotEmpty) {
          Map<String, int> serviceCountMap = {};
          double totalRating = 0;
          int reviewCount = 0;

          for (var reviewDoc in reviewsSnapshot.docs) {
            String? service = reviewDoc['service'];
            if (service != null) {
              serviceCountMap[service] = (serviceCountMap[service] ?? 0) + 1;
            }
            totalRating += (reviewDoc['rating'] as num?)?.toDouble() ?? 0.0;
            reviewCount++;
          }

          // Calculate the average rating
          double averageRating =
              reviewCount > 0 ? totalRating / reviewCount : 0.0;

          // Find the most reviewed service
          String? popularService = serviceCountMap.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

          salonResults.add({
            'salonId': salonDoc.id,
            'salonName': salonDoc['salon_name'] ?? 'Unknown Salon',
            'salonAddress': salonDoc['address'] ?? 'Address not available',
            'rating': averageRating,
            'popularService': popularService ?? 'No service data',
            'imageUrl':
                salonDoc['image_url'] ?? 'assets/images/default_salon.jpg',
            'openTime': salonDoc['open_time'] ?? 'N/A',
            'closeTime': salonDoc['close_time'] ?? 'N/A',
            'status': salonDoc['status'] ?? 'Closed',
          });
        }
      }

      // Update state with fetched data
      setState(() {
        salonsWithPopularService = salonResults;
      });
    } catch (e) {
      print("Error fetching salons with popular services: $e");
      setState(() {
        salonsWithPopularService = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load popular services.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFaf9f6),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _serviceSearchController,
                            style: GoogleFonts.abel(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Search Services',
                              prefixIcon: Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  // Clear the search text
                                  _serviceSearchController.clear();

                                  // Reset state and reload data
                                  setState(() {
                                    _hasSearched = false;
                                    filteredSalons.clear();
                                  });

                                  // Reload top salons and popular services
                                  _fetchTopSalons();
                                  _fetchSalonsWithPopularService();
                                },
                              ),
                              labelStyle: GoogleFonts.abel(fontSize: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onSubmitted: (value) {
                              _fetchKNNRecommendedSalons(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriceRange,
                            hint: Text('Price Range',
                                style: GoogleFonts.abel(fontSize: 14)),
                            items: priceRanges.map((priceRange) {
                              return DropdownMenuItem<String>(
                                value: priceRange,
                                child: Text(priceRange,
                                    style: GoogleFonts.abel(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPriceRange = value;
                              });
                              _fetchKNNRecommendedSalons(
                                  _serviceSearchController.text);
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_hasSearched)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Recommended Salons for ${_serviceSearchController.text}',
                              style: GoogleFonts.abel(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 320,
                            child: filteredSalons.isEmpty
                                ? const Center(child: Text("No salons found"))
                                : SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: filteredSalons.map((salon) {
                                        return SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.6,
                                          child: ServiceSalonContainer(
                                            salonId: salon['salonId'],
                                            salonName: salon['salonName'],
                                            salonAddress: salon['salonAddress'],
                                            rating: salon[
                                                    'averageServiceRating'] ??
                                                0.0, // Default to 0.0 if null
                                            serviceName: salon['serviceName'] ??
                                                'Unknown Service',
                                            servicePrice: salon['servicePrice']
                                                .toString(), // Convert price to String
                                            imageUrl: salon['imageUrl'] ??
                                                'default_image_url',
                                            services: salon['services'] ?? [],
                                            stylists: salon['stylists'] ?? [],
                                            openTime:
                                                salon['openTime'] ?? 'N/A',
                                            closeTime:
                                                salon['closeTime'] ?? 'N/A',
                                            userId: salon['userId'] ?? 'N/A',
                                            status: salon['status'] ?? 'Closed',
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    if (topSalons.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Salons',
                            style: GoogleFonts.abel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 250,
                            child: _isLoadingTopSalons
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: topSalons.length,
                                    itemBuilder: (context, index) {
                                      final salon = topSalons[index];
                                      return TopSalonContainer(
                                        salonId: salon['salonId'],
                                        salonName: salon['salonName'],
                                        salonAddress: salon['salonAddress'],
                                        rating: salon['rating'],
                                        imageUrl: salon['imageUrl'],
                                        openTime: salon['openTime'],
                                        closeTime: salon['closeTime'],
                                        userId: 'user_id_placeholder',
                                        stylists: [],
                                        services: [], // Pass any necessary data
                                        status: salon['status'],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    // Text(
                    //   'Popular Service for each salon',
                    //   style: GoogleFonts.abel(
                    //     fontSize: 16,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    // SizedBox(
                    //     height: 275,
                    //     child: salonsWithPopularService.isEmpty
                    //         ? const Center(child: CircularProgressIndicator())
                    //         : ListView.builder(
                    //             scrollDirection: Axis.horizontal,
                    //             itemCount: salonsWithPopularService.length,
                    //             itemBuilder: (context, index) {
                    //               var salon = salonsWithPopularService[index];
                    //               return MostReviewedServiceContainer(
                    //                 salonId: salon['salonId'] ?? '',
                    //                 salonName:
                    //                     salon['salonName'] ?? 'Unknown Salon',
                    //                 salonAddress: salon['salonAddress'] ??
                    //                     'Address not available',
                    //                 rating: salon['rating'] ?? 0.0,
                    //                 popularServiceName:
                    //                     salon['popularService'] ??
                    //                         'Service not available',
                    //                 imageUrl: salon['imageUrl'] ??
                    //                     'assets/images/default_salon.jpg',
                    //                 openTime: salon['openTime'] ?? 'N/A',
                    //                 closeTime: salon['closeTime'] ?? 'N/A',
                    //                 userId: 'user_id_placeholder',
                    //                 status: salon['status'],
                    //               );
                    //             },
                    //           ))
                  ],
                ),
              ),
            ),
            if (_isLoadingSearchResults)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    // Refresh top salons and popular services
    await _fetchTopSalons();
    await _fetchSalonsWithPopularService();

    setState(() {
      _hasSearched = false;
      filteredSalons.clear();
    });
  }
}
