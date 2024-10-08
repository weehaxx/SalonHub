import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_hub/client/reviews_client.dart';

class ReviewExperiencePage extends StatefulWidget {
  const ReviewExperiencePage({super.key});

  @override
  State<ReviewExperiencePage> createState() => _ReviewExperiencePageState();
}

class _ReviewExperiencePageState extends State<ReviewExperiencePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Appointments'),
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
                  String salonId = salonDoc.id;

                  appointmentWidgets.add(
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('salon')
                          .doc(salonId)
                          .collection('appointments')
                          .where('userId', isEqualTo: _currentUser.uid)
                          .where('status', isEqualTo: 'Done')
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

                        final completedAppointments =
                            appointmentSnapshot.data!.docs;

                        return Column(
                          children: completedAppointments.map((appointment) {
                            String appointmentId = appointment.id;
                            List<dynamic> services =
                                appointment.get('services');

                            return ListTile(
                              title: Text(
                                  'Service: ${services[0]}'), // Assuming services is a list of strings
                              subtitle: Text(
                                  'Stylist: ${appointment.get('stylist')}\nTime: ${appointment.get('time')}'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                // Navigate to the ReviewsClient page with the correct data
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewsClient(
                                      salonId: salonId,
                                      appointmentId: appointmentId,
                                      services: List<String>.from(services),
                                    ),
                                  ),
                                );

                                // Refresh the state after returning
                                setState(() {});
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  );
                }

                return ListView(
                  children: appointmentWidgets,
                );
              },
            ),
    );
  }
}
