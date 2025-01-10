import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReschedulePage extends StatefulWidget {
  const ReschedulePage({super.key});

  @override
  _ReschedulePageState createState() => _ReschedulePageState();
}

class _ReschedulePageState extends State<ReschedulePage> {
  final User? _user = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> _rescheduleStream;

  @override
  void initState() {
    super.initState();
    _rescheduleStream = _getRescheduleStream();
  }

  // Fetch reschedule stream
  Stream<QuerySnapshot> _getRescheduleStream() {
    return FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('appointments')
        .where('status', isEqualTo: 'Rescheduled')
        .snapshots();
  }

  // Refresh function
  Future<void> _refreshReschedules() async {
    setState(() {
      _rescheduleStream = _getRescheduleStream();
    });
  }

  // Accept a reschedule request
  Future<void> _acceptReschedule(
      String appointmentId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'Accepted',
        'date': data['date'], // Update to the new requested date
        'time': data['time'], // Update to the new requested time
        'rescheduled': false, // Clear the reschedule flag
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reschedule accepted and appointment confirmed.')),
      );
      Navigator.pop(
          context, true); // Return true when the reschedule is accepted
    } catch (e) {
      print('Error accepting reschedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept reschedule: $e')),
      );
    }
  }

  // Decline a reschedule request with a reason
  Future<void> _declineReschedule(String appointmentId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reschedule declined. Reason: $reason')),
      );
      Navigator.pop(
          context, true); // Return true when the reschedule is declined
    } catch (e) {
      print('Error declining reschedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline reschedule: $e')),
      );
    }
  }

  // Show confirmation dialog
  Future<bool?> _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No', style: GoogleFonts.poppins(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Yes', style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ],
        );
      },
    );
  }

  // Show decline reason dialog
  Future<void> _showDeclineReasonDialog(String appointmentId) async {
    String? selectedReason;
    final List<String> predefinedReasons = [
      'Client did not confirm',
      'Stylist unavailable',
      'Service not available',
      'Other reasons',
    ];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Decline Reschedule',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please select a reason for declining this reschedule:',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: predefinedReasons
                    .map((reason) => DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason,
                              style: GoogleFonts.poppins(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedReason != null) {
                  _declineReschedule(appointmentId, selectedReason!);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a reason to decline.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Decline', style: GoogleFonts.poppins(fontSize: 14)),
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
        title: const Text('Reschedule Requests',
            style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xffFaF9F6),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReschedules,
        child: StreamBuilder<QuerySnapshot>(
          stream: _rescheduleStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return snapshot.hasData && snapshot.data!.docs.isNotEmpty
                ? ListView(
                    children: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;

// Extracting the services, price, and main_category information
                      List<dynamic> services = data['services'] ?? [];
                      String formattedServices = services.join(', ');
                      String price = data['totalPrice'].toString();
                      String mainCategory = data['main_category'] ??
                          'Unknown'; // Extract main_category

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
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
// Header: Client Name and Category Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Client: ${data['userName']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      mainCategory,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

// Services and Price
                              Row(
                                children: [
                                  const Icon(Icons.design_services,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Services: $formattedServices',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Price: Php $price',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

// Date and Time Information
                              Text(
                                'Previous Schedule:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${data['previousDate']} at ${data['previousTime']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              Text(
                                'Requested Reschedule:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month,
                                      size: 18, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${data['date']} at ${data['time']}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: Colors.grey),
                              if (data['note'] != null &&
                                  data['note'].isNotEmpty) ...[
                                Text(
                                  'Note:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  data['note'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      final confirm =
                                          await _showConfirmationDialog(
                                        context: context,
                                        title: 'Confirm Accept',
                                        message:
                                            'Are you sure you want to accept this reschedule?',
                                      );
                                      if (confirm == true) {
                                        _acceptReschedule(doc.id, data);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('Accept',
                                        style:
                                            GoogleFonts.poppins(fontSize: 14)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _showDeclineReasonDialog(doc.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text('Decline',
                                        style:
                                            GoogleFonts.poppins(fontSize: 14)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : ListView(
                    children: [
                      SizedBox(
                        height:
                            MediaQuery.of(context).size.height - kToolbarHeight,
                        child: const Center(
                          child: Text('No reschedule requests found.'),
                        ),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}
