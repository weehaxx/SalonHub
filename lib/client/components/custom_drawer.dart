import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/bookingSchedule_client.dart';
import 'package:salon_hub/client/payment_history.dart';

class CustomDrawer extends StatelessWidget {
  final String? userName;
  final String? userEmail;
  final String? profileImageUrl;
  final VoidCallback onLogout;
  final VoidCallback? onReviewExperience; // Add this parameter

  const CustomDrawer({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.profileImageUrl,
    required this.onLogout,
    this.onReviewExperience, // Add this line
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
                  : const AssetImage('assets/images/logo.png') as ImageProvider,
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
            leading: const Icon(Icons.payments),
            title: Text(
              'Payment History',
              style: GoogleFonts.abel(),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentHistory(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: Text(
              'Review Experience',
              style: GoogleFonts.abel(),
            ),
            onTap: onReviewExperience, // Call the onReviewExperience callback
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
