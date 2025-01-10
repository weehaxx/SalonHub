import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CancellationPage extends StatefulWidget {
  const CancellationPage({super.key});

  @override
  _CancellationPageState createState() => _CancellationPageState();
}

class _CancellationPageState extends State<CancellationPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> _cancellationStream;

  @override
  void initState() {
    super.initState();
    _cancellationStream = _getCancellationsStream();
  }

  // Fetch cancellations stream
  Stream<QuerySnapshot> _getCancellationsStream() {
    return FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('appointments')
        .where('status', isEqualTo: 'Canceled')
        .snapshots();
  }

  // Refresh function
  Future<void> _refreshCancellations() async {
    setState(() {
      _cancellationStream = _getCancellationsStream();
    });
  }

  // Method to remove a canceled appointment
  Future<void> _removeAppointment(String salonId, String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment removed successfully.')),
      );
    } catch (e) {
      print('Error removing appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cancelled Appointments',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xffFaF9F6),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cancellationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshCancellations,
            child: snapshot.hasData && snapshot.data!.docs.isNotEmpty
                ? ListView(
                    children: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.red.shade200, width: 1),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Client Name and Delete Button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Client: ${data['userName'] ?? 'Unknown'}',
                                      style: GoogleFonts.abel(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      final confirmed =
                                          await _showDeleteConfirmationDialog();
                                      if (confirmed == true) {
                                        _removeAppointment(_user!.uid, doc.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Appointment Details
                              Row(
                                children: [
                                  const Icon(Icons.category,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Category: ${data['main_category'] ?? 'Unknown'}',
                                      style: GoogleFonts.abel(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.design_services,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Service: ${data['services'][0] ?? 'No service provided'}',
                                      style: GoogleFonts.abel(
                                        fontSize: 14,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Stylist: ${data['stylist'] ?? 'Unknown'}',
                                      style: GoogleFonts.abel(
                                        fontSize: 14,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.red, height: 20),

                              // Pricing and Cancellation Details
                              Row(
                                children: [
                                  const Icon(Icons.attach_money,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Price: Php ${data['totalPrice']?.toString() ?? 'N/A'}',
                                      style: GoogleFonts.abel(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cancelled On: ${data['date'] ?? 'No date provided'} at ${data['time'] ?? 'No time provided'}',
                                      style: GoogleFonts.abel(
                                        fontSize: 14,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Cancellation Reason
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info,
                                      size: 18, color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Reason: ${data['declineReason'] ?? data['cancelReason'] ?? 'No reason provided'}',
                                      style: GoogleFonts.abel(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : ListView(
                    // This provides a scrollable area even when no data is available
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height -
                            kToolbarHeight, // Ensures enough space to pull down
                        child: const Center(
                          child: Text('No cancellations found.'),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  // Method to show a confirmation dialog before deleting an appointment
  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
            'Are you sure you want to remove this canceled appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
