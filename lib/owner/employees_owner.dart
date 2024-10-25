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
  final TextEditingController _stylistNameController = TextEditingController();
  final TextEditingController _stylistSpecializationController =
      TextEditingController();
  String _stylistStatus = 'Available';
  final Set<String> _stylistCategories = {};
  bool _isFormVisible = false;

  final List<String> categories = [
    'Hair',
    'Nail',
    'Massage',
    'Others',
  ];

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
      final stylistDoc = await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonDocId)
          .collection('stylists')
          .doc(stylistId)
          .get();
      final oldData = stylistDoc.data() as Map<String, dynamic>?;

      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonDocId)
          .collection('stylists')
          .doc(stylistId)
          .update(updates);

      // Create log messages for each specific change
      if (oldData != null) {
        if (oldData['status'] != updates['status']) {
          await _createLog('Update Stylist',
              'Status changed from ${oldData['status']} to ${updates['status']}');
        }
        if (oldData['specialization'] != updates['specialization']) {
          await _createLog('Update Stylist',
              'Specialization updated from ${oldData['specialization']} to ${updates['specialization']}');
        }
        if (oldData['name'] != updates['name']) {
          await _createLog('Update Stylist',
              'Name changed from ${oldData['name']} to ${updates['name']}');
        }
        if (oldData['categories'] != updates['categories']) {
          await _createLog('Update Stylist', 'Categories updated');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stylist edited successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating stylist: $e');
    }
  }

  Future<void> _deleteStylist(String stylistId) async {
    if (salonDocId == null) return;
    try {
      final stylistToDelete =
          stylists.firstWhere((stylist) => stylist['id'] == stylistId);
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonDocId)
          .collection('stylists')
          .doc(stylistId)
          .delete();

      setState(() {
        stylists.removeWhere((stylist) => stylist['id'] == stylistId);
      });

      await _createLog(
          'Delete Stylist', 'Deleted stylist ${stylistToDelete['name']}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stylist deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting stylist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting stylist: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        final newStylist = {
          'name': _stylistNameController.text,
          'specialization': _stylistSpecializationController.text,
          'status': _stylistStatus,
          'categories': _stylistCategories.toList(),
        };

        await FirebaseFirestore.instance
            .collection('salon')
            .doc(salonDocId)
            .collection('stylists')
            .add(newStylist);

        await _createLog('Add Stylist',
            'Added stylist ${newStylist['name']} with specialization ${newStylist['specialization']} and status ${newStylist['status']}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stylist added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _stylistNameController.clear();
        _stylistSpecializationController.clear();
        _stylistStatus = 'Available';
        _stylistCategories.clear();
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

  Future<void> _createLog(String actionType, String description) async {
    if (salonDocId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonDocId)
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

  void _editStylist(Map<String, dynamic> stylist) {
    _stylistNameController.text = stylist['name'] ?? '';
    _stylistSpecializationController.text = stylist['specialization'] ?? '';
    _stylistStatus = stylist['status'] ?? 'Available';
    _stylistCategories.clear();
    _stylistCategories.addAll(List<String>.from(stylist['categories'] ?? []));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Stylist', style: GoogleFonts.abel()),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: 400,
                width: 300,
                child: Column(
                  children: [
                    TextField(
                      controller: _stylistNameController,
                      decoration: InputDecoration(
                        labelText: 'Stylist Name',
                        labelStyle: GoogleFonts.abel(),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _stylistSpecializationController,
                      decoration: InputDecoration(
                        labelText: 'Specialization',
                        labelStyle: GoogleFonts.abel(),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_stylistNameController.text.isNotEmpty &&
                    _stylistSpecializationController.text.isNotEmpty) {
                  await _updateStylist(stylist['id'], {
                    'name': _stylistNameController.text,
                    'specialization': _stylistSpecializationController.text,
                    'status': _stylistStatus,
                    'categories': _stylistCategories.toList(),
                  });
                  Navigator.of(context).pop();
                  _retrieveStylists();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill out all fields.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Save', style: GoogleFonts.abel()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.abel()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stylists', style: GoogleFonts.abel()),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Container(
        color: Colors.white,
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
            if (_isFormVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildAddStylistForm(),
              ),
          ],
        ),
      ),
      floatingActionButton: !_isFormVisible
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isFormVisible = true;
                });
              },
              backgroundColor: const Color(0xff355E3B),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildAddStylistForm() {
    return Card(
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }

  Widget _buildStylistCard(Map<String, dynamic> stylist) {
    return Card(
      color: Colors.white,
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
                  onChanged: (newStatus) async {
                    if (newStatus != null) {
                      setState(() {
                        stylist['status'] = newStatus;
                      });
                      await _updateStylist(
                          stylist['id'], {'status': newStatus});
                    }
                  },
                  items: <String>['Available', 'Unavailable']
                      .map((status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status, style: GoogleFonts.abel()),
                          ))
                      .toList(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editStylist(stylist),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteStylist(stylist['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
