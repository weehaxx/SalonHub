import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TodaysAppointmentsPage extends StatefulWidget {
  const TodaysAppointmentsPage({super.key});

  @override
  _TodaysAppointmentsPageState createState() => _TodaysAppointmentsPageState();
}

class _TodaysAppointmentsPageState extends State<TodaysAppointmentsPage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  String todayDate =
      DateFormat('yyyy-MM-dd').format(DateTime.now()); // Get today's date

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Today\'s Appointments',
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
            .where('date', isEqualTo: todayDate) // Filter by today's date
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No appointments found for today.',
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

              bool isPaid = appointment['isPaid'] ?? false;
              String paymentStatus = isPaid ? 'Paid' : 'Unpaid';

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
                        'Payment Status: $paymentStatus',
                        style: GoogleFonts.abel(
                          fontSize: 14,
                          color: isPaid ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
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
