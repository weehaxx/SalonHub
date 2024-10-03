import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  String _googleSignInError = ''; // To display Google sign-in errors

  bool _isPasswordVisible = false;

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
  Future<void> signupUser() async {
    // Clear previous error messages
    setState(() {
      _nameError = '';
      _emailError = '';
      _passwordError = '';
      _confirmPasswordError = '';
    });

    // Run final validation before sign-up
    _validateName();
    _validateEmail();
    _validatePassword();
    _validateConfirmPassword();

    // If there are no errors, proceed with sign-up
    if (_nameError.isEmpty &&
        _emailError.isEmpty &&
        _passwordError.isEmpty &&
        _confirmPasswordError.isEmpty) {
      try {
        // Create a new user with Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim());

        // Send a verification email
        await userCredential.user!.sendEmailVerification();

        // Show the verification dialog
        _showEmailVerificationDialog();
      } catch (e) {
        setState(() {
          _emailError = 'Error: $e';
        });
      }
    }
  }

  // Function to check if the email is verified and refresh user data
  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Reload the user's data to get the latest email verification status
      await user.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user!.emailVerified) {
        // If the email is verified, proceed with registration
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'client',
          'uid': user.uid,
        });

        // Show success message and navigate to the login page
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
      } else {
        // Show an error if the email is not verified yet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Email not verified yet. Please verify your email and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Function to show the email verification dialog
  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verify Your Email'),
          content: const Text(
              'We have sent a verification link to your email. Please verify your email address to complete the registration.'),
          actions: [
            TextButton(
              onPressed: () async {
                await _checkEmailVerification();
              },
              child: const Text('I Verified'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Helper function to validate email using regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Function to handle Google sign-in
  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleSignInError = ''; // Clear previous error
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if the user already exists in Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Cast the data to a Map<String, dynamic> for checking fields
      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        // If new user, save user data to Firestore including an empty name field
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'role': 'client', // Assign 'client' role here
          'uid': userCredential.user!.uid,
          'name': '', // Add an empty name field
        });
      } else if (!userData.containsKey('name')) {
        // Add the name field if it doesn't exist in the existing document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({'name': ''});
      }

      // Navigate to the next screen (e.g., main page)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _googleSignInError = 'Error occurred during Google sign-in: $e';
      });
    }
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
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          color: const Color(0xff355e30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 120.0),
                child: Image.asset(
                  "assets/images/logo.png",
                  width: 150.0,
                  height: 150.0,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                    buildTextField('Name', _nameController, false, _nameError),
                    const SizedBox(height: 20),
                    buildTextField(
                        'Email', _emailController, false, _emailError),
                    const SizedBox(height: 20),
                    buildTextField(
                        'Password', _passwordController, true, _passwordError),
                    const SizedBox(height: 20),
                    buildTextField(
                        'Confirm Password',
                        _confirmPasswordController,
                        true,
                        _confirmPasswordError),
                    const SizedBox(height: 20),
                    if (_googleSignInError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _googleSignInError,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    Container(
                      width: 300,
                      height: 40,
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
                    const SizedBox(height: 20),
                    Text(
                      'or register with:',
                      style: GoogleFonts.aBeeZee(),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _signInWithGoogle,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/google.png',
                            height: 40,
                            width: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
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
          width: 300,
          child: TextField(
            controller: controller,
            obscureText: isPassword ? !_isPasswordVisible : false,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Colors.black,
                  width: 1.0,
                ),
              ),
              labelText: labelText,
              labelStyle: const TextStyle(
                fontSize: 17,
                color: Colors.black,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
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
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
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
}
