import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  _LogsPageState createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // Fetch logs from Firestore in descending order of timestamp
  Stream<QuerySnapshot> _getLogsStream() {
    return FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Format the action type and description more clearly
  Widget _buildLogCard(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('yyyy-MM-dd hh:mm a').format(timestamp.toDate())
        : 'No Date';

    String actionType = log['actionType'] ?? 'Unknown Action';
    String description = log['description'] ?? 'No Description';

    IconData logIcon;
    Color iconColor;

    // Customize the icon and color based on the action type
    switch (actionType) {
      case 'Service Added':
        logIcon = Icons.add_circle;
        iconColor = Colors.green;
        break;
      case 'Service Updated':
        logIcon = Icons.edit;
        iconColor = Colors.orange;
        break;
      case 'Service Removed':
        logIcon = Icons.remove_circle;
        iconColor = Colors.red;
        break;
      case 'Stylist Added':
        logIcon = Icons.person_add;
        iconColor = Colors.blue;
        break;
      case 'Stylist Updated':
        logIcon = Icons.person;
        iconColor = Colors.orange;
        break;
      case 'Stylist Removed':
        logIcon = Icons.person_remove;
        iconColor = Colors.red;
        break;
      case 'Salon Info Updated':
        logIcon = Icons.info;
        iconColor = Colors.blueGrey;
        break;
      default:
        logIcon = Icons.history;
        iconColor = Colors.grey;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(logIcon, color: iconColor),
        ),
        title: Text(
          actionType,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs'),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getLogsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading logs'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No logs found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final log =
                  snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildLogCard(log);
            },
          );
        },
      ),
    );
  }
}
