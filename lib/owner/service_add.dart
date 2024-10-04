import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddServiceApp extends StatelessWidget {
  const AddServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manage Service',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AddServicePage(),
    );
  }
}

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

  @override
  _AddServicePageState createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  final List<String> _categories = ['Hair', 'Nail', 'Massage', 'Others'];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isFormVisible = false;

  String? _editingServiceId;
  String? _salonDocId;

  @override
  void initState() {
    super.initState();
    _retrieveSalonId();
  }

  Future<void> _retrieveSalonId() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection('salon')
            .where('owner_uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _salonDocId = querySnapshot.docs.first.id;
          });
        }
      } catch (e) {
        print('Error retrieving salon document: $e');
      }
    }
  }

  void _toggleFormVisibility() {
    setState(() {
      if (_isFormVisible) {
        _nameController.clear();
        _priceController.clear();
        _selectedCategory = null;
        _editingServiceId = null;
      }
      _isFormVisible = !_isFormVisible;
    });
  }

  Future<void> _confirmDeleteService(
      String serviceId, String serviceName) async {
    bool confirmed = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Service', style: GoogleFonts.abel()),
              content: Text('Are you sure you want to delete this service?',
                  style: GoogleFonts.abel()),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel', style: GoogleFonts.abel()),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('Confirm', style: GoogleFonts.abel()),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmed) {
      _deleteService(serviceId, serviceName);
    }
  }

  void _deleteService(String serviceId, String serviceName) async {
    if (_salonDocId != null) {
      await _firestore
          .collection('salon')
          .doc(_salonDocId)
          .collection('services')
          .doc(serviceId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service deleted successfully!'),
        ),
      );
    }
  }

  void _submitForm() async {
    final String serviceName = _nameController.text;
    final String price = _priceController.text;
    final String? category = _selectedCategory;

    if (serviceName.isNotEmpty && price.isNotEmpty && category != null) {
      try {
        final User? user = _auth.currentUser;

        if (user != null && _salonDocId != null) {
          if (_editingServiceId == null) {
            await _firestore
                .collection('salon')
                .doc(_salonDocId)
                .collection('services')
                .add({
              'name': serviceName,
              'price': price,
              'category': category,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Service added successfully!')),
            );
          } else {
            await _firestore
                .collection('salon')
                .doc(_salonDocId)
                .collection('services')
                .doc(_editingServiceId)
                .update({
              'name': serviceName,
              'price': price,
              'category': category,
            });

            setState(() {
              _editingServiceId = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Service updated successfully!')),
            );
          }

          _toggleFormVisibility();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all fields.'),
        ),
      );
    }
  }

  void _editService(DocumentSnapshot service) {
    final serviceName = service['name'] ?? '';
    final servicePrice = service['price'] ?? '';
    final serviceCategory = service['category'] ?? '';

    setState(() {
      _editingServiceId = service.id;
      _nameController.text = serviceName;
      _priceController.text = servicePrice;
      _selectedCategory = serviceCategory;
      _isFormVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Manage Service',
          style: GoogleFonts.abel(
            textStyle: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search services or categories...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _salonDocId == null
                        ? const Center(child: CircularProgressIndicator())
                        : StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('salon')
                                .doc(_salonDocId)
                                .collection('services')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text('Error loading services'),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              final services = snapshot.data?.docs ?? [];

                              final filteredServices =
                                  services.where((service) {
                                final serviceName =
                                    service['name'].toString().toLowerCase();
                                final serviceCategory = service['category']
                                    .toString()
                                    .toLowerCase();
                                final query =
                                    _searchController.text.toLowerCase();
                                return serviceName.contains(query) ||
                                    serviceCategory.contains(query);
                              }).toList();

                              if (filteredServices.isEmpty) {
                                return const Center(
                                  child: Text('No services found.'),
                                );
                              }

                              Map<String, List<DocumentSnapshot>>
                                  categorizedServices = {};
                              for (var service in filteredServices) {
                                String category =
                                    service['category'] ?? 'Others';
                                if (!categorizedServices
                                    .containsKey(category)) {
                                  categorizedServices[category] = [];
                                }
                                categorizedServices[category]!.add(service);
                              }

                              return ListView(
                                children:
                                    categorizedServices.keys.map((category) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          category,
                                          style: GoogleFonts.abel(
                                            textStyle: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        children: categorizedServices[category]!
                                            .map((service) {
                                          return Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            elevation: 2,
                                            child: ListTile(
                                              title: Text(
                                                service['name'] ??
                                                    'Unnamed Service',
                                                style: GoogleFonts.abel(),
                                              ),
                                              subtitle: Text(
                                                'Price: ${service['price']}',
                                                style: GoogleFonts.abel(),
                                              ),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        _editService(service),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      elevation: 4,
                                                      minimumSize:
                                                          const Size(40, 40),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        _confirmDeleteService(
                                                            service.id,
                                                            service['name'] ??
                                                                'Unnamed Service'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      elevation: 4,
                                                      minimumSize:
                                                          const Size(40, 40),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.delete,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: _isFormVisible ? 0 : -350,
              left: 0,
              right: 0,
              child: Card(
                color: Colors.white,
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
                            _editingServiceId == null
                                ? 'Add Service'
                                : 'Edit Service',
                            style: GoogleFonts.abel(
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _toggleFormVisibility,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Service Name',
                          labelStyle: GoogleFonts.abel(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          labelStyle: GoogleFonts.abel(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        value: _selectedCategory,
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category, style: GoogleFonts.abel()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff355E3B),
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 6,
                          ),
                          child: Text(
                            _editingServiceId == null
                                ? 'Add Service'
                                : 'Update Service',
                            style: GoogleFonts.abel(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff355E3B),
        onPressed: _toggleFormVisibility,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        child: Icon(
          _isFormVisible ? Icons.close : Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
