import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting date and time

class Reschedule extends StatefulWidget {
  final String appointmentId;
  final String salonId;
  final String stylistName;
  final String service;
  final String initialDate;
  final String initialTime;

  const Reschedule({
    super.key,
    required this.appointmentId,
    required this.salonId,
    required this.stylistName,
    required this.service,
    required this.initialDate,
    required this.initialTime,
  });

  @override
  State<Reschedule> createState() => _RescheduleState();
}

class _RescheduleState extends State<Reschedule> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _noteController = TextEditingController();

  // Method to select a new date
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Method to select a new time
  Future<void> _pickTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  // Method to format the selected date and time
  String _formatDateTime() {
    if (_selectedDate == null || _selectedTime == null) {
      return '${widget.initialDate} at ${widget.initialTime}';
    }
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final formattedTime = _selectedTime!.format(context);
    return '$formattedDate at $formattedTime';
  }

  // Show confirmation dialog before submitting the reschedule
  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reschedule'),
          content: const Text(
              'Are you sure you want to reschedule this appointment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels rescheduling
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms rescheduling
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  // Handle the submission of the reschedule
  Future<void> _submitReschedule() async {
    if (_selectedDate != null && _selectedTime != null) {
      final confirmation = await _showConfirmationDialog();
      if (confirmation == true) {
        try {
          // Format the new date and time
          final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
          final formattedTime = _selectedTime!.format(context);

          // Reference to the specific appointment document in Firestore
          final appointmentRef = FirebaseFirestore.instance
              .collection('salon')
              .doc(widget.salonId)
              .collection('appointments')
              .doc(widget.appointmentId);

          // Update the appointment with the new date, time, note, status, and previous date/time
          await appointmentRef.update({
            'previousDate': widget.initialDate, // Store the previous date
            'previousTime': widget.initialTime, // Store the previous time
            'date': formattedDate,
            'time': formattedTime,
            'note': _noteController.text, // Add the note if any
            'rescheduled': true, // Mark appointment as rescheduled
            'status': 'Rescheduled', // Set the status to "Rescheduled"
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Appointment rescheduled successfully!')),
          );

          Navigator.pop(context, true); // Return true when successful
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reschedule: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a new date and time.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Appointment'),
        backgroundColor: const Color(0xff355E3B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.all(16.0), // Add padding to the main container
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            child: Padding(
              padding:
                  const EdgeInsets.all(20.0), // Add padding inside the card
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service: ${widget.service}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Stylist: ${widget.stylistName}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 30),
                  const Text(
                    'Reschedule Date & Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text(
                          _selectedDate != null
                              ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                              : widget.initialDate,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                  const Divider(height: 30),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : widget.initialTime,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                  const Divider(height: 30),
                  const Text(
                    'Add a Note (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Write a note...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitReschedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff355E3B),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Submit Changes',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
