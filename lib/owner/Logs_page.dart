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
  Stream<QuerySnapshot<Map<String, dynamic>>> _getLogsStream() {
    return FirebaseFirestore.instance
        .collection('salon')
        .doc(_user?.uid)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Log an action manually
  Future<void> _logAction(String actionType, String description) async {
    if (_user == null) return;

    final salonDocRef =
        FirebaseFirestore.instance.collection('salon').doc(_user?.uid);

    await salonDocRef.collection('logs').add({
      'actionType': actionType,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Example: Add a service and log the action
  Future<void> _addService(String serviceName, double price) async {
    if (_user == null) return;

    final salonDocRef =
        FirebaseFirestore.instance.collection('salon').doc(_user?.uid);

    // Add the new service to the services collection
    await salonDocRef.collection('services').add({
      'name': serviceName,
      'price': price,
    });

    // Log the action
    await _logAction('Service Added', 'Added a new service: $serviceName');
  }

  // Example: Update salon information and log the action
  Future<void> _updateSalonInfo(Map<String, dynamic> updates) async {
    if (_user == null) return;

    final salonDocRef =
        FirebaseFirestore.instance.collection('salon').doc(_user?.uid);

    await salonDocRef.update(updates);

    // Log the action
    final changes =
        updates.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    await _logAction('Salon Info Updated', 'Updated fields: $changes');
  }

  // Example: Change the salon image and log the action
  Future<void> _changeSalonImage(String newImageUrl) async {
    if (_user == null) return;

    final salonDocRef =
        FirebaseFirestore.instance.collection('salon').doc(_user?.uid);

    await salonDocRef.update({'imageUrl': newImageUrl});

    // Log the action
    await _logAction(
      'Salon Image Changed',
      'Updated the salon image to $newImageUrl',
    );
  }

  // Format and display log entries
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
      case 'Inventory Updated':
        logIcon = Icons.inventory;
        iconColor = Colors.purple;
        break;
      case 'Appointment Scheduled':
        logIcon = Icons.event;
        iconColor = Colors.teal;
        break;
      case 'Salon Image Changed':
        logIcon = Icons.image;
        iconColor = Colors.blueAccent;
        break;
      case 'Payment Method Changed':
        logIcon = Icons.payment;
        iconColor = Colors.greenAccent;
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
          style: const TextStyle(fontWeight: FontWeight.bold),
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
              final log = snapshot.data!.docs[index].data();
              return _buildLogCard(log);
            },
          );
        },
      ),
    );
  }
}
