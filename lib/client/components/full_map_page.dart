import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FullMapPage extends StatefulWidget {
  final LatLng userLocation;
  final LatLng salonLocation;
  final String salonName;

  const FullMapPage({
    super.key,
    required this.userLocation,
    required this.salonLocation,
    required this.salonName,
  });

  @override
  _FullMapPageState createState() => _FullMapPageState();
}

class _FullMapPageState extends State<FullMapPage> {
  late GoogleMapController _mapController;
  List<LatLng> _polylineCoordinates = [];

  late Polyline _routePolyline = const Polyline(
    polylineId: PolylineId("default"),
    points: [],
    color: Colors.transparent,
    width: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchDirections();
  }

  // Fetch directions between the user and salon locations
  Future<void> _fetchDirections() async {
    String googleAPIKey = 'YOUR_GOOGLE_API_KEY'; // Replace with your API key
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.userLocation.latitude},${widget.userLocation.longitude}&destination=${widget.salonLocation.latitude},${widget.salonLocation.longitude}&key=$googleAPIKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final polylinePoints =
              data['routes'][0]['overview_polyline']['points'];
          _decodePolyline(polylinePoints);
          _fitMapToBounds();
        } else {
          print('Error fetching directions: ${data['status']}');
        }
      } else {
        print('Error fetching directions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching directions: $e');
    }
  }

  // Decode polyline points to LatLng coordinates
  void _decodePolyline(String polyline) {
    List<LatLng> coordinates = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int b;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      coordinates.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }

    setState(() {
      _polylineCoordinates = coordinates;
      _routePolyline = Polyline(
        polylineId: const PolylineId("route"),
        points: _polylineCoordinates,
        color: Colors.blue,
        width: 5,
      );
    });
  }

  // Adjust the map to fit both locations
  void _fitMapToBounds() {
    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        widget.userLocation.latitude < widget.salonLocation.latitude
            ? widget.userLocation.latitude
            : widget.salonLocation.latitude,
        widget.userLocation.longitude < widget.salonLocation.longitude
            ? widget.userLocation.longitude
            : widget.salonLocation.longitude,
      ),
      northeast: LatLng(
        widget.userLocation.latitude > widget.salonLocation.latitude
            ? widget.userLocation.latitude
            : widget.salonLocation.latitude,
        widget.userLocation.longitude > widget.salonLocation.longitude
            ? widget.userLocation.longitude
            : widget.salonLocation.longitude,
      ),
    );

    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.userLocation,
          zoom: 12,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('userLocation'),
            position: widget.userLocation,
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen), // Different color for user
          ),
          Marker(
            markerId: const MarkerId('salonLocation'),
            position: widget.salonLocation,
            infoWindow: InfoWindow(title: widget.salonName),
          ),
        },
        polylines: _polylineCoordinates.isEmpty ? {} : {_routePolyline},
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _fitMapToBounds();
        },
      ),
    );
  }
}
