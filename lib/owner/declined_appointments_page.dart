import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeclinedAppointmentsPage extends StatefulWidget {
  const DeclinedAppointmentsPage({super.key});

  @override
  State<DeclinedAppointmentsPage> createState() =>
      _DeclinedAppointmentsPageState();
}

class _DeclinedAppointmentsPageState extends State<DeclinedAppointmentsPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> _declinedAppointmentsStream;
  String? _selectedReason; // Holds the currently selected filter

  @override
  void initState() {
    super.initState();
    _declinedAppointmentsStream = _getDeclinedAppointmentsStream();
  }

  // Fetch declined appointments stream
  Stream<QuerySnapshot> _getDeclinedAppointmentsStream() {
    Query query = FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('appointments')
        .where('status', isEqualTo: 'Canceled');

    if (_selectedReason != null && _selectedReason!.isNotEmpty) {
      query = query.where('declineReason', isEqualTo: _selectedReason);
    }

    return query.snapshots();
  }

  // Refresh function
  Future<void> _refreshDeclinedAppointments() async {
    setState(() {
      _declinedAppointmentsStream = _getDeclinedAppointmentsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final predefinedReasons = [
      'Fully booked',
      'Staff unavailable',
      'Service not available',
      'Failure to accept or decline appointment', // Added to track this reason
      'Other reasons',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Declined Appointments',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xffFaF9F6),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedReason,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All Reasons'),
                      ),
                      ...predefinedReasons.map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value?.isEmpty ?? true ? null : value;
                        _declinedAppointmentsStream =
                            _getDeclinedAppointmentsStream();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Filter by Reason',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Declined Appointments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _declinedAppointmentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return ListView(
                    children: [
                      SizedBox(
                        height:
                            MediaQuery.of(context).size.height - kToolbarHeight,
                        child: const Center(
                          child: Text(
                            'No declined appointments found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final appointments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointmentDoc = appointments[index];
                    final appointment =
                        appointmentDoc.data() as Map<String, dynamic>;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Client: ${appointment['userName'] ?? 'Unknown'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Category: ${appointment['main_category'] ?? 'Unknown'}', // Display main_category
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Service: ${appointment['services']?.join(', ') ?? 'No service'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Stylist: ${appointment['stylist'] ?? 'Unknown'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Total Price: Php ${appointment['totalPrice']?.toString() ?? 'N/A'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Decline Reason: ${appointment['declineReason'] ?? 'No reason provided'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Date: ${appointment['date'] ?? 'No date provided'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Time: ${appointment['time'] ?? 'No time provided'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
