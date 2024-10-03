import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupOwner extends StatefulWidget {
  const SignupOwner({super.key});

  @override
  State<SignupOwner> createState() => _SignupOwnerState();
}

class _SignupOwnerState extends State<SignupOwner> {
  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ownerNameController = TextEditingController(); // For salon owner name
  final _salonNameController = TextEditingController(); // For salon name

  // Error messages
  String _emailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';
  String _ownerNameError = '';
  String _salonNameError = '';
  final String _googleSignInError = ''; // To display Google sign-in errors

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Password validation flags
  bool _isLengthValid = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ownerNameController.dispose();
    _salonNameController.dispose();
    super.dispose();
  }

  // Function to validate the email format
  bool _isValidEmail(String email) {
    String emailPattern = r'^[a-zA-Z0-9._]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
    RegExp regExp = RegExp(emailPattern);
    return regExp.hasMatch(email);
  }

  // Function to check if the password matches validation criteria
  void _validatePassword(String password) {
    setState(() {
      _isLengthValid = password.length >= 6;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*]'));
    });
  }

  // Function to sign up the user
  Future<void> signupUser() async {
    setState(() {
      _emailError = '';
      _passwordError = '';
      _confirmPasswordError = '';
      _ownerNameError = '';
      _salonNameError = '';
    });

    // Validate fields
    if (_ownerNameController.text.isEmpty) {
      setState(() {
        _ownerNameError = 'Please enter the salon owner\'s name.';
      });
    }
    if (_salonNameController.text.isEmpty) {
      setState(() {
        _salonNameError = 'Please enter the salon\'s name.';
      });
    }
    if (!_isValidEmail(_emailController.text)) {
      setState(() {
        _emailError = 'Please enter a valid email address.';
      });
    }
    if (!_isLengthValid ||
        !_hasUppercase ||
        !_hasLowercase ||
        !_hasNumber ||
        !_hasSpecialChar) {
      setState(() {
        _passwordError = 'Password does not meet all requirements.';
      });
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match.';
      });
    }

    // Final validation
    if (_emailError.isEmpty &&
        _passwordError.isEmpty &&
        _confirmPasswordError.isEmpty &&
        _ownerNameError.isEmpty &&
        _salonNameError.isEmpty) {
      try {
        // Create a new user with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim());

        // Save the user's data in Firestore, including owner details
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'role': 'owner', // Assign 'owner' role here
          'uid': userCredential.user!.uid,
          'owner_name': _ownerNameController.text.trim(),
          'salon_name': _salonNameController.text.trim(),
        });

        // Show success message and navigate to login page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Redirecting to login...'),
            backgroundColor: Colors.green,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const Login(),
          ),
        );
      } catch (e) {
        setState(() {
          _emailError = 'Error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Text(
                'Register As Owner',
                style: GoogleFonts.aboreto(
                  textStyle: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildTextField('Salon Owner Name', _ownerNameController, false,
                  _ownerNameError),
              const SizedBox(height: 20),
              buildTextField(
                  'Salon Name', _salonNameController, false, _salonNameError),
              const SizedBox(height: 20),
              buildTextField('Email', _emailController, false, _emailError),
              const SizedBox(height: 20),
              buildPasswordField(
                  'Password', _passwordController, _isPasswordVisible, (value) {
                setState(() {
                  _isPasswordVisible = value;
                });
              }, _passwordError),
              buildPasswordValidationChecklist(), // Password validation checklist
              const SizedBox(height: 20),
              buildPasswordField('Confirm Password', _confirmPasswordController,
                  _isConfirmPasswordVisible, (value) {
                setState(() {
                  _isConfirmPasswordVisible = value;
                });
              }, _confirmPasswordError),
              const SizedBox(height: 20),
              if (_googleSignInError.isNotEmpty) // Display Google Sign-in error
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _googleSignInError,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xff355e30),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () {
                    signupUser();
                  },
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.aboreto(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String labelText, TextEditingController controller,
      bool isPassword, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          width: double.infinity,
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              labelText: labelText,
              labelStyle: GoogleFonts.poppins(
                fontSize: 17,
                color: Colors.black,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 128, 26, 245),
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget buildPasswordField(String labelText, TextEditingController controller,
      bool isVisible, Function(bool) onToggleVisibility, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          width: double.infinity,
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            onChanged: (value) {
              _validatePassword(value); // Validate password in real-time
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              labelText: labelText,
              labelStyle: GoogleFonts.poppins(
                fontSize: 17,
                color: Colors.black,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () => onToggleVisibility(!isVisible),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 128, 26, 245),
                  width: 2.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
        if (errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget buildPasswordValidationChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildValidationItem(_isLengthValid, "At least 6 characters"),
        _buildValidationItem(_hasUppercase, "At least 1 uppercase letter"),
        _buildValidationItem(_hasLowercase, "At least 1 lowercase letter"),
        _buildValidationItem(_hasNumber, "At least 1 number"),
        _buildValidationItem(
            _hasSpecialChar, "At least 1 special character (!@#\$%^&*)"),
      ],
    );
  }

  Widget _buildValidationItem(bool isValid, String text) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.poppins(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
