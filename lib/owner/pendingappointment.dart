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

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Decline Appointment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please select a reason for declining this appointment:',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedReason,
                items: predefinedReasons
                    .map((reason) => DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select a reason',
                ),
              ),
            ],
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Decline',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              onPressed: () {
                if (selectedReason != null && selectedReason!.isNotEmpty) {
                  _declineAppointmentWithReason(
                      _user!.uid, appointmentId, selectedReason!);
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
            ),
          ],
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
                              'Services: ${appointment['services']?.join(', ') ?? 'No service'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Main Category (Male or Female)
                            Text(
                              'Category: ${appointment['main_category'] ?? 'No category selected'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Date, Time, and Stylist
                            Text(
                              '${appointment['date']} at ${appointment['time']} with ${appointment['stylist']}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Total Price: Php ${appointment['totalPrice']?.toString() ?? 'No Price'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            // User Name
                            Text(
                              'Set by: $userName',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Accept and Decline Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _acceptAppointment(
                                        _user!.uid, appointmentId);
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
                                    _showDeclineReasonDialog(appointmentId);
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
      ),
    );
  }
}
