import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullMapScreen extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng originalLocation;

  const FullMapScreen({
    super.key,
    required this.currentLocation,
    required this.originalLocation,
  });

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  late LatLng _selectedLocation;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.currentLocation;
  }

  // Adjust the map to fit both locations
  void _fitMapToBounds() {
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        widget.originalLocation.latitude < widget.currentLocation.latitude
            ? widget.originalLocation.latitude
            : widget.currentLocation.latitude,
        widget.originalLocation.longitude < widget.currentLocation.longitude
            ? widget.originalLocation.longitude
            : widget.currentLocation.longitude,
      ),
      northeast: LatLng(
        widget.originalLocation.latitude > widget.currentLocation.latitude
            ? widget.originalLocation.latitude
            : widget.currentLocation.latitude,
        widget.originalLocation.longitude > widget.currentLocation.longitude
            ? widget.originalLocation.longitude
            : widget.currentLocation.longitude,
      ),
    );
    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a New Location'),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.currentLocation,
              zoom: 14.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitMapToBounds();
            },
            onTap: (newLocation) {
              setState(() {
                _selectedLocation = newLocation;
              });
            },
            markers: {
              Marker(
                markerId: const MarkerId('selectedLocation'),
                position: _selectedLocation,
                infoWindow: const InfoWindow(title: "Selected Location"),
              ),
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, widget.originalLocation);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedLocation);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3B7A57),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                  ),
                  child: const Text('Okay'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
