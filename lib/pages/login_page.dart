import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:salon_hub/client/salonHomepage_client.dart';
import 'package:salon_hub/owner/form_owner.dart';
import 'package:salon_hub/pages/signup_page.dart';
import 'package:salon_hub/owner/dashboard_owner.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _emailError = '';
  String _passwordError = '';
  String _loginError = '';
  String _googleSignInError = '';

  @override
  void initState() {
    super.initState();

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
  }

  // Function to validate email
  bool _validateEmail() {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email cannot be empty';
      });
      return false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email)) {
      setState(() {
        _emailError = 'Please enter a valid email';
      });
      return false;
    } else {
      setState(() {
        _emailError = ''; // Clear error when input is valid
      });
      return true;
    }
  }

  // Function to validate password
  bool _validatePassword() {
    String password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _passwordError = 'Password cannot be empty';
      });
      return false;
    } else if (password.length < 8) {
      setState(() {
        _passwordError = 'Password must be at least 8 characters long';
      });
      return false;
    } else {
      setState(() {
        _passwordError = ''; // Clear error when input is valid
      });
      return true;
    }
  }

  // Function to sign in with Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _googleSignInError = ''; // Resetting Google sign-in error
    });

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // If the sign-in is canceled
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtain authentication details
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

      if (userDoc.exists) {
        String role = userDoc['role'];

        // Navigate based on role
        if (role == 'client') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SalonhomepageClient(),
            ),
          );
        } else if (role == 'owner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const FormOwner(),
            ),
          );
        } else {
          setState(() {
            _loginError = 'Unknown role detected.';
          });
        }
      } else {
        // If user doesn't exist, show a message to register
        setState(() {
          _googleSignInError = 'No account found. Please register first.';
          _isLoading = false;
        });
        await FirebaseAuth.instance.signOut(); // Sign out to allow sign up
      }
    } catch (e) {
      setState(() {
        _googleSignInError = 'Error occurred during Google sign-in: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
      _emailError = '';
      _passwordError = '';
      _loginError = '';
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      if (!_validateEmail() || !_validatePassword()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];

        // Navigate based on role
        if (role == 'client') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SalonhomepageClient(),
            ),
          );
        } else if (role == 'owner') {
          // Check if the owner has filled the salon details
          await _checkSalonDetails(userCredential.user!.uid);
        } else {
          setState(() {
            _loginError = 'Unknown role detected.';
          });
        }
      } else {
        setState(() {
          _loginError = 'User data not found in Firestore.';
        });
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          setState(() {
            _loginError = 'No user found with this email.';
          });
          break;
        case 'wrong-password':
          setState(() {
            _loginError = 'Incorrect password. Please try again.';
          });
          break;
        case 'invalid-email':
          setState(() {
            _loginError = 'Invalid email format.';
          });
          break;
        default:
          setState(() {
            _loginError = 'An error occurred: ${e.message}';
          });
      }
    } catch (e) {
      setState(() {
        _loginError = 'An unexpected error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    if (_loginError.isNotEmpty) {
      setState(() {
        _passwordController.clear(); // Clear password field after failed login
      });
    }
  }

  Future<void> _checkSalonDetails(String uid) async {
    try {
      // Log the UID for debugging
      print('Checking salon details for user: $uid');

      // Query the 'salon' collection where 'uid' field equals the user's UID
      QuerySnapshot salonQuery = await FirebaseFirestore.instance
          .collection('salon')
          .where('owner_uid', isEqualTo: uid)
          .limit(1) // Limit to 1 result for efficiency
          .get();

      if (salonQuery.docs.isNotEmpty) {
        // If salon details exist, redirect to the dashboard
        print('Salon details exist for user: $uid. Redirecting to dashboard.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardOwner(),
          ),
        );
      } else {
        // If salon details do not exist, redirect to the form page
        print(
            'No salon details found for user: $uid. Redirecting to FormOwner.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const FormOwner(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _loginError = 'Error checking salon details: $e';
      });
      print('Error checking salon details: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          color: const Color(0xff355E3B),
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
              Text(
                'Salon Hub',
                style: GoogleFonts.aboreto(
                  textStyle: const TextStyle(
                    fontSize: 35,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Your Beauty Companion',
                style: GoogleFonts.aboreto(
                  textStyle: const TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(255, 243, 243, 243),
                  ),
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
                      'Welcome Back!',
                      style: GoogleFonts.aboreto(
                        textStyle: const TextStyle(
                          fontSize: 25,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildTextField(
                        'Email', _emailController, false, _emailError),
                    const SizedBox(height: 10),
                    buildTextField(
                        'Password', _passwordController, true, _passwordError),
                    const SizedBox(height: 20),
                    if (_loginError.isNotEmpty) // Display Firebase login errors
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _loginError,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    if (_googleSignInError
                        .isNotEmpty) // Google Sign-In error message
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _googleSignInError,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              // Sign In Button
                              Container(
                                width: 300,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xff355E3B),
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
                                  onPressed: loginUser,
                                  child: Text(
                                    'Sign In',
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
                              // Google Sign-In Button
                              GestureDetector(
                                onTap: _signInWithGoogle,
                                child: Container(
                                  width: 300,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/google.png',
                                        height: 18,
                                        width: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Sign in with Google',
                                        style: GoogleFonts.aboreto(
                                          textStyle: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: GoogleFonts.aBeeZee(),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignupPage()),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
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
