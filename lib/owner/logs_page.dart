import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Logs',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(color: Colors.black),
          ),
        ),
        backgroundColor: const Color(0xffFaF9F6),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: user == null
          ? Center(
              child: Text(
                'No user logged in.',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('logs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading logs',
                        style: GoogleFonts.poppins(
                            fontSize: 18, color: Colors.red)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = snapshot.data?.docs ?? [];

                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      'No logs available.',
                      style: GoogleFonts.poppins(
                          fontSize: 18, color: Colors.black),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final details =
                        log['details'] ?? 'Log details not available';
                    final timestamp = log['timestamp'] != null
                        ? (log['timestamp'] as Timestamp).toDate().toString()
                        : 'No Date';

                    return ListTile(
                      title: Text(
                        details,
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.black),
                      ),
                      subtitle: Text(
                        'Date: $timestamp',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey),
                      ),
                      leading: const Icon(Icons.info, color: Colors.green),
                    );
                  },
                );
              },
            ),
    );
  }
}
