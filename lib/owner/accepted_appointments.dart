import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class Acceptedappointment extends StatefulWidget {
  const Acceptedappointment({super.key});

  @override
  State<Acceptedappointment> createState() => _AcceptedappointmentState();
}

class _AcceptedappointmentState extends State<Acceptedappointment> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // Function to fetch user name based on userId
  Future<String> _fetchUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown User'; // Fetch user name
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
    return 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Accepted Appointments',
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
            .where('status', isEqualTo: 'Accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No accepted appointments found.',
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
              final userId = appointment['userId'] ?? '';
              final appointmentId = appointmentDoc.id;

              return FutureBuilder<String>(
                future: _fetchUserName(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Card(
                        child: ListTile(
                          title: Text('Loading user...'),
                        ),
                      ),
                    );
                  }

                  final userName = userSnapshot.data ?? 'Unknown User';

                  // Handling multiple services
                  List<dynamic> services = appointment['services'] ?? [];
                  String servicesText = services.isNotEmpty
                      ? services.join(', ') // Join services if more than one
                      : 'No service';

                  // Check payment status
                  bool isPaid = appointment['isPaid'] ?? false;
                  String paymentStatus = isPaid ? 'Paid' : 'Not Paid';

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
                            servicesText, // Display all services
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${appointment['date']} at ${appointment['time']} with ${appointment['stylist']}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Set by: $userName',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Payment Status: $paymentStatus',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isPaid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              // Implement logic for accepting payments, marking as paid, etc.
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isPaid ? Colors.grey : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isPaid ? 'Mark as Unpaid' : 'Mark as Paid',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
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
          );
        },
      ),
    );
  }
}
