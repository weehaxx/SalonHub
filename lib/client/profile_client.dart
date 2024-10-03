import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileClient extends StatefulWidget {
  const ProfileClient({super.key});

  @override
  State<ProfileClient> createState() => _ProfileClientState();
}

class _ProfileClientState extends State<ProfileClient> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff355E3B),
        elevation: 0,
        centerTitle: true, // This centers the title
        title: Text(
          'PROFILE',
          style: GoogleFonts.abel(
            textStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture with Edit Icon
            Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage(
                      'assets/images/logo.png'), // replace with your image asset
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Name Field
            const ProfileField(
              label: 'Name',
              value: 'Michael Jhon Rojo',
            ),
            const SizedBox(height: 20),
            // Email Field
            const ProfileField(
              label: 'E-mail',
              value: 'm.rojo.525349@umindanao.edu.ph',
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;
  final Widget? leadingIcon;

  const ProfileField({
    super.key,
    required this.label,
    required this.value,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.abel(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                leadingIcon!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.abel(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
