import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/reviews_client.dart';

class ReviewExperiencePage extends StatefulWidget {
  const ReviewExperiencePage({super.key});

  @override
  State<ReviewExperiencePage> createState() => _ReviewExperiencePageState();
}

class _ReviewExperiencePageState extends State<ReviewExperiencePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Unreviewed Appointments',
          style: GoogleFonts.abel(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
        backgroundColor: const Color(0xff355E3B),
        elevation: 0,
      ),
      body: _currentUser == null
          ? const Center(
              child: Text(
                'No user logged in.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('salon').snapshots(),
              builder: (context, salonSnapshot) {
                if (salonSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!salonSnapshot.hasData ||
                    salonSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No salons found.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final salonDocs = salonSnapshot.data!.docs;
                List<Widget> appointmentWidgets = [];

                for (var salonDoc in salonDocs) {
                  String currentSalonId = salonDoc.id;

                  appointmentWidgets.add(
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('salon')
                          .doc(currentSalonId)
                          .collection('appointments')
                          .where('userId', isEqualTo: _currentUser!.uid)
                          .where('status', isEqualTo: 'Done')
                          .where('isReviewed', isEqualTo: false)
                          .snapshots(),
                      builder: (context, appointmentSnapshot) {
                        if (appointmentSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!appointmentSnapshot.hasData ||
                            appointmentSnapshot.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final unreviewedAppointments =
                            appointmentSnapshot.data!.docs;

                        return Column(
                          children: unreviewedAppointments.map((appointment) {
                            String fetchedAppointmentId = appointment.id;
                            List<dynamic> fetchedServices =
                                appointment.get('services');

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(
                                  'Service: ${fetchedServices[0]}',
                                  style: GoogleFonts.abel(
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      'Stylist: ${appointment.get('stylist')}',
                                      style: GoogleFonts.abel(
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Time: ${appointment.get('time')}',
                                      style: GoogleFonts.abel(
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: const Color(0xff355E3B),
                                  size: 20,
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReviewsClient(
                                        salonId: currentSalonId,
                                        appointmentId: fetchedAppointmentId,
                                        services:
                                            List<String>.from(fetchedServices),
                                        isAppointmentReview: true,
                                      ),
                                    ),
                                  );

                                  // Refresh the state after returning
                                  _refreshData();
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView(
                    children: appointmentWidgets,
                  ),
                );
              },
            ),
    );
  }
}
