import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PaidAppointmentsPage extends StatefulWidget {
  const PaidAppointmentsPage({super.key});

  @override
  _PaidAppointmentsPageState createState() => _PaidAppointmentsPageState();
}

class _PaidAppointmentsPageState extends State<PaidAppointmentsPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String todayDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.now()); // Get today's date in 'yyyy-MM-dd' format
  late Stream<QuerySnapshot> _paidAppointmentsStream;

  @override
  void initState() {
    super.initState();
    _paidAppointmentsStream = _getPaidAppointmentsStream();
  }

  // Function to fetch the stream of paid appointments for today
  Stream<QuerySnapshot> _getPaidAppointmentsStream() {
    return FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('appointments')
        .where('status', isEqualTo: 'Accepted') // Filter by Accepted status
        .where('isPaid', isEqualTo: true) // Filter by Paid appointments
        .where('date', isEqualTo: todayDate) // Filter by today's date
        .snapshots();
  }

  // Function to mark an appointment as done
  // Function to mark an appointment as done
  Future<void> _markAppointmentDone(
      String appointmentId, String clientId, String referenceNumber) async {
    try {
      // Update the status of the appointment to 'Done' and set 'isReviewed' to false
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'Done',
        'isReviewed': false, // Add this field to indicate it needs a review
      });

      // Send a review notification to the client
      await FirebaseFirestore.instance
          .collection('users')
          .doc(clientId)
          .collection('notifications')
          .add({
        'title': 'Review Your Experience',
        'message':
            'You completed an appointment. Click here to review your experience.',
        'reference_number': referenceNumber,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      _showSnackbar(
          'Appointment marked as done. Client will receive a review prompt.',
          isSuccess: true);
    } catch (e) {
      _showSnackbar('Failed to mark appointment as done: $e');
    }
  }

  // Snackbar display function
  void _showSnackbar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  // Refresh function
  Future<void> _refreshAppointments() async {
    setState(() {
      _paidAppointmentsStream = _getPaidAppointmentsStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Paid Appointments Today',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xffFaF9F6),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAppointments,
        child: StreamBuilder<QuerySnapshot>(
          stream: _paidAppointmentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height - kToolbarHeight,
                    child: const Center(
                      child: Text(
                        'No paid appointments found for today.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
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

                String mainCategory = appointment['main_category'] ??
                    'Unknown'; // Added this line

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 6,
                          offset: const Offset(0, 3), // Shadow position
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and Time
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${appointment['date']} at ${appointment['time']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Stylist
                        Row(
                          children: [
                            const Icon(Icons.person,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Stylist: ${appointment['stylist']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Main Category
                        Row(
                          children: [
                            const Icon(Icons.category,
                                size: 18, color: Colors.blueAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Category: $mainCategory',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Total Price
                        Row(
                          children: [
                            const Icon(Icons.attach_money,
                                size: 18, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Total Price: Php ${appointment['totalPrice']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Reference Number
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reference Number: ${appointment['reference_number']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: Colors.grey),

                        // Action Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _markAppointmentDone(
                                appointmentDoc.id,
                                appointment['userId'],
                                appointment['reference_number'],
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff355E3B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.done,
                                size: 20, color: Colors.white),
                            label: Text(
                              'Mark as Done',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
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
    );
  }
}
