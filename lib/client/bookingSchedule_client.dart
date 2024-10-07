import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_hub/client/downpayment_client.dart';
import 'package:salon_hub/client/reschedule.dart';
import 'package:intl/intl.dart';

class BookingscheduleClient extends StatefulWidget {
  const BookingscheduleClient({super.key});

  @override
  State<BookingscheduleClient> createState() => _BookingscheduleClientState();
}

class _BookingscheduleClientState extends State<BookingscheduleClient> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  // List to store appointments
  List<Map<String, dynamic>> _appointments = [];

  // Method to fetch appointments based on logged-in user
  Future<void> _fetchAppointments() async {
    List<Map<String, dynamic>> appointments = [];

    try {
      QuerySnapshot salonSnapshot = await _firestore.collection('salon').get();

      for (var salonDoc in salonSnapshot.docs) {
        String salonId = salonDoc.id;

        QuerySnapshot appointmentSnapshot = await _firestore
            .collection('salon')
            .doc(salonId)
            .collection('appointments')
            .where('userId', isEqualTo: _user?.uid)
            .get();

        for (var appointmentDoc in appointmentSnapshot.docs) {
          var data = appointmentDoc.data() as Map<String, dynamic>;

          appointments.add({
            'appointmentId': appointmentDoc.id,
            'salonId': salonId,
            'salonName': salonDoc['salon_name'] ?? 'Unknown Salon',
            'stylistName': data['stylist'] ?? 'Unknown Stylist',
            'service': data['services'][0] ?? 'No service provided',
            'price': data['totalPrice']?.toString() ?? 'N/A',
            'date': data['date'] ?? 'No date provided',
            'time': data['time'] ?? 'No time provided',
            'status': data['status'] ?? 'No status provided',
            'isPaid': data['isPaid'] ?? false,
            'rescheduled': data['rescheduled'] ?? false,
            'statusColor': _getStatusColor(data['status']),
            'statusTextColor': _getStatusTextColor(data['status']),
            'isAccepted': data['status']?.toLowerCase() == 'accepted',
          });
        }
      }

      appointments.sort((a, b) {
        DateTime dateTimeA = _getAppointmentDateTime(a['date'], a['time']);
        DateTime dateTimeB = _getAppointmentDateTime(b['date'], b['time']);
        return dateTimeB.compareTo(dateTimeA);
      });

      setState(() {
        _appointments = appointments;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  // Helper method to parse and combine the date and time into a DateTime object
  DateTime _getAppointmentDateTime(String date, String time) {
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat.jm();
      final parsedDate = dateFormat.parse(date);
      final parsedTime = timeFormat.parse(time);
      return DateTime(parsedDate.year, parsedDate.month, parsedDate.day,
          parsedTime.hour, parsedTime.minute);
    } catch (e) {
      print('Error parsing date and time: $e');
      return DateTime.now();
    }
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

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
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
      body: RefreshIndicator(
        onRefresh: _fetchAppointments,
        child: _appointments.isEmpty
            ? const Center(child: Text('No appointments found'))
            : ListView.builder(
                itemCount: _appointments.length,
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  bool isCanceled = appointment['status'] == 'Canceled';
                  bool isPending = appointment['status'] == 'Pending';
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              trailing: Text(
                                appointment['rescheduled']
                                    ? '${appointment['status']} (Rescheduled)'
                                    : appointment['status'] ??
                                        'No status provided',
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed:
                                        isCanceled || appointment['isPaid']
                                            ? null
                                            : appointment['isAccepted']
                                                ? () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            DownpaymentClient(
                                                          salonId: appointment[
                                                              'salonId'],
                                                          totalPrice: double.tryParse(
                                                                  appointment[
                                                                          'price']
                                                                      .toString()) ??
                                                              0.0,
                                                          appointmentId:
                                                              appointment[
                                                                  'appointmentId'],
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isCanceled || appointment['isPaid']
                                              ? Colors.grey
                                              : appointment['isAccepted']
                                                  ? Colors.green
                                                  : Colors.grey,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      appointment['isPaid'] ? 'Paid' : 'Pay',
                                      style: GoogleFonts.abel(
                                        textStyle: const TextStyle(
                                            color: Colors.white, fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: isCanceled ||
                                            isPending ||
                                            appointment['rescheduled']
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await _showRescheduleConfirmationDialog();
                                            if (confirmed == true) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      Reschedule(
                                                    appointmentId: appointment[
                                                        'appointmentId'],
                                                    salonId:
                                                        appointment['salonId'],
                                                    stylistName: appointment[
                                                        'stylistName'],
                                                    service:
                                                        appointment['service'],
                                                    initialDate:
                                                        appointment['date'],
                                                    initialTime:
                                                        appointment['time'],
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isCanceled ||
                                              isPending ||
                                              appointment['rescheduled']
                                          ? Colors.grey
                                          : Colors.orange,
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
                                    onPressed: isCanceled
                                        ? null
                                        : () async {
                                            final confirmed =
                                                await _showCancellationConfirmationDialog();
                                            if (confirmed == true) {
                                              _cancelAppointment(
                                                appointment['salonId'],
                                                appointment['appointmentId'],
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          isCanceled ? Colors.grey : Colors.red,
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
              ),
      ),
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

  // Show confirmation dialog for rescheduling
  Future<bool?> _showRescheduleConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
            'You can only reschedule once. Are you sure you want to reschedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog for cancellation
  Future<bool?> _showCancellationConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text(
            'Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  // Method to cancel the appointment
  Future<void> _cancelAppointment(String salonId, String appointmentId) async {
    try {
      final appointmentRef = _firestore
          .collection('salon')
          .doc(salonId)
          .collection('appointments')
          .doc(appointmentId);

      await appointmentRef.update({'status': 'Canceled'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment canceled successfully!')),
      );

      _fetchAppointments(); // Refresh the appointments list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    }
  }
}
