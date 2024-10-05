import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_hub/client/downpayment_client.dart';

class BookingscheduleClient extends StatefulWidget {
  const BookingscheduleClient({super.key});

  @override
  State<BookingscheduleClient> createState() => _BookingscheduleClientState();
}

class _BookingscheduleClientState extends State<BookingscheduleClient> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // Method to fetch appointments based on logged-in user
  Future<List<Map<String, dynamic>>> _fetchAppointments() async {
    List<Map<String, dynamic>> appointments = [];

    try {
      // Fetch the salon document ID
      QuerySnapshot salonSnapshot = await _firestore.collection('salon').get();

      // Loop through each salon to find the appointments for the logged-in user
      for (var salonDoc in salonSnapshot.docs) {
        String salonId = salonDoc.id; // Extract salonId here

        // Fetch appointments from the nested appointments collection within the salon document
        QuerySnapshot appointmentSnapshot = await _firestore
            .collection('salon')
            .doc(salonId)
            .collection('appointments')
            .where('userId', isEqualTo: _user?.uid)
            .get();

        for (var appointmentDoc in appointmentSnapshot.docs) {
          var data = appointmentDoc.data() as Map<String, dynamic>;

          // Add each appointment to the list with its details, including the salonId and appointmentId
          appointments.add({
            'appointmentId':
                appointmentDoc.id, // Store the appointment document ID
            'salonId': salonId, // Include salonId in each appointment
            'salonName': salonDoc['salon_name'] ?? 'Unknown Salon',
            'stylistName': data['stylist'] ?? 'Unknown Stylist',
            'service': data['services'][0] ?? 'No service provided',
            'price': data['totalPrice']?.toString() ?? 'N/A',
            'date': data['date'] ?? 'No date provided',
            'time': data['time'] ?? 'No time provided',
            'status': data['status'] ?? 'No status provided',
            'statusColor': _getStatusColor(data['status']),
            'statusTextColor': _getStatusTextColor(data['status']),
            'isAccepted': data['status']?.toLowerCase() == 'accepted',
          });
        }
      }

      // Sort appointments by date and time
      appointments.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date'] + ' ' + a['time']);
        DateTime dateB = DateTime.parse(b['date'] + ' ' + b['time']);
        return dateA.compareTo(dateB);
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }

    return appointments;
  }

  // Helper method to get the color for status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade100;
      case 'accepted':
        return Colors.green.shade100;
      case 'canceled':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  // Helper method to get the text color for status
  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'canceled':
        return Colors.red;
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.black54;
    }
  }

  // Helper method to show appointment dialog
  void _showAppointmentDialog(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            appointment['salonName'] ?? 'Unknown Salon',
            style: GoogleFonts.abel(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Stylist', appointment['stylistName']),
              _buildDetailRow('Service', appointment['service']),
              _buildDetailRow('Price', 'Php ${appointment['price']}'),
              _buildDetailRow('Date & Time',
                  '${appointment['date']} at ${appointment['time']}'),
              _buildDetailRow('Status', appointment['status']),
            ],
          ),
          actions: <Widget>[
            if (appointment['isAccepted'])
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child:
                    Text('Pay', style: GoogleFonts.abel(color: Colors.white)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DownpaymentClient(
                        salonId: appointment['salonId'],
                        totalPrice:
                            double.tryParse(appointment['price'].toString()) ??
                                0.0,
                        appointmentId: appointment[
                            'appointmentId'], // Pass the appointmentId
                      ),
                    ),
                  );
                },
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child:
                    Text('Pay', style: GoogleFonts.abel(color: Colors.white)),
                onPressed: () {
                  _showWaitingMessage(); // Show waiting message if not accepted
                },
              ),
            TextButton(
              child: Text('Close', style: GoogleFonts.abel(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to create rows for details in the dialog
  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title:',
            style: GoogleFonts.abel(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value ?? 'N/A',
              style: GoogleFonts.abel(color: Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Show message to wait for acceptance
  void _showWaitingMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Payment Unavailable'),
          content: const Text(
              'Please wait for the salon to accept your booking before making a payment.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
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
        centerTitle: true,
        title: Text('Booking Schedule',
            style: GoogleFonts.abel(color: Colors.white)),
        backgroundColor: const Color(0xff355E3B),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading appointments'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No appointments found'));
          } else {
            final appointments = snapshot.data!;
            return ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              appointment['salonName'] ?? 'Unknown Salon',
                              style: GoogleFonts.abel(
                                textStyle: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            trailing: Text(
                              appointment['status'] ?? 'No status provided',
                              style: GoogleFonts.abel(
                                color: appointment['statusTextColor'] ??
                                    Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                              'Stylist', appointment['stylistName']),
                          _buildDetailRow('Service', appointment['service']),
                          _buildDetailRow(
                              'Price', 'Php ${appointment['price']}'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                appointment['date'] ?? 'No date provided',
                                style: GoogleFonts.abel(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.access_time_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(
                                appointment['time'] ?? 'No time provided',
                                style: GoogleFonts.abel(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: appointment['isAccepted']
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DownpaymentClient(
                                                salonId: appointment['salonId'],
                                                totalPrice: double.tryParse(
                                                        appointment['price']
                                                            .toString()) ??
                                                    0.0,
                                                appointmentId: appointment[
                                                    'appointmentId'], // Pass appointmentId here
                                              ),
                                            ),
                                          );
                                        }
                                      : null, // Enable only if accepted
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appointment['isAccepted']
                                        ? Colors.green
                                        : Colors.grey,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Pay',
                                    style: GoogleFonts.abel(
                                      textStyle: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: appointment['isAccepted']
                                      ? () {
                                          // Handle reschedule logic here
                                        }
                                      : null, // Enable only if accepted
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appointment['isAccepted']
                                        ? Colors.orange
                                        : Colors.grey,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Reschedule',
                                    style: GoogleFonts.abel(
                                      textStyle: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // Handle cancel logic here
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.abel(
                                      textStyle: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
