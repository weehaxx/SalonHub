// custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/bookingSchedule_client.dart';

class CustomDrawer extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? profileImageUrl;
  final VoidCallback onLogout;

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              userName ?? 'User',
              style: GoogleFonts.abel(),
            ),
            accountEmail: Text(
              userEmail ?? '',
              style: GoogleFonts.abel(),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : const AssetImage('assets/images/default_user.png')
                      as ImageProvider,
            ),
            decoration: const BoxDecoration(
              color: Color(0xff355E3B),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(
              'Bookings',
              style: GoogleFonts.abel(),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingscheduleClient(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(
              'Logout',
              style: GoogleFonts.abel(),
            ),
            onTap: onLogout, // Call logout function
          ),
        ],
      ),
    );
  }
}
