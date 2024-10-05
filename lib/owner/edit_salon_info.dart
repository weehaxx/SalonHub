import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // <-- Import this for DateFormat

class EditSalonInfo extends StatefulWidget {
  final Map<String, dynamic> salonData;

  const EditSalonInfo({super.key, required this.salonData});

  @override
  State<EditSalonInfo> createState() => _EditSalonInfoState();
}

class _EditSalonInfoState extends State<EditSalonInfo> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _salonNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _addressController;
  late TimeOfDay _openTime;
  late TimeOfDay _closeTime;

  @override
  void initState() {
    super.initState();
    _salonNameController =
        TextEditingController(text: widget.salonData['salon_name']);
    _ownerNameController =
        TextEditingController(text: widget.salonData['owner_name']);
    _addressController =
        TextEditingController(text: widget.salonData['address']);

    // Use the current time as default if time data is not available
    _openTime = widget.salonData['open_time'] != null
        ? _convertStringToTimeOfDay(widget.salonData['open_time'])
        : TimeOfDay.now();
    _closeTime = widget.salonData['close_time'] != null
        ? _convertStringToTimeOfDay(widget.salonData['close_time'])
        : TimeOfDay.now();
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Update the Firestore document
          QuerySnapshot salonSnapshot = await FirebaseFirestore.instance
              .collection('salon')
              .where('owner_uid', isEqualTo: currentUser.uid)
              .get();

          if (salonSnapshot.docs.isNotEmpty) {
            String docId = salonSnapshot.docs.first.id;
            await FirebaseFirestore.instance
                .collection('salon')
                .doc(docId)
                .update({
              'salon_name': _salonNameController.text,
              'owner_name': _ownerNameController.text,
              'address': _addressController.text,
              'open_time': _openTime.format(context),
              'close_time': _closeTime.format(context),
            });

            Navigator.pop(context); // Go back to the previous screen
          }
        }
      } catch (e) {
        print("Error updating salon information: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Salon Information'),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildEditCard(
                _salonNameController,
                'Salon Name',
                Icons.store,
              ),
              const SizedBox(height: 20),
              _buildEditCard(
                _ownerNameController,
                'Owner Name',
                Icons.person,
              ),
              const SizedBox(height: 20),
              _buildEditCard(
                _addressController,
                'Address',
                Icons.location_on,
              ),
              const SizedBox(height: 20),
              _buildTimePickerCard(
                'Open Time',
                _openTime,
                Icons.access_time,
                (TimeOfDay selectedTime) {
                  setState(() {
                    _openTime = selectedTime;
                  });
                },
              ),
              const SizedBox(height: 20),
              _buildTimePickerCard(
                'Close Time',
                _closeTime,
                Icons.access_time_filled,
                (TimeOfDay selectedTime) {
                  setState(() {
                    _closeTime = selectedTime;
                  });
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 32, 124, 46),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build individual cards for editing text fields
  Widget _buildEditCard(
    TextEditingController controller,
    String labelText,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Inner padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xff355E3B),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 15), // Spacing between icon and text
                Text(
                  labelText,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(
                height: 10), // Spacing between the label and the input
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $labelText';
                }
                return null;
              },
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build a card for time picker
  Widget _buildTimePickerCard(
    String labelText,
    TimeOfDay time,
    IconData icon,
    ValueChanged<TimeOfDay> onTimePicked,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xff355E3B),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 15),
                Text(
                  labelText,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (pickedTime != null) {
                  onTimePicked(pickedTime);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: Text(
                  time.format(context),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Convert string time like '10:00' (24-hour format) into TimeOfDay
  TimeOfDay _convertStringToTimeOfDay(String time) {
    // Use the 24-hour format to avoid issues with AM/PM
    final format = DateFormat.Hm(); // 'HH:mm' for 24-hour format
    final dt = format.parse(time); // Parse time string
    return TimeOfDay.fromDateTime(dt);
  }
}
