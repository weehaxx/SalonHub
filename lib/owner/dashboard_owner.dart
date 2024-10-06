import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:salon_hub/owner/accepted_appointments.dart';
import 'package:salon_hub/owner/employees_owner.dart';
import 'package:salon_hub/owner/paid_appointments.dart';
import 'package:salon_hub/owner/pendingappointment.dart';
import 'package:salon_hub/owner/salonInfo_owner.dart';
import 'package:salon_hub/owner/todays_appointment.dart';
import 'package:salon_hub/owner/service_add.dart';
import 'package:salon_hub/pages/login_page.dart';

class DashboardOwner extends StatefulWidget {
  const DashboardOwner({super.key});

  @override
  State<DashboardOwner> createState() => _DashboardOwnerState();
}

class _DashboardOwnerState extends State<DashboardOwner> {
  final User? _user = FirebaseAuth.instance.currentUser;
  int pendingAppointmentsCount = 0;
  int acceptedAppointmentsCount = 0;
  int paidAppointmentsTodayCount =
      0; // Add this variable for paid appointments count
  int todaysAppointmentsCount =
      0; // Add this variable for today's appointments count
  String salonName = "Salon Name";
  String ownerName = "Owner Name";

  @override
  void initState() {
    super.initState();
    fetchAppointmentsCount();
    fetchSalonDetails();
    fetchPaidAppointmentsTodayCount(); // Fetch paid appointments count
    fetchTodaysAppointmentsCount(); // Fetch today's appointments count
  }

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
        });
      }
    } catch (e) {
      print('Error fetching salon details: $e');
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

      setState(() {
        pendingAppointmentsCount = pendingQuerySnapshot.docs.length;
        acceptedAppointmentsCount = acceptedQuerySnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  // Fetch the count of paid appointments for today
  Future<void> fetchPaidAppointmentsTodayCount() async {
    try {
      String todayDate =
          DateFormat('yyyy-MM-dd').format(DateTime.now()); // Get today's date
      final paidQuerySnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .where('status', isEqualTo: 'Accepted')
          .where('isPaid', isEqualTo: true) // Filter for paid appointments
          .where('date',
              isEqualTo: todayDate) // Filter for today's appointments
          .get();

      setState(() {
        paidAppointmentsTodayCount =
            paidQuerySnapshot.docs.length; // Update the count
      });
    } catch (e) {
      print('Error fetching paid appointments for today: $e');
    }
  }

  // Fetch the count of today's appointments (both paid and unpaid)
  Future<void> fetchTodaysAppointmentsCount() async {
    try {
      String todayDate =
          DateFormat('yyyy-MM-dd').format(DateTime.now()); // Get today's date
      final todaysQuerySnapshot = await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .where('date',
              isEqualTo: todayDate) // Filter for today's appointments
          .get();

      setState(() {
        todaysAppointmentsCount =
            todaysQuerySnapshot.docs.length; // Update the count
      });
    } catch (e) {
      print('Error fetching today\'s appointments: $e');
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
    // Refresh the dashboard by re-fetching the appointments count and salon details
    await fetchAppointmentsCount();
    await fetchSalonDetails();
    await fetchPaidAppointmentsTodayCount(); // Refresh the paid appointments count
    await fetchTodaysAppointmentsCount(); // Refresh today's appointments count
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
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/images/logo.png'),
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
              onTap: () {},
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
                    builder: (context) => const SaloninfoOwner(),
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
          physics:
              const AlwaysScrollableScrollPhysics(), // Allow scroll even if content is less than full height
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
                _buildDashboardItem(
                  todaysAppointmentsCount
                      .toString(), // Display today's appointments count
                  "Today's Appointments",
                  const Color(0xff355E3B),
                  const Color(0xFFF9F9F9),
                  const Icon(Icons.calendar_today,
                      size: 40, color: Color(0xFF4A90E2)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TodaysAppointmentsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildDashboardItem(
                  paidAppointmentsTodayCount
                      .toString(), // Display the paid appointments count
                  "Paid Appointments for Today",
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
                          builder: (context) => const Acceptedappointment()),
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
                  '0',
                  "Cancelled",
                  const Color(0xff355E3B),
                  const Color(0xFFF9F9F9),
                  const Icon(Icons.cancel, size: 40, color: Color(0xFFD0021B)),
                  onTap: () {},
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
