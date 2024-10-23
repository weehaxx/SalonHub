import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_hub/client/components/service_salon_container.dart';

class SalonFilterPage extends StatefulWidget {
  const SalonFilterPage(
      {Key? key,
      required Null Function(dynamic filteredSalons) onFilterApplied})
      : super(key: key);

  @override
  _SalonFilterPageState createState() => _SalonFilterPageState();
}

class _SalonFilterPageState extends State<SalonFilterPage> {
  String? _selectedPriceRange; // For Price Range Dropdown
  String? _selectedRating; // For Rating Dropdown
  TextEditingController _serviceSearchController = TextEditingController();
  bool _hasSearched = false; // To track if a search/filter has been applied
  bool _isLoading = false; // To track the loading state

  // Define your price range options as strings
  List<String> priceRanges = [
    "50 - 100",
    "100 - 200",
    "200 - 300",
    "300 - 400",
    "400 - 500",
    "500 - 1000",
  ];

  // Define rating options
  List<String> ratings = [
    "1",
    "2",
    "3",
    "4",
    "5"
  ]; // Rating options from 1 to 5

  List<Map<String, dynamic>> filteredSalons = [];

  // Function to fetch filtered salons based on search, price, and rating
  Future<void> _fetchFilteredSalons() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    String serviceSearch = _serviceSearchController.text.toLowerCase();

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

        if (serviceName.contains(serviceSearch)) {
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

            bool matchesRating = _selectedRating != null
                ? (averageRating >= double.parse(_selectedRating!) &&
                    averageRating < double.parse(_selectedRating!) + 1)
                : true;

            if (matchesRating) {
              salonResults.add({
                'salonId': salonDoc.id,
                'salonName': salonDoc['salon_name'] ?? 'Unknown Salon',
                'salonAddress': salonDoc['address'] ?? 'Address not available',
                'rating': averageRating,
                'imageUrl': salonDoc['image_url'] ?? 'default_image_url',
                'serviceName': serviceData['name'] ?? 'Unknown Service',
                'servicePrice': serviceData['price']?.toString() ?? '0',
              });
            }
          }
        }
      }
    }

    setState(() {
      filteredSalons = salonResults;
      _hasSearched = true; // Mark that search/filtering has been applied
      _isLoading = false; // Stop loading
    });
  }

  bool _isWithinPriceRange(double price, String priceRange) {
    List<String> range = priceRange.split(' - ');
    double minPrice = double.parse(range[0]);
    double maxPrice = double.parse(range[1]);
    return price >= minPrice && price <= maxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFaf9f6), // Set the background color here
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search for Services
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40, // Adjust height
                    child: TextField(
                      controller: _serviceSearchController,
                      style: GoogleFonts.abel(fontSize: 14), // Smaller font
                      decoration: InputDecoration(
                        labelText: 'Search Services',
                        labelStyle: GoogleFonts.abel(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12), // Adjust padding
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _fetchFilteredSalons();
                    setState(() {
                      _hasSearched = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Search', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Price Range and Rating Dropdowns
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price Range',
                          style: GoogleFonts.abel(fontSize: 12)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _selectedPriceRange,
                        hint: Text('Select',
                            style: GoogleFonts.abel(fontSize: 12)),
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
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Salon Rating',
                          style: GoogleFonts.abel(fontSize: 12)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _selectedRating,
                        hint: Text('Select',
                            style: GoogleFonts.abel(fontSize: 12)),
                        items: ratings.map((rating) {
                          return DropdownMenuItem<String>(
                            value: rating,
                            child: Text(rating,
                                style: GoogleFonts.abel(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRating = value;
                          });
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
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8), // Reduced this size

            // Single container for both the text and the salon containers
            if (_hasSearched)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search result text
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Salons that offer "${_serviceSearchController.text}" with rating of "${_selectedRating ?? 'Any'}"',
                        style: GoogleFonts.abel(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Filtered Salons List
                    SizedBox(
                      height: 300, // Define height for the salon container list
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _hasSearched && filteredSalons.isEmpty
                              ? const Center(
                                  child: Text("No salons match the criteria"))
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: filteredSalons.map((salon) {
                                      return SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                        child: ServiceSalonContainer(
                                          salonId: salon['salonId'],
                                          salonName: salon['salonName'],
                                          salonAddress: salon['salonAddress'],
                                          rating: salon['rating'],
                                          serviceName: salon['serviceName'],
                                          imageUrl: salon['imageUrl'],
                                          servicePrice: salon['servicePrice'],
                                          address: null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
