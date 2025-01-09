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
  String? _selectedReason;

  // List of predefined reasons
  final List<String> _predefinedReasons = [
    "Change of plans",
    "Found another appointment",
    "Not feeling well",
    "Unable to attend",
    "Other"
  ];

  Future<void> _submitCancellation() async {
    if (_selectedReason == null && _reasonController.text.isEmpty) {
      // Ensure at least one reason is provided
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or provide a reason for cancellation'),
        ),
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

      // Combine selected or custom reason
      final reason = _selectedReason == "Other"
          ? _reasonController.text
          : _selectedReason ?? _reasonController.text;

      // Update the status to "Canceled" and log the reason
      await appointmentRef.update({
        'status': 'Canceled',
        'cancelReason': reason,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reason for Cancellation:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Predefined reasons
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predefinedReasons.length,
              itemBuilder: (context, index) {
                final reason = _predefinedReasons[index];
                return ListTile(
                  title: Text(reason),
                  leading: Radio<String>(
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                        if (value != "Other") {
                          _reasonController.clear();
                        }
                      });
                    },
                  ),
                );
              },
            ),

            // TextField for custom reason
            if (_selectedReason == "Other")
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: TextField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your reason here...',
                    labelText: 'Custom Reason',
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCancellation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff355E3B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
