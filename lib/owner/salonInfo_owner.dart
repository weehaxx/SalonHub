import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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
          // Fetch the first document that matches the UID
          setState(() {
            salonData = salonSnapshot.docs.first.data() as Map<String, dynamic>;
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
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoCard(salonData!['salon_name'], Icons.store),
                      _buildInfoCard(salonData!['owner_name'], Icons.person),
                      _buildInfoCard(
                        FirebaseAuth.instance.currentUser?.email ?? 'N/A',
                        Icons.email,
                      ),
                      _buildInfoCard(salonData!['address'], Icons.location_on),
                      _buildInfoCard(
                          salonData!['open_time'], Icons.access_time),
                      _buildInfoCard(
                          salonData!['close_time'], Icons.access_time_filled),
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
                      salonData: salonData!,
                    ),
                  ),
                ).then((value) {
                  // Refresh the salon data when coming back from the edit screen
                  _retrieveSalonInfo();
                });
              },
              child: const Icon(Icons.edit),
              backgroundColor: const Color(0xff355E3B),
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
}
