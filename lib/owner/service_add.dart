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
  final List<String> _categories = ['Hair', 'Nail', 'Spa', 'Others'];
  final List<String> _mainCategories = ['Male', 'Female'];
  String _filterMainCategory = 'All'; // Default to showing all categories

  String? _selectedCategory;
  String? _selectedMainCategory;
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

  Future<void> _createLog(String actionType, String description) async {
    if (_salonDocId != null) {
      try {
        await _firestore
            .collection('salon')
            .doc(_salonDocId)
            .collection('logs')
            .add({
          'actionType': actionType,
          'description': description,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error creating log: $e');
      }
    }
  }

  void _toggleFormVisibility() {
    setState(() {
      if (_isFormVisible) {
        _nameController.clear();
        _priceController.clear();
        _selectedCategory = null;
        _selectedMainCategory = null;
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

      // Create log entry for deletion
      await _createLog('Delete Service', 'Deleted service $serviceName');
    }
  }

  void _submitForm() async {
    final String serviceName = _nameController.text.trim();
    final String price = _priceController.text.trim();
    final String? category = _selectedCategory;
    final String? main_category = _selectedMainCategory;

    if (serviceName.isNotEmpty &&
        price.isNotEmpty &&
        category != null &&
        main_category != null) {
      try {
        if (_salonDocId != null) {
          // Check if a service with the same name already exists in the selected main category
          final existingServiceQuery = await _firestore
              .collection('salon')
              .doc(_salonDocId)
              .collection('services')
              .where('name', isEqualTo: serviceName)
              .where('main_category', isEqualTo: main_category)
              .get();

          if (existingServiceQuery.docs.isNotEmpty) {
            // If a duplicate is found during editing and it's not the same service being edited
            if (_editingServiceId == null ||
                (existingServiceQuery.docs.first.id != _editingServiceId)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Service "$serviceName" already exists in $main_category.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
          }

          if (_editingServiceId == null) {
            // Adding new service
            await _firestore
                .collection('salon')
                .doc(_salonDocId)
                .collection('services')
                .add({
              'name': serviceName,
              'price': price,
              'category': category,
              'main_category': main_category,
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Service added successfully!')),
            );

            // Log the service addition
            await _createLog('Add Service',
                'Added service $serviceName in $main_category with price $price and category $category');
          } else {
            // Updating existing service
            final serviceDoc = await _firestore
                .collection('salon')
                .doc(_salonDocId)
                .collection('services')
                .doc(_editingServiceId)
                .get();
            final oldData = serviceDoc.data();

            await _firestore
                .collection('salon')
                .doc(_salonDocId)
                .collection('services')
                .doc(_editingServiceId)
                .update({
              'name': serviceName,
              'price': price,
              'category': category,
              'main_category': main_category,
            });

            setState(() {
              _editingServiceId = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Service updated successfully!')),
            );

            // Log the service update with detailed changes
            String logDescription =
                'Updated service in $main_category with the following changes:';
            if (oldData != null) {
              if (oldData['name'] != serviceName) {
                logDescription +=
                    ' name changed from "${oldData['name']}" to "$serviceName".';
              }
              if (oldData['price'] != price) {
                logDescription +=
                    ' price changed from ${oldData['price']} to $price.';
              }
              if (oldData['category'] != category) {
                logDescription +=
                    ' category changed from ${oldData['category']} to $category.';
              }
            }
            await _createLog('Update Service', logDescription);
          }

          _toggleFormVisibility();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editService(DocumentSnapshot service) {
    final serviceName = service['name'] ?? '';
    final servicePrice = service['price'] ?? '';
    final serviceCategory = service['category'] ?? '';
    final serviceMainCategory = service['main_category'] ?? '';

    setState(() {
      _editingServiceId = service.id;
      _nameController.text = serviceName;
      _priceController.text = servicePrice;
      _selectedCategory = serviceCategory;
      _selectedMainCategory = serviceMainCategory;
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
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Dropdown for filtering by Main Category
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Main Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _filterMainCategory,
                  items: ['All', 'Male', 'Female']
                      .map((filter) => DropdownMenuItem<String>(
                            value: filter,
                            child: Text(filter),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterMainCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Search bar for searching services
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search services, categories, or main category...',
                    hintStyle: GoogleFonts.abel(),
                    labelStyle: GoogleFonts.abel(),
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
                            final filteredServices = services.where((service) {
                              final data =
                                  service.data() as Map<String, dynamic>;

                              final serviceName =
                                  (data['name'] ?? '').toString().toLowerCase();
                              final serviceCategory = (data['category'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final serviceMainCategory = data
                                      .containsKey('main_category')
                                  ? (data['main_category'] ?? 'Others')
                                      .toString()
                                      .toLowerCase()
                                  : 'Others'; // Default to 'Others' if the field doesn't exist
                              final query =
                                  _searchController.text.toLowerCase();

                              // Check if the service matches the selected filter and search query
                              final matchesMainCategory =
                                  _filterMainCategory == 'All' ||
                                      serviceMainCategory ==
                                          _filterMainCategory.toLowerCase();

                              final matchesSearchQuery =
                                  serviceName.contains(query) ||
                                      serviceCategory.contains(query);

                              return matchesMainCategory && matchesSearchQuery;
                            }).toList();
                            if (filteredServices.isEmpty) {
                              return const Center(
                                  child: Text('No services found.'));
                            }

                            Map<String, Map<String, List<DocumentSnapshot>>>
                                categorizedServices = {};
                            for (var service in filteredServices) {
                              String main_category =
                                  service['main_category'] ?? 'Others';
                              String category = service['category'] ?? 'Others';

                              categorizedServices.putIfAbsent(
                                  main_category, () => {});
                              categorizedServices[main_category]!
                                  .putIfAbsent(category, () => []);
                              categorizedServices[main_category]![category]!
                                  .add(service);
                            }

                            return ListView(
                              children: categorizedServices.keys.map(
                                (main_category) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          main_category,
                                          style: GoogleFonts.abel(
                                            textStyle: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      ...categorizedServices[main_category]!
                                          .keys
                                          .map((category) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4.0),
                                              child: Text(
                                                category,
                                                style: GoogleFonts.abel(
                                                  textStyle: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Column(
                                              children: categorizedServices[
                                                      main_category]![category]!
                                                  .map((service) {
                                                return Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  margin: const EdgeInsets
                                                      .symmetric(vertical: 8),
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
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed: () =>
                                                              _editService(
                                                                  service),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.blue,
                                                            elevation: 4,
                                                            minimumSize:
                                                                const Size(
                                                                    40, 40),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                            Icons.edit,
                                                            color: Colors.white,
                                                            size: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
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
                                                                const Size(
                                                                    40, 40),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
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
                                    ],
                                  );
                                },
                              ).toList(),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: _isFormVisible,
            child: AnimatedPositioned(
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
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Main Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _selectedMainCategory,
                        items: _mainCategories.map((mainCategory) {
                          return DropdownMenuItem<String>(
                            value: mainCategory,
                            child: Text(mainCategory),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMainCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
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
          ),
        ],
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
