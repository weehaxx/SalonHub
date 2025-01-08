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
  late Stream<QuerySnapshot> _acceptedAppointmentsStream;

  @override
  void initState() {
    super.initState();
    _acceptedAppointmentsStream = _getAcceptedAppointmentsStream();
  }

  // Function to fetch accepted appointments stream based on selected filter
  Stream<QuerySnapshot> _getAcceptedAppointmentsStream() {
    final bool filterIsPaid =
        _selectedFilter == 'Paid'; // Map filter to boolean
    print("Fetching for status: 'Accepted' and isPaid: $filterIsPaid");
    return FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('appointments')
        .where('status', isEqualTo: 'Accepted') // Match 'Accepted'
        .where('isPaid', isEqualTo: filterIsPaid) // Match boolean filter
        .snapshots()
        .handleError((error) {
      print("Error fetching appointments: $error");
    });
  }

  // Refresh function
  Future<void> _refreshAppointments() async {
    setState(() {
      _acceptedAppointmentsStream = _getAcceptedAppointmentsStream();
    });
  }

  Future<String> _fetchUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
    return 'Unknown User';
  }

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
                    _showFullImage(receiptUrl);
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
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              items: [
                DropdownMenuItem(
                  value: 'Paid',
                  child: Text(
                    'Paid',
                    style: GoogleFonts.abel(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Not Paid',
                  child: Text(
                    'Not Paid',
                    style: GoogleFonts.abel(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                  _acceptedAppointmentsStream =
                      _getAcceptedAppointmentsStream();
                  print(
                      "Selected filter: $_selectedFilter"); // Log selected filter
                });
              },
              style: GoogleFonts.abel(fontSize: 16, color: Colors.black87),
              dropdownColor: Colors.white,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAppointments,
              child: StreamBuilder<QuerySnapshot>(
                stream: _acceptedAppointmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height -
                              kToolbarHeight,
                          child: const Center(
                            child: Text(
                              'No appointments found.',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
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
                      final userId = appointment['userId'] ?? '';

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
                          List<dynamic> services =
                              appointment['services'] ?? [];
                          String servicesText = services.isNotEmpty
                              ? services.join(', ')
                              : 'No service';

                          bool isPaid = appointment['isPaid'] ?? false;
                          String paymentStatus = isPaid ? 'Paid' : 'Not Paid';
                          String mainCategory =
                              appointment['main_category'] ?? 'Unknown';

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
                                  // Services
                                  Text(
                                    servicesText,
                                    style: GoogleFonts.abel(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Main Category
                                  Text(
                                    'Category: $mainCategory',
                                    style: GoogleFonts.abel(
                                      fontSize: 14,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Date, Time, and Stylist
                                  Text(
                                    '${appointment['date']} at ${appointment['time']} with ${appointment['stylist']}',
                                    style: GoogleFonts.abel(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // User Name
                                  Text(
                                    'Set by: $userName',
                                    style: GoogleFonts.abel(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Total Price
                                  Text(
                                    'Total Price: Php ${appointment['totalPrice']}',
                                    style: GoogleFonts.abel(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),

                                  // Payment Status
                                  Text(
                                    'Payment Status: $paymentStatus',
                                    style: GoogleFonts.abel(
                                      fontSize: 14,
                                      color: isPaid ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  // Receipt Button
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
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        'See Details',
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
          ),
        ],
      ),
    );
  }
}
