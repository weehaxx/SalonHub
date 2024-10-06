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
  String _selectedFilter = 'Paid'; // Default filter to 'Paid'

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

  // Function to show the receipt details in a popup
  void _showReceiptDetails(String receiptUrl, String referenceNumber) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Payment Details',
            style: GoogleFonts.abel(),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _showFullImage(receiptUrl); // View image in full screen
                  },
                  child: receiptUrl.isNotEmpty
                      ? Image.network(
                          receiptUrl,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('Failed to load receipt image');
                          },
                        )
                      : const Text('No receipt image available'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Reference Number: $referenceNumber',
                  style: GoogleFonts.abel(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Function to show image in full screen
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // Close the full-screen image
            },
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Failed to load image'));
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Function to mark the appointment as paid
  Future<void> _markAsPaid(String salonId, String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('appointments')
          .doc(appointmentId)
          .update({'isPaid': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as Paid')),
      );
    } catch (e) {
      print('Error marking as paid: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark as paid')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xffFaF9F6),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Accepted Appointments',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              items: const [
                DropdownMenuItem(
                  value: 'Paid',
                  child: Text('Paid'),
                ),
                DropdownMenuItem(
                  value: 'Not Paid',
                  child: Text('Not Paid'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('salon')
                  .doc(_user?.uid)
                  .collection('appointments')
                  .where('status', isEqualTo: 'Accepted')
                  .where('isPaid', isEqualTo: _selectedFilter == 'Paid')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No appointments found.',
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
                    final appointment =
                        appointmentDoc.data() as Map<String, dynamic>;
                    final userId = appointment['userId'] ?? '';
                    final appointmentId = appointmentDoc.id;
                    final salonId =
                        _user?.uid ?? ''; // Assuming salonId is the user UID

                    return FutureBuilder<String>(
                      future: _fetchUserName(userId),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
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
                            ? services
                                .join(', ') // Join services if more than one
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
                                  style: GoogleFonts.abel(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${appointment['date']} at ${appointment['time']} with ${appointment['stylist']}',
                                  style: GoogleFonts.abel(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Set by: $userName',
                                  style: GoogleFonts.abel(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
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
                                  'Payment Status: $paymentStatus',
                                  style: GoogleFonts.abel(
                                    fontSize: 14,
                                    color: isPaid ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                if (isPaid)
                                  ElevatedButton(
                                    onPressed: () {
                                      _showReceiptDetails(
                                        appointment['receipt_url'] ?? '',
                                        appointment['reference_number'] ??
                                            'N/A',
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'See Details',
                                      style: GoogleFonts.abel(
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () {
                                      _markAsPaid(salonId, appointmentId);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Mark as Paid',
                                      style: GoogleFonts.abel(
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
          ),
        ],
      ),
    );
  }
}
