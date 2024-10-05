import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SalonInformationForm extends StatefulWidget {
  final TextEditingController salonNameController;
  final TextEditingController salonOwnerController;
  final TextEditingController addressController;
  final TextEditingController openTimeController;
  final TextEditingController closeTimeController;

  // Add these two properties to pass latitude and longitude back
  final Function(double?, double?) onLocationSelected;

  const SalonInformationForm({
    super.key,
    required this.salonNameController,
    required this.salonOwnerController,
    required this.addressController,
    required this.openTimeController,
    required this.closeTimeController,
    required this.onLocationSelected, // Pass the location callback
  });

  @override
  _SalonInformationFormState createState() => _SalonInformationFormState();
}

class _SalonInformationFormState extends State<SalonInformationForm> {
  bool _isLoading = true;
  LatLng? _currentLocation;
  GoogleMapController? _mapController;

  // Marker set to show on the map
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchSalonData();
    _checkLocationPermission(); // Automatically check for location permission on load
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

  // Function to check location permission and fetch current location
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      // If permission is granted, get the current position
      _locateMyPosition();
    }
  }

  // Function to automatically locate and display the current position
  Future<void> _locateMyPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      // Move the camera to the new location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 14.0),
      );

      // Update the marker on the map
      setState(() {
        _currentLocation = currentLatLng;
        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLatLng,
          infoWindow: const InfoWindow(title: 'Current Location'),
        ));
      });
    } catch (e) {
      print('Error locating position: $e');
    }
  }

  // Function to save the current location when clicking the "Next" button
  Future<void> _submitMyLocation() async {
    try {
      if (_currentLocation != null) {
        final User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
          });

          // Pass the latitude and longitude back to form_owner.dart
          widget.onLocationSelected(
              _currentLocation!.latitude, _currentLocation!.longitude);
        }
      }
    } catch (e) {
      print('Error submitting location: $e');
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
                        // Display the Google Map automatically without any button
                        _buildGoogleMap(),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                  // Centered "Submit My Location" button with custom design
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitMyLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xff355E3B), // Button color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5, // Shadow effect
                      ),
                      child: Text(
                        'Submit My Location',
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Function to build a text field
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

  // Function to build a time picker field
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

  // Function to build the Google Map
  Widget _buildGoogleMap() {
    return SizedBox(
      height: 300,
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          if (_currentLocation != null) {
            _mapController
                ?.moveCamera(CameraUpdate.newLatLng(_currentLocation!));
          }
        },
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? const LatLng(0, 0), // Default position
          zoom: 14,
        ),
        markers: _markers, // Use the updated markers set
        myLocationEnabled: false, // Disable automatic location marker
      ),
    );
  }
}
