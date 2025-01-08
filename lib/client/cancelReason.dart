import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CancelReason extends StatefulWidget {
  final String salonId;
  final String appointmentId;
  final bool isPaid;

  const CancelReason({
    super.key,
    required this.salonId,
    required this.appointmentId,
    required this.isPaid,
  });

  @override
  State<CancelReason> createState() => _CancelReasonState();
}

class _CancelReasonState extends State<CancelReason> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitCancellation() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a reason for cancellation')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final appointmentRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('appointments')
          .doc(widget.appointmentId);

      // Update the status to "Canceled" and log the reason
      await appointmentRef.update({
        'status': 'Canceled',
        'cancelReason': _reasonController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment canceled successfully!')),
      );
      Navigator.pop(context); // Close the reason page
      Navigator.pop(context); // Return to the main schedule page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel appointment: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancel Appointment'),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for Cancellation:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your reason here...',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCancellation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff355E3B),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
