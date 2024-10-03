import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SalonInformationForm extends StatefulWidget {
  final TextEditingController salonNameController;
  final TextEditingController salonOwnerController;
  final TextEditingController addressController;
  final TextEditingController openTimeController;
  final TextEditingController closeTimeController;

  const SalonInformationForm({
    super.key,
    required this.salonNameController,
    required this.salonOwnerController,
    required this.addressController,
    required this.openTimeController,
    required this.closeTimeController,
  });

  @override
  _SalonInformationFormState createState() => _SalonInformationFormState();
}

class _SalonInformationFormState extends State<SalonInformationForm> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSalonData();
  }

  // Async method to fetch salon data from Firestore
  Future<void> _fetchSalonData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            widget.salonNameController.text = userDoc['salon_name'] ?? '';
            widget.salonOwnerController.text = userDoc['owner_name'] ?? '';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error fetching salon data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Salon Information',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 24,
                              color: Color(0xff355E3B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                            'Salon Name', widget.salonNameController, true),
                        _buildTextField(
                            'Salon Owner', widget.salonOwnerController, true),
                        _buildTimePickerField(
                            'Opening Time', widget.openTimeController, context),
                        const SizedBox(height: 15),
                        _buildTimePickerField('Closing Time',
                            widget.closeTimeController, context),
                        const SizedBox(height: 15),
                        _buildTextField(
                            'Address', widget.addressController, false),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool readOnly) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(color: Color(0xff355E3B)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xff355E3B)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff355E3B)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerField(
      String label, TextEditingController controller, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        TimeOfDay? selectedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (selectedTime != null) {
          final formattedTime = selectedTime.format(context);
          controller.text = formattedTime;
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          style: const TextStyle(color: Color(0xff355E3B)),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xff355E3B)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff355E3B)),
            ),
          ),
        ),
      ),
    );
  }
}
