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
  final TextEditingController salonSpecializationController;

  final Function(double?, double?) onLocationSelected;

  const SalonInformationForm({
    super.key,
    required this.salonNameController,
    required this.salonOwnerController,
    required this.salonSpecializationController, // Add here
    required this.addressController,
    required this.openTimeController,
    required this.closeTimeController,
    required this.onLocationSelected,
  });

  @override
  _SalonInformationFormState createState() => _SalonInformationFormState();
}

class _SalonInformationFormState extends State<SalonInformationForm> {
  bool _isLoading = true;
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchSalonData();
    _checkLocationPermission();
  }

  Future<void> _fetchSalonData() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('salon')
            .doc(currentUser.uid)
            .get()
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Fetching salon data timed out.');
          },
        );

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>? ?? {};
          if (mounted) {
            setState(() {
              widget.salonNameController.text = data['salon_name'] ?? '';
              widget.salonSpecializationController.text =
                  data['specialization'] ?? '';
              widget.salonOwnerController.text = data['owner_name'] ?? '';
              widget.addressController.text = data['address'] ?? '';
              widget.openTimeController.text = data['open_time'] ?? '';
              widget.closeTimeController.text = data['close_time'] ?? '';
            });
          }
        } else {
          print('No salon data found for user ${currentUser.uid}.');
        }
      } catch (e) {
        print('Error fetching salon data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load salon information.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      _locateMyPosition();
    }
  }

  Future<void> _locateMyPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Fetching location timed out.');
        },
      );

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 14.0),
      );

      setState(() {
        _currentLocation = currentLatLng;
        _selectedLocation = currentLatLng;
        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLatLng,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
          },
          infoWindow: const InfoWindow(title: 'Drag to Set Location'),
        ));
      });
    } catch (e) {
      print('Error locating position: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch location. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Open the full-screen map to select location
  void _onMapTap(LatLng tappedPoint) {
    _openFullMap();
  }

  Future<void> _openFullMap() async {
    LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMap(
          initialPosition:
              _selectedLocation ?? _currentLocation ?? const LatLng(0, 0),
        ),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId('selectedLocation'),
          position: pickedLocation,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
          },
          infoWindow: const InfoWindow(title: 'Drag to Set Location'),
        ));

        // Update the camera position on the small map to reflect the selected location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(pickedLocation, 14.0),
        );
      });
    }
  }

  Future<void> _submitMyLocation() async {
    try {
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a location before submitting.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User is not logged in.');
      }

      // Extract latitude and longitude from the selected location
      final double latitude = _selectedLocation!.latitude;
      final double longitude = _selectedLocation!.longitude;

      if (latitude == 0.0 && longitude == 0.0) {
        throw Exception('Invalid location coordinates.');
      }

      // Collect additional details from the form
      final String address = widget.addressController.text.trim();
      final String openTime = widget.openTimeController.text.trim();
      final String closeTime = widget.closeTimeController.text.trim();
      final String specialization =
          widget.salonSpecializationController.text.trim();

      // Validate required fields
      if (specialization.isEmpty ||
          address.isEmpty ||
          openTime.isEmpty ||
          closeTime.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Specialization, address, opening time, and closing time must not be empty.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('salon').doc(currentUser.uid);

      // Prepare the data payload
      final Map<String, dynamic> salonData = {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'open_time': openTime,
        'close_time': closeTime,
        'specialization': specialization,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Check if the salon document already exists
      final DocumentSnapshot userDocSnapshot = await userDocRef.get();
      if (!userDocSnapshot.exists) {
        // Add 'createdAt' for new documents
        salonData['createdAt'] = FieldValue.serverTimestamp();

        // Create the new document
        await userDocRef.set(salonData);
        print('Document created for user: ${currentUser.uid}');
      } else {
        // Update the existing document
        await userDocRef.update(salonData);
        print('Document updated for user: ${currentUser.uid}');
      }

      // Call the callback to update the parent widget with the new location
      widget.onLocationSelected(latitude, longitude);

      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location and details successfully saved!'),
          backgroundColor: Colors.green,
        ),
      );

      // Update the map with the new marker
      setState(() {
        _markers.clear();
        _markers.add(Marker(
          markerId: const MarkerId('selectedLocation'),
          position: _selectedLocation!,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
          },
          infoWindow: const InfoWindow(title: 'Submitted Location'),
        ));
      });

      // Adjust the camera position to focus on the selected location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 14.0),
      );
    } catch (e) {
      print('Error submitting location: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save location. Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                          'Salon Specialization', // Label
                          widget.salonSpecializationController, // Controller
                          false, // Not read-only
                        ),
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
                        _buildGoogleMap(),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submitMyLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff355E3B),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
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
        onTap: _onMapTap, // Directly call the _onMapTap method
        initialCameraPosition: CameraPosition(
          target: _currentLocation ?? const LatLng(0, 0),
          zoom: 14,
        ),
        markers: _markers,
        myLocationEnabled: false,
      ),
    );
  }
}

class FullScreenMap extends StatefulWidget {
  final LatLng initialPosition;

  const FullScreenMap({
    Key? key,
    required this.initialPosition,
  }) : super(key: key);

  @override
  _FullScreenMapState createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extends the body behind the app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent background
        elevation: 0, // Removes the shadow from the app bar
        title: Text(
          'Select Location',
          style: TextStyle(
            color: Colors.black, // Black text color for visibility
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // Centers the title
        iconTheme: IconThemeData(color: Colors.black), // Black icon color
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {},
            onTap: (tappedPoint) {
              setState(() {
                _selectedLocation = tappedPoint;
              });
            },
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition,
              zoom: 14,
            ),
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selectedLocation'),
                      position: _selectedLocation!,
                      draggable: true,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _selectedLocation = newPosition;
                        });
                      },
                    ),
                  }
                : {},
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected Location:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 60,
            right: 60,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: const Color(0xff355E3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Location',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
