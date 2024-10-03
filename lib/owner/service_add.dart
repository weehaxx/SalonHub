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

class _AddServicePageState extends State<AddServicePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _searchController =
      TextEditingController(); // Search controller
  String? _selectedCategory; // For storing selected category
  final List<String> _categories = ['Hair', 'Nail', 'Massage', 'Others'];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isFormVisible = false; // Control form visibility

  String? _editingServiceId;
  String? _salonDocId; // To store the current salon document ID

  @override
  void initState() {
    super.initState();
    _retrieveSalonId(); // Retrieve the current user's salon document ID
  }

  // Retrieve the salon document ID for the current user
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

  // Log service changes to Firestore
  // Log service changes to Firestore in a user-specific sub-collection
  Future<void> _logServiceChange(String action, String serviceName,
      {Map<String, String>? previousData, String? newName}) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        String details = '';

        if (action == 'Edit' && previousData != null && newName != null) {
          // Create a log message showing the previous and updated name
          details =
              '${previousData['name']} has been modified to $newName (${previousData['category']})';
        } else if (action == 'Add') {
          details = 'A new service has been added: $serviceName';
        } else if (action == 'Delete') {
          details = 'Service deleted: $serviceName';
        }

        // Save log to the user's specific sub-collection
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('logs')
            .add({
          'action': action,
          'service_name': serviceName,
          'details': details,
          'timestamp': DateTime.now(),
        });
      }
    } catch (e) {
      print('Error logging service change: $e');
    }
  }

  // Show confirmation dialog for updating the service
  Future<bool?> _showUpdateConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Service'),
          content: const Text('Are you sure you want to update this service?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog for deleting the service
  Future<void> _confirmDeleteService(
      String serviceId, String serviceName) async {
    bool confirmed = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Service'),
              content:
                  const Text('Are you sure you want to delete this service?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Confirm'),
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
      _deleteService(
          serviceId, serviceName); // Proceed with deleting the service
    }
  }

  // Submit or Update Service - Keep this correct version
  void _submitForm() async {
    final String serviceName = _nameController.text;
    final String price = _priceController.text;
    final String? category = _selectedCategory;

    if (serviceName.isNotEmpty && price.isNotEmpty && category != null) {
      try {
        final User? user = _auth.currentUser;

        if (user != null && _salonDocId != null) {
          if (_editingServiceId == null) {
            // Add a new service under the current user's salon document
            await _firestore
                .collection('salon')
                .doc(_salonDocId)
                .collection('services')
                .add({
              'name': serviceName,
              'price': price,
              'category': category,
            });

            // Log the addition of the service
            await _logServiceChange('Add', serviceName);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Service added successfully!')),
            );
          } else {
            // Show confirmation dialog before updating
            bool? confirmed = await _showUpdateConfirmationDialog();

            if (confirmed == true) {
              // Update an existing service if confirmed
              final previousName = _previousServiceData['name'] ?? '';
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

              // Log the update, showing previous and new names
              await _logServiceChange('Edit', previousName,
                  previousData: _previousServiceData, newName: serviceName);

              setState(() {
                _editingServiceId = null; // Reset after updating
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Service updated successfully!')),
              );
            }
          }

          // Clear the text fields after submission
          _nameController.clear();
          _priceController.clear();
          setState(() {
            _selectedCategory = null; // Clear selected category
          });
          FocusScope.of(context).unfocus();

          // Hide the form after submission
          setState(() {
            _isFormVisible = false;
          });
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

  // Delete service
  void _deleteService(String serviceId, String serviceName) async {
    if (_salonDocId != null) {
      await _firestore
          .collection('salon')
          .doc(_salonDocId)
          .collection('services')
          .doc(serviceId)
          .delete();

      // Log the deletion of the service
      await _logServiceChange('Delete', serviceName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service deleted successfully!'),
        ),
      );
    }
  }

  // Edit service
  // Define a Map to store previous service data
  Map<String, String> _previousServiceData = {};

// Edit service: Capture previous data before editing
  void _editService(DocumentSnapshot service) {
    // Capture previous data before editing
    final previousName = service['name'] ?? '';
    final previousPrice = service['price'] ?? '';
    final previousCategory = service['category'] ?? '';

    setState(() {
      _editingServiceId = service.id;
      _nameController.text = previousName; // Set service name
      _priceController.text = previousPrice; // Set service price
      _selectedCategory = previousCategory; // Set service category
      _isFormVisible = true; // Show form when editing
    });

    // Store the previous data to log after updating
    _previousServiceData = {
      'name': previousName,
      'price': previousPrice,
      'category': previousCategory,
    };
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff355E3B),
        title: Text(
          'Manage Service',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
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
                    setState(
                        () {}); // Update the UI when the search query changes
                  },
                ),
                const SizedBox(height: 16), // Add some spacing
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

                            // Filter services based on the search query
                            final filteredServices = services.where((service) {
                              final serviceName =
                                  service['name'].toString().toLowerCase();
                              final serviceCategory =
                                  service['category'].toString().toLowerCase();
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

                            // Group services by category
                            Map<String, List<DocumentSnapshot>>
                                categorizedServices = {};
                            for (var service in filteredServices) {
                              String category = service['category'] ?? 'Others';
                              if (!categorizedServices.containsKey(category)) {
                                categorizedServices[category] = [];
                              }
                              categorizedServices[category]!.add(service);
                            }

                            return ListView(
                              children:
                                  categorizedServices.keys.map((category) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Text(
                                        category,
                                        style: GoogleFonts.poppins(
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
                                            title: Text(service['name'] ??
                                                'Unnamed Service'),
                                            subtitle: Text(
                                                'Price: ${service['price']}'),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blue),
                                                  onPressed: () =>
                                                      _editService(service),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  onPressed: () =>
                                                      _confirmDeleteService(
                                                          service.id,
                                                          service['name'] ??
                                                              'Unnamed Service'),
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
          // Add Service Form with Animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _isFormVisible ? 0 : -350, // Hide the form when not visible
            left: 0,
            right: 0,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Service Name',
                        labelStyle: GoogleFonts.poppins(
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
                        labelStyle: GoogleFonts.poppins(
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
                          child: Text(category),
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
                        onPressed:
                            _submitForm, // Trigger confirmation for update
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff355E3B),
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _editingServiceId == null
                              ? 'Add Service'
                              : 'Update Service',
                          style: GoogleFonts.poppins(
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff355E3B),
        onPressed: () {
          setState(() {
            _isFormVisible = !_isFormVisible; // Toggle form visibility
          });
        },
        child: Icon(
          _isFormVisible ? Icons.close : Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
