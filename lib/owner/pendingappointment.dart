import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:salon_hub/owner/banned_page.dart';

class Pendingappointment extends StatefulWidget {
  const Pendingappointment({super.key});

  @override
  State<Pendingappointment> createState() => _PendingappointmentState();
}

class _PendingappointmentState extends State<Pendingappointment> {
  final User? _user = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> _pendingAppointmentsStream;
  int missedAppointmentCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _pendingAppointmentsStream = _getPendingAppointmentsStream();
    _checkForMissedAppointments();
  }

  bool _isProcessing = false;

  // Fetch pending appointments stream
  Stream<QuerySnapshot> _getPendingAppointmentsStream() {
    final stream = FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('appointments')
        .where('status', isEqualTo: 'Pending')
        .snapshots();

    // Add a side-effect listener to process appointments
    stream.listen((snapshot) {
      _processPendingAppointments(
          snapshot); // Process appointments in real time
    });

    return stream; // Return the original stream
  }

  Future<void> _processPendingAppointments(QuerySnapshot snapshot) async {
    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      try {
        final date = data['date']; // Example: "2025-01-10"
        final time = data['time']; // Example: "5:00 PM"
        final scheduledTime =
            DateFormat('yyyy-MM-dd h:mm a').parse('$date $time');

        if (now.isAfter(scheduledTime.subtract(const Duration(hours: 3)))) {
          // Check if already processed
          if (data['status'] == 'Pending') {
            // Auto-decline overdue appointment
            await FirebaseFirestore.instance
                .collection('salon')
                .doc(_user?.uid)
                .collection('appointments')
                .doc(doc.id)
                .update({
              'status': 'Canceled',
              'declineReason': 'Failure to accept or decline appointment',
            });

            // Increment missed count
            missedAppointmentCount += 1;

            // Handle banning logic
            if (missedAppointmentCount >= 3) {
              await _handleSalonBan();
              break;
            }
          }
        }
      } catch (e) {
        print('Error processing appointment ${doc.id}: $e');
      }
    }
  }

  Future<void> _handleSalonBan() async {
    final salonDocRef =
        FirebaseFirestore.instance.collection('salon').doc(_user?.uid);

    await salonDocRef.update({
      'isBanned': true,
      'banEndDate':
          DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      'missedAppointmentCount': 0, // Reset missed count
    });

    if (mounted) {
      _showBanPromptDialog();
    }
  }

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _checkForMissedAppointments() async {
    final now = DateTime.now();
    final salonDocRef =
        FirebaseFirestore.instance.collection('salon').doc(_user?.uid);

    int missedCount = 0;

    // Fetch pending appointments
    final pendingAppointments = await FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('appointments')
        .where('status', isEqualTo: 'Pending')
        .get();

    for (var doc in pendingAppointments.docs) {
      final data = doc.data() as Map<String, dynamic>;

      try {
        final date = data['date']; // Example: "2025-01-10"
        final time = data['time']; // Example: "5:00 PM"
        final scheduledTime =
            DateFormat('yyyy-MM-dd h:mm a').parse('$date $time');

        // Check if the appointment is overdue (within 3 hours of the scheduled time)
        if (now.isAfter(scheduledTime.subtract(const Duration(hours: 3)))) {
          // Auto-decline the appointment
          await FirebaseFirestore.instance
              .collection('salon')
              .doc(_user?.uid)
              .collection('appointments')
              .doc(doc.id)
              .update({
            'status': 'Canceled',
            'declineReason': 'Failure to accept or decline appointment',
          });

          missedCount += 1; // Increment missed count
        }
      } catch (e) {
        print('Error parsing date and time for appointment ${doc.id}: $e');
      }
    }

    // Fetch the current missed count from the salon document
    final salonDoc = await salonDocRef.get();
    int currentMissedCount = salonDoc.data()?['missedAppointmentCount'] ?? 0;

    // Update the missed count
    currentMissedCount += missedCount;

    if (currentMissedCount >= 3) {
      // Ban the account if 3 missed appointments occurred
      await salonDocRef.update({
        'isBanned': true,
        'banEndDate':
            DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'missedAppointmentCount': 0, // Reset missed count after banning
      });

      if (mounted) {
        // Show prompt dialog before signing out
        _showBanPromptDialog();
      }
    } else {
      // Save the updated missed count if not banned
      await salonDocRef.update({'missedAppointmentCount': currentMissedCount});
    }
  }

  // Method to show the confirmation dialog for accepting a booking
  Future<void> _showAcceptConfirmationDialog(
      String salonId, String appointmentId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Booking',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to accept this booking?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text(
                'Confirm',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop(true); // Return true
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _acceptAppointment(salonId, appointmentId);
    }
  }

  void _showBanPromptDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent closing the dialog by tapping outside
      builder: (BuildContext context) {
        return PopScope(
          canPop:
              false, // Prevent the dialog from being dismissed by back button
          child: AlertDialog(
            title: Text(
              'Account Banned',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Your account has been banned for 3 days due to failure to respond to appointments within the required time. You will now be logged out.',
              style: GoogleFonts.poppins(),
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onPressed: () async {
                  Navigator.of(context).pop(); // Close the dialog
                  await FirebaseAuth.instance.signOut(); // Sign out the user
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const BannedPage(), // Redirect to Banned Page
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'booking_channel', // Unique ID for the channel
      'Booking Notifications', // Name of the channel
      channelDescription: 'Notifications for client bookings',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title, // Title of the notification
      body, // Body of the notification
      notificationDetails,
    );
  }

  Future<void> _refreshPendingAppointments() async {
    setState(() {
      _pendingAppointmentsStream = _getPendingAppointmentsStream();
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

  Future<void> _declineAppointmentWithReason(
      String salonId, String appointmentId, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonId)
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'Canceled',
        'declineReason': reason,
        'updatedAt': FieldValue.serverTimestamp(), // Track updates
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment declined successfully.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      print('Error declining appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to decline appointment.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeclineReasonDialog(String appointmentId) async {
    String? selectedReason;
    final List<String> predefinedReasons = [
      'Fully booked',
      'Staff unavailable',
      'Service not available',
      'Other reasons',
    ];

    TextEditingController customReasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Decline Appointment',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select a reason for declining the appointment:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      items: predefinedReasons
                          .map(
                            (reason) => DropdownMenuItem<String>(
                              value: reason,
                              child: Text(
                                reason,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedReason = value;
                          if (value != 'Other reasons') {
                            customReasonController.clear();
                          }
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Reason',
                        labelStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (selectedReason == 'Other reasons') ...[
                      const SizedBox(height: 10),
                      Text(
                        'Provide details:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextField(
                        controller: customReasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter reason...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (selectedReason != null &&
                        (selectedReason != 'Other reasons' ||
                            customReasonController.text.isNotEmpty)) {
                      final reason = selectedReason == 'Other reasons'
                          ? customReasonController.text
                          : selectedReason!;
                      _declineAppointmentWithReason(
                          _user!.uid, appointmentId, reason); // Pass the reason
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select or enter a reason to decline.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Decline',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept appointment.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      body: RefreshIndicator(
        onRefresh: _refreshPendingAppointments,
        child: StreamBuilder<QuerySnapshot>(
          stream: _pendingAppointmentsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height - kToolbarHeight,
                    child: const Center(
                      child: Text(
                        'No pending appointments found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
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
                final appointmentId = appointmentDoc.id;
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
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
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
                            // Header: Service Name and Category
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Services: ${appointment['services']?.join(', ') ?? 'No service'}',
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
                                    appointment['main_category'] ??
                                        'No category',
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

                            // Appointment Details
                            Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${appointment['date']} at ${appointment['time']}',
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
                                const Icon(Icons.person,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Stylist: ${appointment['stylist'] ?? 'No stylist'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
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
                                    'Total Price: Php ${appointment['totalPrice']?.toString() ?? 'No Price'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.account_circle,
                                    size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Set by: $userName',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, color: Colors.grey),

                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _showAcceptConfirmationDialog(
                                        _user!.uid, appointmentId);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check,
                                      size: 20, color: Colors.white),
                                  label: Text(
                                    'Accept',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _showDeclineReasonDialog(appointmentId);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.cancel,
                                      size: 20, color: Colors.white),
                                  label: Text(
                                    'Decline',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
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
      ),
    );
  }
}
