import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_hub/client/components/most_reviewed_service_container.dart';
import 'package:salon_hub/client/components/service_salon_container.dart';
import 'package:salon_hub/client/components/top_salon_container.dart';

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
    });

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
            double totalRating = 0;
            QuerySnapshot reviewsSnapshot =
                await salonDoc.reference.collection('reviews').get();
            if (reviewsSnapshot.docs.isNotEmpty) {
              for (var reviewDoc in reviewsSnapshot.docs) {
                totalRating += reviewDoc['rating'] as double;
              }
            }

            double averageRating = reviewsSnapshot.docs.isNotEmpty
                ? totalRating / reviewsSnapshot.docs.length
                : 0.0;

            List<Map<String, dynamic>> services =
                serviceData['services'] != null
                    ? List<Map<String, dynamic>>.from(serviceData['services'])
                    : [];

            QuerySnapshot stylistsSnapshot =
                await salonDoc.reference.collection('stylists').get();
            List<Map<String, dynamic>> stylists = stylistsSnapshot.docs
                .map((stylistDoc) => stylistDoc.data() as Map<String, dynamic>)
                .toList();

            salonResults.add({
              'salonId': salonDoc.id,
              'salonName': salonDoc['salon_name'] ?? 'Unknown Salon',
              'salonAddress': salonDoc['address'] ?? 'Address not available',
              'rating': averageRating,
              'imageUrl': salonDoc['image_url'] ?? 'default_image_url',
              'serviceName': serviceData['name'] ?? 'Unknown Service',
              'servicePrice': serviceData['price']?.toString() ?? '0',
              'openTime': salonDoc['open_time'] ?? 'N/A',
              'closeTime': salonDoc['close_time'] ?? 'N/A',
              'status': salonDoc['status'] ?? 'Closed',
              'userId': 'user_id_placeholder',
              'services': services,
              'stylists': stylists,
            });
          }
        }
      }
    }

    setState(() {
      filteredSalons = salonResults;
      _hasSearched = true;
      _isLoadingSearchResults = false;
    });
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

  bool _isWithinPriceRange(double price, String priceRange) {
    List<String> range = priceRange.split(' - ');
    double minPrice = double.parse(range[0]);
    double maxPrice = double.parse(range[1]);
    return price >= minPrice && price <= maxPrice;
  }

  @override
  void initState() {
    super.initState();
    _fetchSalonsWithPopularService();
    _fetchTopSalons();
  }

  Future<void> _fetchSalonsWithPopularService() async {
    QuerySnapshot salonSnapshot =
        await FirebaseFirestore.instance.collection('salon').get();
    List<Map<String, dynamic>> salonResults = [];

    for (var salonDoc in salonSnapshot.docs) {
      QuerySnapshot reviewsSnapshot =
          await salonDoc.reference.collection('reviews').get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        Map<String, int> serviceCountMap = {};
        double totalRating = 0;
        int reviewCount = 0;

        for (var reviewDoc in reviewsSnapshot.docs) {
          String service = reviewDoc['service'];
          serviceCountMap[service] = (serviceCountMap[service] ?? 0) + 1;
          totalRating += reviewDoc['rating'] as double;
          reviewCount++;
        }

        double averageRating =
            reviewCount > 0 ? totalRating / reviewCount : 0.0;

        String popularService = serviceCountMap.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        salonResults.add({
          'salonId': salonDoc.id,
          'salonName': salonDoc['salon_name'] ?? 'Unknown Salon',
          'salonAddress': salonDoc['address'] ?? 'Address not available',
          'rating': averageRating,
          'popularService': popularService,
          'imageUrl':
              salonDoc['image_url'] ?? 'assets/images/default_salon.jpg',
          'openTime': salonDoc['open_time'] ?? 'N/A',
          'closeTime': salonDoc['close_time'] ?? 'N/A',
          'status': salonDoc['status'] ?? 'Closed',
        });
      }
    }

    setState(() {
      salonsWithPopularService = salonResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFaf9f6),
      body: Stack(
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
                            'Recommended Salons for "${_serviceSearchController.text}"',
                            style: GoogleFonts.abel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 300,
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
                                            rating: salon['rating'],
                                            serviceName: salon['serviceName'],
                                            servicePrice: salon['servicePrice'],
                                            imageUrl: salon['imageUrl'],
                                            services: salon['services'] ?? [],
                                            stylists: salon['stylists'] ?? [],
                                            openTime: salon['openTime'],
                                            closeTime: salon['closeTime'],
                                            userId: salon['userId'],
                                            status: salon['status'],
                                          ));
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
                              ? const Center(child: CircularProgressIndicator())
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
                                      stylists: [], // Pass any necessary data
                                      status: salon['status'],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Popular Service for each salon',
                    style: GoogleFonts.abel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                      height: 275,
                      child: salonsWithPopularService.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: salonsWithPopularService.length,
                              itemBuilder: (context, index) {
                                var salon = salonsWithPopularService[index];
                                return MostReviewedServiceContainer(
                                  salonId: salon['salonId'] ?? '',
                                  salonName:
                                      salon['salonName'] ?? 'Unknown Salon',
                                  salonAddress: salon['salonAddress'] ??
                                      'Address not available',
                                  rating: salon['rating'] ?? 0.0,
                                  popularServiceName: salon['popularService'] ??
                                      'Service not available',
                                  imageUrl: salon['imageUrl'] ??
                                      'assets/images/default_salon.jpg',
                                  openTime: salon['openTime'] ?? 'N/A',
                                  closeTime: salon['closeTime'] ?? 'N/A',
                                  userId: 'user_id_placeholder',
                                  status: salon['status'],
                                );
                              },
                            ))
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
    );
  }
}
