import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReschedulePage extends StatefulWidget {
  const ReschedulePage({Key? key}) : super(key: key);

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

  // Decline a reschedule request and remove the appointment
  Future<void> _declineReschedule(String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(_user?.uid)
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Reschedule request declined and appointment removed.')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reschedule Requests',
          style: TextStyle(color: Colors.black),
        ),
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

                      // Extracting the services and price information
                      List<dynamic> services = data['services'] ?? [];
                      String formattedServices = services.join(', ');
                      String price = data['totalPrice'].toString();

                      return ListTile(
                        title: Text(
                          'Client: ${data['userName']}',
                          style: GoogleFonts.abel(),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Services: $formattedServices',
                              style: GoogleFonts.abel(),
                            ),
                            Text(
                              'Price: \$${price}',
                              style: GoogleFonts.abel(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Previous Date: ${data['previousDate']}',
                              style: GoogleFonts.abel(),
                            ),
                            Text(
                              'Previous Time: ${data['previousTime']}',
                              style: GoogleFonts.abel(),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'New Requested Date: ${data['date']}',
                              style: GoogleFonts.abel(),
                            ),
                            Text(
                              'New Requested Time: ${data['time']}',
                              style: GoogleFonts.abel(),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                _acceptReschedule(doc.id, data);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                _declineReschedule(doc.id);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : ListView(
                    // Provides a scrollable area even when no data is available
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
