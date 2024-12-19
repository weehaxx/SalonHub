import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'full_map_screen.dart';

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
  late String? salonDocId;

  late LatLng _currentLocation;
  late LatLng _originalLocation; // Store the original location for reverting

  @override
  void initState() {
    super.initState();

    // Extract document ID and initialize form fields
    salonDocId = widget.salonData['id'];
    if (salonDocId == null || salonDocId!.isEmpty) {
      _showError("Invalid salon ID. Please contact support.");
      return;
    }

    _salonNameController =
        TextEditingController(text: widget.salonData['salon_name'] ?? '');
    _ownerNameController =
        TextEditingController(text: widget.salonData['owner_name'] ?? '');
    _addressController =
        TextEditingController(text: widget.salonData['address'] ?? '');
    _openTime = widget.salonData['open_time'] != null
        ? _convertStringToTimeOfDay(widget.salonData['open_time'])
        : TimeOfDay.now();
    _closeTime = widget.salonData['close_time'] != null
        ? _convertStringToTimeOfDay(widget.salonData['close_time'])
        : TimeOfDay.now();

    // Initialize the current and original locations
    _currentLocation = LatLng(
      widget.salonData['latitude'] ?? 0.0,
      widget.salonData['longitude'] ?? 0.0,
    );
    _originalLocation = _currentLocation;
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _logAction(String actionType, String description) async {
    if (salonDocId == null || salonDocId!.isEmpty) return;

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
      _showError('Error logging action: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (salonDocId == null || salonDocId!.isEmpty) {
        _showError("Cannot update salon information. Invalid document ID.");
        return;
      }

      try {
        // Retrieve the original data for comparison
        final salonDocSnapshot = await FirebaseFirestore.instance
            .collection('salon')
            .doc(salonDocId)
            .get();

        final originalData = salonDocSnapshot.data();

        // Prepare updated data
        final updatedData = {
          'salon_name': _salonNameController.text,
          'owner_name': _ownerNameController.text,
          'address': _addressController.text,
          'open_time': _formatTimeOfDay(_openTime),
          'close_time': _formatTimeOfDay(_closeTime),
          'latitude': _currentLocation.latitude,
          'longitude': _currentLocation.longitude,
        };

        // Update salon data
        await FirebaseFirestore.instance
            .collection('salon')
            .doc(salonDocId)
            .update(updatedData);

        // Compare and log changes
        for (final key in updatedData.keys) {
          if (originalData != null &&
              updatedData[key].toString() != originalData[key].toString()) {
            await _logAction(
              'Salon Info Updated',
              'Updated $key: ${originalData[key]} → ${updatedData[key]}',
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salon information updated successfully!'),
          ),
        );

        Navigator.pop(context, true);
      } catch (e) {
        _showError('Error updating salon information: $e');
      }
    }
  }

  Future<void> _openFullMap() async {
    debugPrint("Opening Full Map Screen...");
    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMapScreen(
          currentLocation: _currentLocation,
          originalLocation: _originalLocation,
        ),
      ),
    );

    if (selectedLocation != null) {
      debugPrint("New location selected: $selectedLocation");
      setState(() {
        _currentLocation = selectedLocation;
      });
    } else {
      debugPrint("Map interaction cancelled.");
    }
  }

  TimeOfDay _convertStringToTimeOfDay(String? time) {
    if (time == null || time.isEmpty) return TimeOfDay.now();
    try {
      final format = DateFormat.jm();
      final dt = format.parse(time);
      return TimeOfDay.fromDateTime(dt);
    } catch (e) {
      print('Error parsing time string: $e');
      return TimeOfDay.now();
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    return DateFormat.jm()
        .format(DateTime(now.year, now.month, now.day, time.hour, time.minute));
  }

  void _showError(String message) {
    debugPrint("Error: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              const SizedBox(height: 20),
              _buildLocationPickerCard(),
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

  Widget _buildLocationPickerCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xff355E3B),
                      child: const Icon(Icons.location_on, color: Colors.white),
                    ),
                    const SizedBox(width: 15),
                    Text('Location',
                        style: GoogleFonts.abel(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
                ElevatedButton(
                  onPressed: _openFullMap,
                  child: const Text('Edit Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 60, 150, 90),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 14.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('currentLocation'),
                    position: _currentLocation,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
