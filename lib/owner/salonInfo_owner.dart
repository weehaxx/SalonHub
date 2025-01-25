import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:salon_hub/owner/edit_salon_info.dart';

class SaloninfoOwner extends StatefulWidget {
  const SaloninfoOwner({super.key});

  @override
  State<SaloninfoOwner> createState() => _SaloninfoOwnerState();
}

class _SaloninfoOwnerState extends State<SaloninfoOwner> {
  // Placeholder to store the salon data
  Map<String, dynamic>? salonData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _retrieveSalonInfo();
  }

  // Method to retrieve salon information based on the current owner
  Future<void> _retrieveSalonInfo() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Query Firestore to retrieve the salon information based on the owner's UID
        QuerySnapshot salonSnapshot = await FirebaseFirestore.instance
            .collection('salon')
            .where('owner_uid', isEqualTo: currentUser.uid)
            .get();

        if (salonSnapshot.docs.isNotEmpty) {
          // Fetch the first document that matches the UID and include the document ID
          final doc = salonSnapshot.docs.first;
          setState(() {
            salonData = {
              'id': doc.id, // Include document ID
              ...doc.data() as Map<String, dynamic>, // Merge document data
            };
            isLoading = false;
          });
        } else {
          setState(() {
            salonData = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error retrieving salon information: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon Information'),
        backgroundColor: const Color(0xff355E3B),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : salonData != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(salonData!['salon_name'], Icons.store),
                      _buildInfoCard(salonData!['owner_name'], Icons.person),
                      _buildInfoCard(
                        FirebaseAuth.instance.currentUser?.email ?? 'N/A',
                        Icons.email,
                      ),
                      _buildInfoCard(salonData!['address'], Icons.location_on),
                      _buildInfoCard(
                          salonData!['specialization'] ??
                              'No specialization provided',
                          Icons.brush), // Added here
                      _buildInfoCard(
                          salonData!['open_time'], Icons.access_time),
                      _buildInfoCard(
                          salonData!['close_time'], Icons.access_time_filled),
                      const SizedBox(height: 20),
                      _buildGoogleMap(), // Add Google Map widget
                    ],
                  ),
                )
              : const Center(
                  child: Text(
                    'No salon information found.',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
      floatingActionButton: salonData != null
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to the edit screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditSalonInfo(
                      salonData: salonData!, // Pass the salon data with the ID
                    ),
                  ),
                ).then((value) {
                  // Refresh the salon data when coming back from the edit screen
                  _retrieveSalonInfo();
                });
              },
              backgroundColor: const Color(0xff355E3B),
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  // Helper method to build individual cards with information
  Widget _buildInfoCard(String value, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15), // Spacing between cards
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // Inner padding inside the card
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xff355E3B),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 15), // Spacing between icon and text
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to display the salon location on Google Maps
  Widget _buildGoogleMap() {
    if (salonData == null ||
        salonData!['latitude'] == null ||
        salonData!['longitude'] == null) {
      return const Center(
        child: Text(
          'Location data not available.',
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    LatLng salonLocation = LatLng(
      salonData!['latitude'],
      salonData!['longitude'],
    );

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add a header for the map
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xff355E3B),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Text(
              'Current Location',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Display the Google Map
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: salonLocation,
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('salonLocation'),
                  position: salonLocation,
                  infoWindow: InfoWindow(
                    title: salonData!['salon_name'],
                    snippet: salonData!['address'],
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
