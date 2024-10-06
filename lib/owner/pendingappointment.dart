import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class Pendingappointment extends StatefulWidget {
  const Pendingappointment({super.key});

  @override
  State<Pendingappointment> createState() => _PendingappointmentState();
}

class _PendingappointmentState extends State<Pendingappointment> {
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

  // Function to update the appointment status and set isPaid to false
  Future<void> _acceptAppointment(String salonId, String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'Accepted',
        'isPaid': false,
      });

      if (mounted) {
        // Ensure the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment Accepted and marked as unpaid.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error accepting appointment: $e');
      if (mounted) {
        // Ensure the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept appointment.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateAppointmentStatus(
      String salonId, String appointmentId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': status});

      if (mounted) {
        // Ensure the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment $status successfully.'),
            backgroundColor: status == 'Accepted' ? Colors.green : Colors.red,
          ),
        );

        // Redirect to home page after status update
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error updating appointment status: $e');
      if (mounted) {
        // Ensure the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update appointment status.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to show confirmation dialog before updating status
  Future<void> _showConfirmationDialog(
      String appointmentId, String status) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Action',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to ${status.toLowerCase()} this appointment?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    status == 'Accepted' ? Colors.green : Colors.red,
              ),
              child: Text(
                status == 'Accepted' ? 'Accept' : 'Decline',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onPressed: () {
                if (status == 'Accepted') {
                  _acceptAppointment(_user!.uid,
                      appointmentId); // Set status to Accepted and isPaid to false
                } else {
                  _updateAppointmentStatus(_user!.uid, appointmentId,
                      status); // Update status as Declined
                }
                Navigator.of(context).pop(); // Close the confirmation dialog
                Navigator.of(context).pop(
                    true); // Close the Pendingappointment screen and pass true to refresh the dashboard
              },
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
        title: const Text(
          'Pending Appointments',
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
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending appointments found.',
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
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showConfirmationDialog(
                                    appointmentId,
                                    'Accepted',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Accept',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _showConfirmationDialog(
                                    appointmentId,
                                    'Declined',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'Decline',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
