import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date formatting

class PaidAppointmentsPage extends StatefulWidget {
  const PaidAppointmentsPage({super.key});

  @override
  _PaidAppointmentsPageState createState() => _PaidAppointmentsPageState();
}

class _PaidAppointmentsPageState extends State<PaidAppointmentsPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String todayDate = DateFormat('yyyy-MM-dd')
      .format(DateTime.now()); // Get today's date in 'yyyy-MM-dd' format

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('salon')
            .doc(_user?.uid)
            .collection('appointments')
            .where('status', isEqualTo: 'Accepted') // Filter by Accepted status
            .where('isPaid', isEqualTo: true) // Filter by Paid appointments
            .where('date', isEqualTo: todayDate) // Filter by today's date
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No paid appointments found for today.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointmentDoc = appointments[index];
              final appointment = appointmentDoc.data() as Map<String, dynamic>;

              // Display the appointment details
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
                        '${appointment['date']} at ${appointment['time']}',
                        style: GoogleFonts.abel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Stylist: ${appointment['stylist']}',
                        style: GoogleFonts.abel(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Total Price: Php ${appointment['totalPrice']}',
                        style: GoogleFonts.abel(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Reference Number: ${appointment['reference_number']}',
                        style: GoogleFonts.abel(
                          fontSize: 14,
                          color: Colors.grey[600],
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
    );
  }
}
