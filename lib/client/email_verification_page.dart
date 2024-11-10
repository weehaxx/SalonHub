import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salon_hub/pages/login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final String password;
  final String name;

  const EmailVerificationPage({
    Key? key,
    required this.email,
    required this.password,
    required this.name,
  }) : super(key: key);

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isEmailVerified = false;
  bool _isLoading = false;
  late User _user;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = ''; // Clear any previous error message
    });

    await _user.reload();
    _user = FirebaseAuth.instance.currentUser!;
    _isEmailVerified = _user.emailVerified;

    if (_isEmailVerified) {
      await _addUserDataToFirestore();
    } else {
      setState(() {
        _errorMessage =
            'Email is not verified. Please check your inbox and try again.';
        _showErrorSnackbar(_errorMessage);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addUserDataToFirestore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(_user.uid).set({
        'name': widget.name,
        'email': widget.email,
        'role': 'client',
        'uid': _user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified! Registration complete.')),
      );

      // Navigate to login page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      print('Error adding user data to Firestore: $e');
      setState(() {
        _errorMessage = 'Failed to complete registration. Please try again.';
        _showErrorSnackbar(_errorMessage);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await _user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verification email sent! Please check your inbox.')),
      );
    } catch (e) {
      print('Error sending verification email: $e');
      setState(() {
        _errorMessage =
            'Failed to send verification email. Please try again later.';
        _showErrorSnackbar(_errorMessage);
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5), // Light background color
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.email,
                      color: Color(0xff355E3B),
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Email Verification',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff355E3B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Please verify your email to complete registration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () async {
                        await _checkEmailVerification();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff355E3B),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'I Verified My Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: _resendVerificationEmail,
                      child: Text(
                        'Resend Verification Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xff355E3B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Go Back',
                        style: TextStyle(
                          color: Color(0xff355E3B),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xff355E3B),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
