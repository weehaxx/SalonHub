import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmployeesOwner extends StatefulWidget {
  const EmployeesOwner({super.key});

  @override
  State<EmployeesOwner> createState() => _EmployeesOwnerState();
}

class _EmployeesOwnerState extends State<EmployeesOwner> {
  String? salonDocId;
  bool isLoading = true;
  List<Map<String, dynamic>> stylists = [];
  Map<String, String> modifiedStylists = {};

  final TextEditingController _stylistNameController = TextEditingController();
  final TextEditingController _stylistSpecializationController =
      TextEditingController();
  String _stylistStatus = 'Available';
  final Set<String> _stylistCategories = {}; // Track multiple categories
  bool _isFormVisible = false;

  final List<String> categories = [
    'Hair',
    'Nails',
    'Massage',
    'Makeup'
  ]; // Example categories

  @override
  void initState() {
    super.initState();
    _retrieveStylists();
  }

  Future<void> _retrieveStylists() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot salonSnapshot = await FirebaseFirestore.instance
            .collection('salon')
            .where('owner_uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (salonSnapshot.docs.isNotEmpty) {
          salonDocId = salonSnapshot.docs.first.id;
          QuerySnapshot stylistSnapshot = await FirebaseFirestore.instance
              .collection('salon')
              .doc(salonDocId)
              .collection('stylists')
              .get();

          setState(() {
            stylists = stylistSnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error retrieving stylists: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateStylist(
      String stylistId, Map<String, dynamic> updates) async {
    if (salonDocId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonDocId)
          .collection('stylists')
          .doc(stylistId)
          .update(updates);
    } catch (e) {
      print('Error updating stylist: $e');
    }
  }

  Future<void> _addStylist() async {
    if (_stylistNameController.text.isEmpty ||
        _stylistSpecializationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (salonDocId != null) {
        await FirebaseFirestore.instance
            .collection('salon')
            .doc(salonDocId)
            .collection('stylists')
            .add({
          'name': _stylistNameController.text,
          'specialization': _stylistSpecializationController.text,
          'status': _stylistStatus,
          'categories': _stylistCategories.toList(), // Save multiple categories
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stylist added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _stylistNameController.clear();
        _stylistSpecializationController.clear();
        _stylistStatus = 'Available';
        _stylistCategories.clear(); // Reset categories
        setState(() {
          _isFormVisible = false;
        });

        _retrieveStylists();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding stylist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stylists', style: GoogleFonts.abel()),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _isFormVisible = true;
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Set the background color to white
        child: Stack(
          children: [
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : stylists.isEmpty
                    ? Center(
                        child: Text('No stylists found.',
                            style: GoogleFonts.abel(fontSize: 18)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: stylists.length,
                        itemBuilder: (context, index) {
                          return _buildStylistCard(stylists[index]);
                        },
                      ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _isFormVisible ? 0 : -1000,
              left: 0,
              right: 0,
              child: Card(
                color: Colors.white, // Set form card background to white
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add Stylist',
                            style: GoogleFonts.abel(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _isFormVisible = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _stylistNameController,
                        decoration: InputDecoration(
                          labelText: 'Stylist Name',
                          labelStyle: GoogleFonts.abel(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _stylistSpecializationController,
                        decoration: InputDecoration(
                          labelText: 'Specialization',
                          labelStyle: GoogleFonts.abel(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          labelStyle: GoogleFonts.abel(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        value: _stylistStatus,
                        items: <String>['Available', 'Unavailable']
                            .map((String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: GoogleFonts.abel()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _stylistStatus = value ?? 'Available';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: categories.map((category) {
                          return FilterChip(
                            label: Text(category, style: GoogleFonts.abel()),
                            selected: _stylistCategories.contains(category),
                            onSelected: (isSelected) {
                              setState(() {
                                isSelected
                                    ? _stylistCategories.add(category)
                                    : _stylistCategories.remove(category);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _addStylist,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff355E3B),
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Add Stylist',
                              style: GoogleFonts.abel(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStylistCard(Map<String, dynamic> stylist) {
    return Card(
      color: Colors.white, // Set stylist card background to white
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stylist['name'] ?? 'N/A',
              style:
                  GoogleFonts.abel(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Categories: ${stylist['categories'] is List ? (stylist['categories'] as List).join(', ') : stylist['categories']}',
              style: GoogleFonts.abel(),
            ),
            Text(
              'Specialization: ${stylist['specialization'] ?? 'N/A'}',
              style: GoogleFonts.abel(),
            ),
            Row(
              children: [
                Text('Status:', style: GoogleFonts.abel()),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: stylist['status'] ?? 'Available',
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      setState(() {
                        stylist['status'] = newStatus;
                        modifiedStylists[stylist['id']] = newStatus;
                      });
                    }
                  },
                  items: <String>['Available', 'Unavailable']
                      .map((status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status, style: GoogleFonts.abel()),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
