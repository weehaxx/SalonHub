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
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            margin: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.green.shade300, width: 1),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Service Name
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            servicesText,
                                            style: GoogleFonts.abel(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.green.shade800,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPaid
                                                ? Colors.green.shade300
                                                : Colors.red.shade300,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            paymentStatus,
                                            style: GoogleFonts.abel(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Main Category
                                    Text(
                                      'Category: $mainCategory',
                                      style: GoogleFonts.abel(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Appointment Details
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${appointment['date']} at ${appointment['time']}',
                                            style: GoogleFonts.abel(
                                              fontSize: 14,
                                              color: Colors.green.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.person,
                                            size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Stylist: ${appointment['stylist']}',
                                            style: GoogleFonts.abel(
                                              fontSize: 14,
                                              color: Colors.green.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline,
                                            size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Set by: $userName',
                                            style: GoogleFonts.abel(
                                              fontSize: 14,
                                              color: Colors.green.shade600,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                        color: Colors.green, height: 20),

                                    // Total Price
                                    Row(
                                      children: [
                                        const Icon(Icons.attach_money,
                                            size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Total Price: Php ${appointment['totalPrice']}',
                                            style: GoogleFonts.abel(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),

                                    // Receipt Button
                                    if (isPaid)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            _showReceiptDetails(
                                              appointment['receipt_url'] ?? '',
                                              appointment['reference_number'] ??
                                                  'N/A',
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade600,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 10),
                                          ),
                                          icon: const Icon(Icons.receipt,
                                              size: 20, color: Colors.white),
                                          label: Text(
                                            'View Receipt',
                                            style: GoogleFonts.abel(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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
