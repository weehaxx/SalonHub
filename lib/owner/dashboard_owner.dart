import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:salon_hub/owner/ChangePaymentMethodPage.dart';
import 'package:salon_hub/owner/Logs_page.dart';
import 'package:salon_hub/owner/Reviews_Page.dart';
import 'package:salon_hub/owner/Salon_Images.dart';
import 'package:salon_hub/owner/accepted_appointments.dart';
import 'package:salon_hub/owner/declined_appointments_page.dart';
import 'package:salon_hub/owner/employees_owner.dart';
import 'package:salon_hub/owner/paid_appointments.dart';
import 'package:salon_hub/owner/pendingappointment.dart';
import 'package:salon_hub/owner/reschedule_page.dart';
import 'package:salon_hub/owner/cancellation_page.dart';
import 'package:salon_hub/owner/salonInfo_owner.dart';
import 'package:salon_hub/owner/service_add.dart';
import 'package:salon_hub/pages/login_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DashboardOwner extends StatefulWidget {
  const DashboardOwner({super.key});

  @override
  State<DashboardOwner> createState() => _DashboardOwnerState();
}

class _DashboardOwnerState extends State<DashboardOwner> {
  final User? _user = FirebaseAuth.instance.currentUser;
  int pendingAppointmentsCount = 0;
  int acceptedAppointmentsCount = 0;
  int paidAppointmentsTodayCount = 0;
  int rescheduleCount = 0;
  int cancellationCount = 0;
  int declinedCount = 0;
  String salonName = "Salon Name";
  String ownerName = "Owner Name";
  String status = "Open"; // Initialize salon status

  @override
  void initState() {
    super.initState();
    fetchAppointmentsCount();
    _initializeNotifications();
    fetchSalonDetails();
    fetchPaidAppointmentsTodayCount();
    fetchRescheduleCount();
    fetchCancellationCount();
    fetchDeclinedCount();
  }

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Future<void> fetchSalonDetails() async {
    try {
      final salonDoc = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .get();

      if (salonDoc.exists) {
        setState(() {
          salonName = salonDoc.data()?['salon_name'] ?? 'Salon Name';
          ownerName = salonDoc.data()?['owner_name'] ?? 'Owner Name';
          status = salonDoc.data()?['status'] ?? 'Open'; // Fetch status field
        });
      }
    } catch (e) {
      print('Error fetching salon details: $e');
    }
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Replace with your app icon
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'declined_channel', // Unique ID for the channel
      'Declined Notifications', // Name of the channel
      channelDescription: 'Notifications for declined bookings',
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

  Future<void> updateSalonStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .update({'status': newStatus}); // Update the status field

      setState(() {
        status = newStatus;
      });

      // Log the status change
      createLog('Status Update', 'Salon status changed to $newStatus');
    } catch (e) {
      print('Error updating salon status: $e');
    }
  }

  Future<void> fetchAppointmentsCount() async {
    try {
      final pendingQuerySnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .where('status', isEqualTo: 'Pending')
          .get();

      final acceptedQuerySnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .where('status', isEqualTo: 'Accepted')
          .get();

      if (pendingQuerySnapshot.docs.length > pendingAppointmentsCount) {
        _showNotification(
          'New Appointment Request',
          'A new appointment request has been made.',
        );
      }

      setState(() {
        pendingAppointmentsCount = pendingQuerySnapshot.docs.length;
        acceptedAppointmentsCount = acceptedQuerySnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  Future<void> fetchPaidAppointmentsTodayCount() async {
    try {
      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final paidQuerySnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .where('status', isEqualTo: 'Accepted')
          .where('isPaid', isEqualTo: true)
          .where('date', isEqualTo: todayDate)
          .get();

      if (paidQuerySnapshot.docs.length > paidAppointmentsTodayCount) {
        _showNotification(
          "Today's Appointments",
          "You have new paid appointments for today.",
        );
      }

      setState(() {
        paidAppointmentsTodayCount = paidQuerySnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching paid appointments for today: $e');
    }
  }

  Future<void> fetchRescheduleCount() async {
    try {
      final rescheduleQuerySnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .where('status', isEqualTo: 'Rescheduled')
          .get();

      if (rescheduleQuerySnapshot.docs.length > rescheduleCount) {
        _showNotification(
          'Reschedule Request',
          'A client has requested to reschedule an appointment.',
        );
      }

      setState(() {
        rescheduleCount = rescheduleQuerySnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching reschedule appointments: $e');
    }
  }

  Future<void> fetchDeclinedCount() async {
    try {
      // Log the UID for debugging
      print('Fetching declined appointments for UID: ${_user?.uid}');

      // Query Firestore for declined appointments
      final declinedQuerySnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .where('status', isEqualTo: 'Declined')
          .get();

      // Debug log the count fetched
      print(
          'Fetched Declined Appointments Count: ${declinedQuerySnapshot.docs.length}');

      // Update the declined count in the UI
      setState(() {
        declinedCount = declinedQuerySnapshot.docs.length;
      });

      // Check if there are new declined appointments and show a notification
      if (declinedQuerySnapshot.docs.length > declinedCount) {
        _showNotification(
          'Declined Booking Update',
          'A booking was recently declined.',
        );
      }
    } catch (e) {
      print('Error fetching declined appointments: $e');
    }
  }

  Future<void> fetchCancellationCount() async {
    try {
      final cancellationQuerySnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .where('status', isEqualTo: 'Canceled')
          .get();

      if (cancellationQuerySnapshot.docs.length > cancellationCount) {
        _showNotification(
          'Cancellation Request',
          'A client has canceled their appointment.',
        );
      }

      setState(() {
        cancellationCount = cancellationQuerySnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching cancellation appointments: $e');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    await fetchAppointmentsCount();
    await fetchSalonDetails();
    await fetchPaidAppointmentsTodayCount();
    await fetchRescheduleCount();
    await fetchCancellationCount();
    await fetchDeclinedCount();
  }

  Future<void> createLog(String actionType, String description) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('logs')
          .add({
        'actionType': actionType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Log created: $actionType - $description');
    } catch (e) {
      print('Error creating log: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFaF9F6),
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(
          'DASHBOARD',
          style: GoogleFonts.abel(
            textStyle: const TextStyle(color: Colors.black),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications,
              color: Color(0xff355E3B),
            ),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xff355E3B),
              ),
              child: Column(
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('salon')
                        .doc(_user?.uid)
                        .snapshots(), // Listen for real-time updates
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(); // Show a loading indicator while fetching the data
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey,
                          child:
                              Icon(Icons.image, size: 40, color: Colors.white),
                        ); // Show a placeholder image if there's an error or no data
                      }

                      final salonImage = snapshot.data?.get('image_url') ?? '';

                      if (salonImage.isEmpty) {
                        return const CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey,
                          child:
                              Icon(Icons.image, size: 40, color: Colors.white),
                        ); // Placeholder if no image URL is provided
                      }

                      return CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(salonImage),
                      ); // Display the fetched salon image
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ownerName,
                    style: GoogleFonts.abel(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.green[700]),
              title: Text(
                'Dashboard',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardOwner(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info, color: Colors.green[700]),
              title: Text(
                'Salon Information',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SaloninfoOwner(), // Match the correct widget name
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.image, color: Colors.green[700]),
              title: Text(
                'Salon Images',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const SalonImages(), // Navigate to Salon Images
                  ),
                );
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.payment, color: Colors.green[700]), // New icon
              title: Text(
                'Change Payment Method', // New item label
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChangePaymentMethodPage(), // New page navigation
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.content_cut, color: Colors.green[700]),
              title: Text(
                'Services',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddServicePage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.green[700]),
              title: Text(
                'Stylists',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeesOwner(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.reviews, color: Colors.green[700]),
              title: Text(
                'Reviews',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReviewsPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.green[700]),
              title: Text(
                'Logs',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LogsPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red[700]),
              title: Text(
                'Logout',
                style: GoogleFonts.abel(
                  textStyle: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salonName,
                  style: GoogleFonts.abel(
                    textStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Status Container for Salon Open/Closed
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color:
                        status == "Open" ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Salon is $status",
                        style: GoogleFonts.montserrat(
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: status == "Open" ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      Switch(
                        value: status == "Open",
                        onChanged: (value) {
                          String newStatus = value ? "Open" : "Closed";
                          updateSalonStatus(newStatus);
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildDashboardItem(
                  paidAppointmentsTodayCount.toString(),
                  "Today's Appointment",
                  const Color(0xff355E3B),
                  const Color(0xFFF9F9F9),
                  const Icon(Icons.money, size: 40, color: Colors.green),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaidAppointmentsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildDashboardItem(
                  acceptedAppointmentsCount.toString(),
                  "Confirmed",
                  const Color(0xff355E3B),
                  const Color(0xFFF9F9F9),
                  const Icon(Icons.check_circle,
                      size: 40, color: Color(0xFF50E3C2)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AcceptedAppointmentsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildDashboardItem(
                  pendingAppointmentsCount.toString(),
                  "Requests",
                  const Color(0xff355E3B),
                  const Color(0xFFF9F9F9),
                  const Icon(Icons.pending, size: 40, color: Color(0xFFF5A623)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Pendingappointment(),
                      ),
                    ).then((shouldRefresh) {
                      if (shouldRefresh == true) {
                        fetchAppointmentsCount();
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildDashboardItem(
                  rescheduleCount.toString(),
                  "Reschedule",
                  const Color(0xff355E3B),
                  const Color(0xFFF9F9F9),
                  const Icon(Icons.schedule,
                      size: 40, color: Color(0xFF1E90FF)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReschedulePage(),
                      ),
                    ).then((shouldRefresh) {
                      if (shouldRefresh == true) {
                        fetchRescheduleCount();
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildDashboardItem(
                  cancellationCount.toString(),
                  "Cancelled",
                  const Color(0xff355E3B),
                  const Color(0xFFF9F9F9),
                  const Icon(Icons.cancel, size: 40, color: Color(0xFFD0021B)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CancellationPage(),
                      ),
                    ).then((shouldRefresh) {
                      if (shouldRefresh == true) {
                        fetchCancellationCount();
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                _buildDashboardItem(
                  declinedCount.toString(),
                  "Declined Apppointments",
                  const Color(0xff355E3B),
                  const Color(0xFFF9F9F9),
                  const Icon(Icons.cancel,
                      size: 40, color: Color.fromARGB(255, 182, 176, 177)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeclinedAppointmentsPage(),
                      ),
                    ).then((shouldRefresh) {
                      if (shouldRefresh == true) {
                        fetchDeclinedCount();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
      String count, String label, Color textColor, Color bgColor, Icon icon,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    textStyle: TextStyle(
                      fontSize: 12,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            icon,
          ],
        ),
      ),
    );
  }
}
