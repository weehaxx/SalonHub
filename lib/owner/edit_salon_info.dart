import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EditSalonInfo extends StatefulWidget {
  const EditSalonInfo({super.key});

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
  String? salonDocId;

  @override
  void initState() {
    super.initState();
    _salonNameController = TextEditingController();
    _ownerNameController = TextEditingController();
    _addressController = TextEditingController();
    _openTime = TimeOfDay.now();
    _closeTime = TimeOfDay.now();
    _getSalonDocId();
  }

  Future<void> _getSalonDocId() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final salonSnapshot = await FirebaseFirestore.instance
            .collection('salon')
            .where('owner_uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();

        if (salonSnapshot.docs.isNotEmpty) {
          setState(() {
            salonDocId = salonSnapshot.docs.first.id;
          });
          _fetchSalonData();
        }
      }
    } catch (e) {
      print('Error fetching salon document ID: $e');
    }
  }

  void _fetchSalonData() {
    if (salonDocId != null) {
      FirebaseFirestore.instance
          .collection('salon')
          .doc(salonDocId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _salonNameController.text = snapshot['salon_name'] ?? '';
            _ownerNameController.text = snapshot['owner_name'] ?? '';
            _addressController.text = snapshot['address'] ?? '';
            _openTime = snapshot['open_time'] != null
                ? _convertStringToTimeOfDay(snapshot['open_time'])
                : TimeOfDay.now();
            _closeTime = snapshot['close_time'] != null
                ? _convertStringToTimeOfDay(snapshot['close_time'])
                : TimeOfDay.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && salonDocId != null) {
      try {
        List<String> changeDetails = _getChangeDetails();

        await FirebaseFirestore.instance
            .collection('salon')
            .doc(salonDocId)
            .update({
          'salon_name': _salonNameController.text,
          'owner_name': _ownerNameController.text,
          'address': _addressController.text,
          'open_time': _formatTimeOfDay(_openTime),
          'close_time': _formatTimeOfDay(_closeTime),
        });

        if (changeDetails.isNotEmpty) {
          await _createLog('Update Salon Info', changeDetails.join(", "));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Salon information updated successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        print("Error updating salon information: $e");
      }
    }
  }

  List<String> _getChangeDetails() {
    final oldData = {
      'salon_name': _salonNameController.text,
      'owner_name': _ownerNameController.text,
      'address': _addressController.text,
      'open_time': _formatTimeOfDay(_openTime),
      'close_time': _formatTimeOfDay(_closeTime),
    };

    return [
      if (oldData['salon_name'] != _salonNameController.text)
        "Salon Name changed from '${oldData['salon_name']}' to '${_salonNameController.text}'",
      if (oldData['owner_name'] != _ownerNameController.text)
        "Owner Name changed from '${oldData['owner_name']}' to '${_ownerNameController.text}'",
      if (oldData['address'] != _addressController.text)
        "Address changed from '${oldData['address']}' to '${_addressController.text}'",
      if (oldData['open_time'] != _formatTimeOfDay(_openTime))
        "Open Time changed from '${oldData['open_time']}' to '${_formatTimeOfDay(_openTime)}'",
      if (oldData['close_time'] != _formatTimeOfDay(_closeTime))
        "Close Time changed from '${oldData['close_time']}' to '${_formatTimeOfDay(_closeTime)}'",
    ];
  }

  Future<void> _createLog(String actionType, String description) async {
    if (salonDocId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('salon')
          .doc(salonDocId)
          .collection('logs')
          .add({
        'actionType': actionType,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating log: $e');
    }
  }

  TimeOfDay _convertStringToTimeOfDay(String time) {
    final format = DateFormat.jm(); // 12-hour format with AM/PM
    final dt = format.parse(time);
    return TimeOfDay.fromDateTime(dt);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final formattedTime = DateFormat.jm()
        .format(DateTime(now.year, now.month, now.day, time.hour, time.minute));
    return formattedTime;
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
              _buildEditCard(_salonNameController, 'Salon Name', Icons.store),
              const SizedBox(height: 20),
              _buildEditCard(_ownerNameController, 'Owner Name', Icons.person),
              const SizedBox(height: 20),
              _buildEditCard(_addressController, 'Address', Icons.location_on),
              const SizedBox(height: 20),
              _buildTimePickerCard('Open Time', _openTime, Icons.access_time,
                  (selectedTime) => setState(() => _openTime = selectedTime)),
              const SizedBox(height: 20),
              _buildTimePickerCard(
                'Close Time',
                _closeTime,
                Icons.access_time_filled,
                (selectedTime) => setState(() => _closeTime = selectedTime),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 32, 124, 46),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditCard(
      TextEditingController controller, String labelText, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                Text(labelText,
                    style: GoogleFonts.abel(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter $labelText'
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerCard(
    String labelText,
    TimeOfDay time,
    IconData icon,
    ValueChanged<TimeOfDay> onTimePicked,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                Text(labelText,
                    style: GoogleFonts.abel(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final pickedTime =
                    await showTimePicker(context: context, initialTime: time);
                if (pickedTime != null) onTimePicked(pickedTime);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: Text(time.format(context), style: GoogleFonts.abel()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
