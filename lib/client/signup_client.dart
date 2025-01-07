import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_hub/client/email_verification_page.dart';
import 'package:salon_hub/pages/login_page.dart'; // Update this path as per your project structure

class SignupClient extends StatefulWidget {
  const SignupClient({super.key});

  @override
  State<SignupClient> createState() => _SignupClientState();
}

class _SignupClientState extends State<SignupClient> {
  // Text controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Error messages
  String _nameError = '';
  String _emailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';

  bool _isPasswordVisible = false;
  bool _isLoading = false; // Track loading state

  @override
  void initState() {
    super.initState();

    // Add listeners for real-time validation
    _nameController.addListener(() {
      setState(() {
        _validateName();
      });
    });

    _emailController.addListener(() {
      setState(() {
        _validateEmail();
      });
    });

    _passwordController.addListener(() {
      setState(() {
        _validatePassword();
      });
    });

    _confirmPasswordController.addListener(() {
      setState(() {
        _validateConfirmPassword();
      });
    });
  }

  // Real-time name validation
  void _validateName() {
    if (_nameController.text.isEmpty) {
      _nameError = 'Please enter your name.';
    } else {
      _nameError = '';
    }
  }

  // Real-time email validation
  void _validateEmail() {
    if (!_isValidEmail(_emailController.text)) {
      _emailError = 'Please enter a valid email.';
    } else {
      _emailError = '';
    }
  }

  // Real-time password validation
  void _validatePassword() {
    if (_passwordController.text.length < 8) {
      _passwordError = 'Password must be at least 8 characters long.';
    } else {
      _passwordError = '';
    }
    _validateConfirmPassword(); // Ensure confirm password is checked as well
  }

  // Real-time confirm password validation
  void _validateConfirmPassword() {
    if (_passwordController.text != _confirmPasswordController.text) {
      _confirmPasswordError = 'Passwords do not match!';
    } else {
      _confirmPasswordError = '';
    }
  }

  // Function to sign up the user and send a verification email
  // Function to sign up the user and send a verification email
  Future<void> signupUser() async {
    setState(() {
      _nameError = '';
      _emailError = '';
      _passwordError = '';
      _confirmPasswordError = '';
      _isLoading = true; // Show loading indicator
    });

    // Final validation checks
    _validateName();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    if (_nameError.isEmpty &&
        _emailError.isEmpty &&
        _passwordError.isEmpty &&
        _confirmPasswordError.isEmpty) {
      try {
        // Create user in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim());

        // Send verification email
        await userCredential.user!.sendEmailVerification();

        // Navigate to the Email Verification Page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              name: _nameController.text.trim(),
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          setState(() {
            _emailError =
                'This email is already registered. Please use a different email.';
          });
        } else {
          setState(() {
            _emailError = 'Error: ${e.message}';
          });
        }
      } catch (e) {
        setState(() {
          _emailError = 'Unexpected error: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    } else {
      setState(() {
        _isLoading = false; // Hide loading indicator if validation fails
      });
    }
  }

  // Helper function to validate email using regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      body: Center(
        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20), // Adjust padding
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Image.asset(
                          "assets/images/logo2.png",
                          width: 150.0,
                          height: 150.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Register',
                        style: GoogleFonts.aboreto(
                          textStyle: const TextStyle(
                            fontSize: 25,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildTextField(
                          'Name', _nameController, false, _nameError),
                      const SizedBox(height: 20),
                      buildTextField(
                          'Email', _emailController, false, _emailError),
                      const SizedBox(height: 20),
                      buildTextField('Password', _passwordController, true,
                          _passwordError),
                      const SizedBox(height: 20),
                      buildTextField(
                          'Confirm Password',
                          _confirmPasswordController,
                          true,
                          _confirmPasswordError),
                      const SizedBox(height: 20),
                      Container(
                        width: 300,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xff355E3B),
                          borderRadius: BorderRadius.circular(12),
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
                          onPressed: signupUser,
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
            ),
            if (_isLoading)
              Container(
                color:
                    Colors.black.withOpacity(0.3), // Semi-transparent overlay
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xff355E3B),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(String hintText, TextEditingController controller,
      bool isPassword, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 60, // Increased height for a modern look
          width: 350,
          child: TextField(
            controller: controller,
            obscureText: isPassword ? !_isPasswordVisible : false,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200], // Light grey background
              prefixIcon: Icon(
                isPassword ? Icons.lock : Icons.person, // Add icons
                color: Colors.black54,
              ),
              hintText: hintText, // Use hintText instead of labelText
              hintStyle: const TextStyle(fontSize: 16, color: Colors.black54),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15), // Rounded corners
                borderSide: BorderSide.none, // No border for a clean look
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xff355E3B), // Green border when focused
                  width: 2.0,
                ),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (errorMessage.isNotEmpty) // Only show space if error exists
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
}
