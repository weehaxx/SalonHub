import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalonFilterPage extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) onFilterApplied;

  const SalonFilterPage({
    Key? key,
    required this.onFilterApplied,
  }) : super(key: key);

  @override
  _SalonFilterPageState createState() => _SalonFilterPageState();
}

class _SalonFilterPageState extends State<SalonFilterPage> {
  String? _selectedCategory; // For Category Dropdown
  String? _selectedPriceRange; // For Price Range Dropdown
  String? _selectedRating; // For Rating Dropdown

  // Define your price range options as strings
  List<String> priceRanges = [
    "50 - 100",
    "100 - 200",
    "200 - 300",
    "300 - 400",
    "400 - 500",
    "500 - 1000",
  ];

  // Define categories as a list of strings
  List<String> categories = ['Hair', 'Nail', 'Skin', 'Massage'];

  // Define rating options
  List<String> ratings = [
    "1",
    "2",
    "3",
    "4",
    "5"
  ]; // Rating options from 1 to 5

  // List to store filtered salons
  List<Map<String, dynamic>> filteredSalons = [];

  @override
  void initState() {
    super.initState();
    _applyFilters(); // Automatically apply filters when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Salons', style: GoogleFonts.abel(fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Dropdown
            Text('Category', style: GoogleFonts.abel(fontSize: 18)),
            DropdownButton<String>(
              value: _selectedCategory,
              hint: Text('Select Category', style: GoogleFonts.abel()),
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category, style: GoogleFonts.abel()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _applyFilters(); // Automatically apply filters when a category is selected
                });
              },
              isExpanded: true, // Makes the dropdown full-width
            ),
            const SizedBox(height: 10),

            // Price Range Dropdown
            Text('Price Range', style: GoogleFonts.abel(fontSize: 18)),
            DropdownButton<String>(
              value: _selectedPriceRange,
              hint: Text('Select Price Range', style: GoogleFonts.abel()),
              items: priceRanges.map((priceRange) {
                return DropdownMenuItem<String>(
                  value: priceRange,
                  child: Text(priceRange, style: GoogleFonts.abel()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriceRange = value;
                  _applyFilters(); // Automatically apply filters when a price range is selected
                });
              },
              isExpanded: true, // Makes the dropdown full-width
            ),
            const SizedBox(height: 10),

            // Rating Dropdown
            Text('Rating', style: GoogleFonts.abel(fontSize: 18)),
            DropdownButton<String>(
              value: _selectedRating,
              hint: Text('Select Rating', style: GoogleFonts.abel()),
              items: ratings.map((rating) {
                return DropdownMenuItem<String>(
                  value: rating,
                  child: Text(rating, style: GoogleFonts.abel()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRating = value;
                  _applyFilters(); // Automatically apply filters when a rating is selected
                });
              },
              isExpanded: true, // Makes the dropdown full-width
            ),
            const SizedBox(height: 10),

            // Display the filtered salons below the filter controls
            Expanded(
              child: filteredSalons.isEmpty
                  ? Center(child: Text("No salons match the criteria"))
                  : ListView.builder(
                      itemCount: filteredSalons.length,
                      itemBuilder: (context, index) {
                        final salon = filteredSalons[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            title: Text(salon['salon_name']),
                            subtitle: Text('Address: ${salon['address']}'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to apply filters and fetch salons based on the selected criteria
  Future<void> _applyFilters() async {
    try {
      // Fetch all salons from Firestore
      QuerySnapshot salonSnapshot =
          await FirebaseFirestore.instance.collection('salon').get();

      // Temporary list to store the filtered results
      List<Map<String, dynamic>> filteredSalonsResult = [];

      // Parse the selected price range into minPrice and maxPrice
      if (_selectedPriceRange != null) {
        List<String> priceRangeSplit = _selectedPriceRange!.split(' - ');
        double minPrice = double.parse(priceRangeSplit[0]);
        double maxPrice = double.parse(priceRangeSplit[1]);

        // Loop through each salon and filter its services
        for (var salonDoc in salonSnapshot.docs) {
          List<Map<String, dynamic>> services = [];
          QuerySnapshot servicesSnapshot =
              await salonDoc.reference.collection('services').get();

          // Filter services based on the selected category and price range
          for (var serviceDoc in servicesSnapshot.docs) {
            Map<String, dynamic> serviceData =
                serviceDoc.data() as Map<String, dynamic>;
            double servicePrice =
                double.tryParse(serviceData['price'].toString()) ?? 0;
            String serviceCategory = serviceData['category'] ?? '';

            // Check if service matches selected filters
            bool matchesPrice =
                servicePrice >= minPrice && servicePrice <= maxPrice;
            bool matchesCategory = _selectedCategory == null ||
                serviceCategory.toLowerCase() ==
                    _selectedCategory!.toLowerCase();

            if (matchesPrice && matchesCategory) {
              services.add(serviceData); // Add matching services
            }
          }

          // If services match the filter, check the rating and add the salon
          if (services.isNotEmpty) {
            // Fetch and calculate the average rating for this salon
            QuerySnapshot reviewsSnapshot =
                await salonDoc.reference.collection('reviews').get();
            double totalRating = 0;
            for (var reviewDoc in reviewsSnapshot.docs) {
              totalRating += reviewDoc['rating'];
            }
            double averageRating = reviewsSnapshot.docs.isNotEmpty
                ? totalRating / reviewsSnapshot.docs.length
                : 0;

            // Check if the rating matches the selected rating filter
            bool matchesRating = _selectedRating == null ||
                averageRating >= double.parse(_selectedRating!);

            if (matchesRating) {
              filteredSalonsResult.add({
                'salon_id': salonDoc.id,
                'salon_name': salonDoc['salon_name'],
                'address': salonDoc['address'],
                'services': services, // Add filtered services
                'rating': averageRating,
              });
            }
          }
        }
      }

      // Update the state to display the filtered salons
      setState(() {
        filteredSalons = filteredSalonsResult;
      });
    } catch (e) {
      print('Error applying filters: $e');
      // Show error message if filters cannot be applied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply filters')),
      );
    }
  }
}
