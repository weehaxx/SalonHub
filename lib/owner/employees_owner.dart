import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeesOwner extends StatefulWidget {
  const EmployeesOwner({super.key});

  @override
  State<EmployeesOwner> createState() => _EmployeesOwnerState();
}

class _EmployeesOwnerState extends State<EmployeesOwner> {
  String? salonDocId; // To store the salon document ID
  bool isLoading = true;
  List<Map<String, dynamic>> stylists = [];
  Map<String, String> modifiedStylists =
      {}; // To track changes in stylist status

  // Form fields for adding a new stylist
  final TextEditingController _stylistNameController = TextEditingController();
  final TextEditingController _stylistSpecializationController =
      TextEditingController();
  String _stylistStatus = 'Available'; // Default status
  bool _isFormVisible = false; // Control form visibility

  @override
  void initState() {
    super.initState();
    _retrieveStylists();
  }

  // Retrieve stylist data based on the current owner
  Future<void> _retrieveStylists() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Query the 'salon' collection to get the salon document ID
        QuerySnapshot salonSnapshot = await FirebaseFirestore.instance
            .collection('salon')
            .where('owner_uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (salonSnapshot.docs.isNotEmpty) {
          salonDocId = salonSnapshot.docs.first.id;
          // Now fetch the stylists from the 'stylists' subcollection
          QuerySnapshot stylistSnapshot = await FirebaseFirestore.instance
              .collection('salon')
              .doc(salonDocId)
              .collection('stylists')
              .get();

          setState(() {
            stylists = stylistSnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              // Add default value for 'status' if it doesn't exist
              if (!data.containsKey('status') || data['status'].isEmpty) {
                data['status'] = 'Available'; // Default to Available
                _updateStylistStatus(doc.id, 'Available'); // Update Firestore
              }
              return {
                ...data,
                'id': doc.id, // Add document ID for future updates
              };
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

  // Update the stylist's status in Firestore
  Future<void> _updateStylistStatus(String stylistId, String status) async {
    if (salonDocId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonDocId)
          .collection('stylists')
          .doc(stylistId)
          .update({'status': status});
    } catch (e) {
      print('Error updating stylist status: $e');
    }
  }

  // Save all changes in status to Firestore
  Future<void> _saveChanges() async {
    for (var entry in modifiedStylists.entries) {
      await _updateStylistStatus(entry.key, entry.value);
    }

    // Clear modified stylists after saving changes
    setState(() {
      modifiedStylists.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All changes saved successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Function to add a new stylist to Firestore
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
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stylist added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear the form fields
        _stylistNameController.clear();
        _stylistSpecializationController.clear();
        _stylistStatus = 'Available';
        setState(() {
          _isFormVisible = false;
        });

        // Refresh the stylist list
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
        title: const Text('Stylists'),
        backgroundColor: const Color(0xff355E3B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _isFormVisible = true; // Show the add stylist form
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : stylists.isEmpty
                  ? const Center(
                      child: Text(
                        'No stylists found.',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: stylists.length,
                      itemBuilder: (context, index) {
                        return _buildStylistCard(stylists[index]);
                      },
                    ),
          // Add Stylist Form with Animation
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Stylist',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _isFormVisible = false; // Hide the form
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
                      controller: _stylistSpecializationController,
                      decoration: InputDecoration(
                        labelText: 'Specialization',
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
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      value: _stylistStatus,
                      items: <String>['Available', 'Unavailable']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _stylistStatus = value ?? 'Available';
                        });
                      },
                    ),
                    const SizedBox(height: 30),
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
                        child: const Text(
                          'Add Stylist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
      // Floating save button that appears when there are changes
      floatingActionButton: modifiedStylists.isNotEmpty
          ? FloatingActionButton(
              onPressed: _saveChanges,
              backgroundColor: const Color(0xff355E3B),
              tooltip: 'Save Changes',
              elevation: 4,
              child: const Icon(Icons.save),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Helper method to build a card for each stylist
  Widget _buildStylistCard(Map<String, dynamic> stylist) {
    String status = stylist['status'] ?? 'Available'; // Default to Available

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 15), // Spacing between cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                stylist['name'] ?? 'N/A',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Specialization: ${stylist['specialization'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: status,
                            items: <String>['Available', 'Unavailable']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() {
                                  stylist['status'] = newValue;
                                  modifiedStylists[stylist['id']] = newValue;
                                });
                              }
                            },
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
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
