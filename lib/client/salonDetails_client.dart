import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_hub/client/booking_client.dart';
import 'package:salon_hub/client/client_feedback_page.dart';

class SalondetailsClient extends StatefulWidget {
  final String salonId;
  final String salonName;
  final String address;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> stylists;
  final String openTime;
  final String closeTime;
  final String userId; // Add userId here

  const SalondetailsClient({
    super.key,
    required this.salonId,
    required this.salonName,
    required this.address,
    required this.services,
    required this.stylists,
    required this.openTime,
    required this.closeTime,
    required this.userId, // Add userId as a required parameter
  });

  @override
  _SalondetailsClientState createState() => _SalondetailsClientState();
}

class _SalondetailsClientState extends State<SalondetailsClient> {
  bool _showServices = true;
  String? _imageUrl;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  String _selectedCategory = 'All'; // Default category is 'All'

  @override
  void initState() {
    super.initState();
    _fetchSalonData();
  }

  Future<void> _fetchSalonData() async {
    await Future.wait([
      _fetchSalonImage(),
      _fetchSalonRating(),
    ]);
  }

  Future<void> _fetchSalonImage() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .get();

      if (snapshot.exists) {
        setState(() {
          _imageUrl =
              snapshot['image_url'] ?? 'https://via.placeholder.com/400';
        });
      }
    } catch (e) {
      print('Error fetching salon image: $e');
      setState(() {
        _imageUrl = 'https://via.placeholder.com/400';
      });
    }
  }

  Future<void> _fetchSalonRating() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('reviews')
          .get();

      if (snapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        for (var doc in snapshot.docs) {
          totalRating += doc['rating'];
        }

        setState(() {
          _averageRating = totalRating / snapshot.docs.length;
          _totalReviews = snapshot.docs.length;
        });
      } else {
        setState(() {
          _averageRating = 0.0;
          _totalReviews = 0;
        });
      }
    } catch (e) {
      print('Error fetching salon rating: $e');
    }
  }

  Future<void> _onRefresh() async {
    await _fetchSalonData();
  }

  // Function to filter services based on the selected category
  List<Map<String, dynamic>> _filterServices() {
    if (_selectedCategory == 'All') {
      return widget.services;
    }
    return widget.services
        .where((service) => service['category'] == _selectedCategory)
        .toList();
  }

  // Function to toggle stylist's availability status
  void _toggleStylistStatus(String stylistId, String currentStatus) async {
    String newStatus =
        currentStatus == 'Available' ? 'Unavailable' : 'Available';

    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('stylists')
          .doc(stylistId)
          .update({'status': newStatus});

      setState(() {
        for (var stylist in widget.stylists) {
          if (stylist['id'] == stylistId) {
            stylist['status'] = newStatus;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function to display rating as stars
  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor(); // Number of full stars
    bool halfStar = (rating - fullStars) >= 0.5; // Check if there's a half star
    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return const Icon(Icons.star, color: Colors.yellow, size: 20);
        } else if (index == fullStars && halfStar) {
          return const Icon(Icons.star_half, color: Colors.yellow, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.yellow, size: 20);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _imageUrl != null
                      ? ClipRRect(
                          child: Image.network(
                            _imageUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  widget.salonName,
                  style: GoogleFonts.abel(
                    textStyle: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.black, size: 20),
                    const SizedBox(width: 3),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        widget.address,
                        style: GoogleFonts.abel(
                          textStyle: const TextStyle(
                            color: Color.fromARGB(255, 153, 152, 152),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Star Rating Section
                    Row(
                      children: [
                        _buildStarRating(_averageRating), // Display star rating
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ClientFeedbackPage(
                                  salonId: widget.salonId,
                                  services: widget.services,
                                  userId: widget.userId, // Pass userId here
                                ),
                              ),
                            );
                          },
                          child: Text(
                            '$_totalReviews reviews',
                            style: GoogleFonts.abel(
                              textStyle: const TextStyle(
                                fontSize: 16, // Matches the font size with time
                                color: Color.fromARGB(255, 153, 152, 152),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Time Section
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            color: Colors.black, size: 20),
                        const SizedBox(width: 5),
                        Text(
                          '${widget.openTime} - ${widget.closeTime}',
                          style: GoogleFonts.abel(
                            textStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 16, // Same font size as the rating
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showServices = true;
                            _selectedCategory = 'All'; // Show all services
                          });
                        },
                        icon: Icon(
                          Icons.content_cut_sharp,
                          color: _showServices
                              ? Colors.black
                              : const Color.fromARGB(255, 155, 155, 155),
                        ),
                        label: Text(
                          'Services',
                          style: GoogleFonts.abel(
                            textStyle: TextStyle(
                              fontSize: 18,
                              color: _showServices
                                  ? Colors.black
                                  : const Color.fromARGB(255, 155, 155, 155),
                              fontWeight: _showServices
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: _showServices
                              ? Colors.grey[200]
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 1,
                        color: const Color.fromARGB(255, 189, 189, 189),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showServices = false;
                          });
                        },
                        icon: Icon(
                          Icons.person_outline,
                          color: !_showServices
                              ? Colors.black
                              : const Color.fromARGB(255, 155, 155, 155),
                        ),
                        label: Text(
                          'Stylists',
                          style: GoogleFonts.abel(
                            textStyle: TextStyle(
                              fontSize: 18,
                              color: !_showServices
                                  ? Colors.black
                                  : const Color.fromARGB(255, 155, 155, 155),
                              fontWeight: !_showServices
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: !_showServices
                              ? Colors.grey[200]
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 10),
              // Category buttons for filtering services
              if (_showServices)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryButton('All'),
                        const SizedBox(width: 10),
                        _buildCategoryButton('Hair'),
                        const SizedBox(width: 10),
                        _buildCategoryButton('Nail'),
                        const SizedBox(width: 10),
                        _buildCategoryButton('Spa'),
                        const SizedBox(width: 10),
                        _buildCategoryButton('Others'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showServices)
                      ..._filterServices().map((service) {
                        return _buildServiceItem(
                            service['name'], service['price']);
                      }),
                    // Check if no services are available for the selected category
                    if (_showServices && _filterServices().isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'No services available for this category.',
                          style: GoogleFonts.abel(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    if (!_showServices)
                      ...widget.stylists.map((stylist) {
                        return _buildStylistItem(
                          stylist['id'],
                          stylist['name'],
                          stylist['specialization'],
                          stylist['status'],
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingClient(
                    services: widget.services,
                    stylists: widget.stylists,
                    salonId: widget.salonId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: const Color(0xff355E3B),
            ),
            child: Text(
              'BOOK NOW',
              style: GoogleFonts.abel(
                  textStyle: const TextStyle(color: Colors.white),
                  fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedCategory == category
            ? const Color(0xff355E3B)
            : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        category,
        style: GoogleFonts.abel(
          textStyle: TextStyle(
            fontSize: 16,
            color: _selectedCategory == category
                ? Colors.white
                : const Color(0xff355E3B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(String title, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.abel(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Text(
                'Php $price',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStylistItem(
      String? id, String? name, String? specialization, String? status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'N/A',
                      style: GoogleFonts.abel(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      specialization ?? 'N/A',
                      style: GoogleFonts.abel(
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 122, 122, 122),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (id != null) {
                    _toggleStylistStatus(id, status ?? 'Unavailable');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Stylist ID is missing. Unable to update status.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: (status == 'Available')
                      ? const Color.fromARGB(255, 29, 141, 6)
                      : const Color.fromARGB(255, 214, 48, 49),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  status == 'Available' ? 'Available' : 'Unavailable',
                  style: GoogleFonts.abel(
                    textStyle: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
