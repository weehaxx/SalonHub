import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/pages/login_page.dart';

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

  final List<String> _predefinedReasons = [
    "Change of plans",
    "Found another appointment",
    "Not feeling well",
    "Unable to attend",
    "Other"
  ];

  Future<void> _submitCancellation() async {
    if (_selectedReason == null && _reasonController.text.isEmpty) {
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
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception("User is not logged in.");
      }

      final reason = _selectedReason == "Other"
          ? _reasonController.text
          : _selectedReason ?? _reasonController.text;

      final appointmentRef = FirebaseFirestore.instance
          .collection('salon')
          .doc(widget.salonId)
          .collection('appointments')
          .doc(widget.appointmentId);

      // Update the appointment status and reason
      await appointmentRef.update({
        'status': 'Canceled',
        'cancelReason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update user cancellation logic
      if (!widget.isPaid) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        final userSnapshot = await userRef.get();

        if (userSnapshot.exists) {
          final userData = userSnapshot.data();
          int cancelCount = userData?['cancelCount'] ?? 0;
          Set<String> canceledSalonIds = Set<String>.from(
            userData?['canceledSalonIds'] ?? [],
          );

          // Add current salonId to the set
          canceledSalonIds.add(widget.salonId);

          // Increment the cancel count
          cancelCount++;

          // Check if the user should be banned
          if (canceledSalonIds.length >= 3) {
            // Ban the user
            await userRef.update({
              'cancelCount': cancelCount,
              'canceledSalonIds': canceledSalonIds.toList(),
              'isBanned': true,
              'bannedAt': FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Your account has been banned due to cancellations in 3 different salons.',
                ),
              ),
            );

            // Log the user out and redirect to login
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Login(),
              ),
            );
            return;
          } else {
            // Update canceled salon IDs and count
            await userRef.update({
              'cancelCount': cancelCount,
              'canceledSalonIds': canceledSalonIds.toList(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Warning: You have canceled in ${canceledSalonIds.length} different salon(s). If you reach 3, you will be banned.',
                ),
              ),
            );
          }
        } else {
          // Initialize user's cancellation data
          await userRef.set({
            'cancelCount': 1,
            'canceledSalonIds': [widget.salonId],
            'isBanned': false,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Warning: If you cancel in 3 different salons, your account will be banned.',
              ),
            ),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment canceled successfully!')),
      );
      Navigator.pop(context);
      Navigator.pop(context);
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

  Future<void> _showConfirmationDialog() async {
    final reason = _selectedReason == "Other"
        ? _reasonController.text
        : _selectedReason ?? "";

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or provide a reason for cancellation'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Cancellation',
          style: GoogleFonts.abel(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to cancel this appointment for the following reason?\n\n"$reason"',
          style: GoogleFonts.abel(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: GoogleFonts.abel(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff355E3B),
            ),
            child: Text(
              'Yes',
              style: GoogleFonts.abel(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _submitCancellation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cancel Appointment',
          style: GoogleFonts.abel(color: Colors.white),
        ),
        backgroundColor: const Color(0xff355E3B),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason for Cancellation',
              style: GoogleFonts.abel(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xff355E3B),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: _predefinedReasons.map((reason) {
                    return ListTile(
                      title: Text(
                        reason,
                        style: GoogleFonts.abel(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
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
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedReason == "Other")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Reason',
                    style: GoogleFonts.abel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff355E3B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      hintText: 'Enter your reason here...',
                      hintStyle: GoogleFonts.abel(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: const Color(0xff355E3B),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff355E3B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit',
                        style: GoogleFonts.abel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
