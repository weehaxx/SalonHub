import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CancelledBookingsPage extends StatefulWidget {
  const CancelledBookingsPage({super.key});

  @override
  State<CancelledBookingsPage> createState() => _CancelledBookingsPageState();
}

class _CancelledBookingsPageState extends State<CancelledBookingsPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // Fetch cancelled bookings stream for the logged-in client
  Stream<QuerySnapshot> _getCancelledBookingsStream() {
    return FirebaseFirestore.instance
        .collectionGroup('appointments') // Fetch appointments across all salons
        .where('userId', isEqualTo: _user?.uid) // Filter by client userId
        .where('status', isEqualTo: 'Declined') // Filter only declined bookings
        .snapshots();
  }

  // Fetch salon name dynamically
  Future<String> _getSalonName(String salonId) async {
    try {
      final salonDoc = await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .get();
      return salonDoc.data()?['salon_name'] ?? 'Unknown Salon';
    } catch (e) {
      return 'Unknown Salon';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cancelled Bookings',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xffFaF9F6),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getCancelledBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: Colors.grey, size: 50),
                  const SizedBox(height: 10),
                  const Text(
                    'No cancelled bookings found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final booking = bookingDoc.data() as Map<String, dynamic>;
              final salonId = bookingDoc.reference.parent.parent?.id ?? '';

              return FutureBuilder<String>(
                future: _getSalonName(salonId),
                builder: (context, salonSnapshot) {
                  final salonName = salonSnapshot.data ?? 'Loading...';

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
                            'Salon: $salonName',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Client Name: ${booking['userName'] ?? 'No name provided'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Service: ${booking['services']?.join(', ') ?? 'No service'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Stylist: ${booking['stylist'] ?? 'Not assigned'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Total Price: Php ${booking['totalPrice']?.toString() ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Cancellation Reason: ${booking['declineReason'] ?? 'No reason provided'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Date: ${booking['date'] ?? 'No date provided'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Time: ${booking['time'] ?? 'No time provided'}',
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
          );
        },
      ),
    );
  }
}
