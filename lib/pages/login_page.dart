import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _resetPasswordMessage = '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_emailController.text.isNotEmpty) {
        setState(() {
          _emailError = '';
        });
      }
    });
    _passwordController.addListener(() {
      if (_passwordController.text.isNotEmpty) {
        setState(() {
          _passwordError = '';
        });
      }
    });
  }

  // Function to check if user is blocked
  Future<void> _checkIfUserBlocked(String uid) async {
    DocumentSnapshot flagDoc = await FirebaseFirestore.instance
        .collection('user_flags')
        .doc(uid)
        .get();

    if (flagDoc.exists) {
      int cancelCount = flagDoc['cancelCount'] ?? 0;
      if (cancelCount >= 3) {
        _showBlockedAccountDialog();
        return;
      }
    }
    _navigateBasedOnRole(uid);
  }

  // Function to show the blocked account dialog
  void _showBlockedAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Blocked'),
        content: const Text(
          'Your account has been blocked due to multiple appointment cancellations.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Log out the user and redirect to the login page
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const Login(),
                ),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPasswordDialog(BuildContext context) async {
    TextEditingController resetEmailController = TextEditingController();
    String resetEmailError = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please enter your registered email address. We will send you a link to reset your password. Make sure to check your inbox and follow the instructions provided.',
                style: GoogleFonts.aBeeZee(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 15),
              buildTextField(
                'Enter your email',
                resetEmailController,
                false,
                resetEmailError,
                Icons.email,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xff355E3B),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                String email = resetEmailController.text.trim();
                if (email.isEmpty) {
                  setState(() {
                    resetEmailError = 'Email cannot be empty';
                  });
                } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                    .hasMatch(email)) {
                  setState(() {
                    resetEmailError = 'Please enter a valid email address';
                  });
                } else {
                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    Navigator.of(context).pop();
                    setState(() {
                      _resetPasswordMessage =
                          'Password reset link has been sent to your email. Please check your inbox.';
                    });
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'user-not-found') {
                      setState(() {
                        resetEmailError = 'No user found with this email.';
                      });
                    } else if (e.code == 'invalid-email') {
                      setState(() {
                        resetEmailError = 'Invalid email format.';
                      });
                    } else {
                      setState(() {
                        resetEmailError = 'An error occurred: ${e.message}';
                      });
                    }
                  }
                }
              },
              child: const Text('Submit'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff355E3B),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> loginUser() async {
    setState(() {
      _isLoading = true;
      _loginError = '';
    });

    bool isEmailValid = _validateEmail();
    bool isPasswordValid = _validatePassword();

    if (!isEmailValid || !isPasswordValid) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;
      await _checkIfUserBlocked(uid);
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

  Future<void> _navigateBasedOnRole(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

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
        await _checkSalonDetails(uid);
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
  }

  Future<void> _checkSalonDetails(String uid) async {
    try {
      QuerySnapshot salonQuery = await FirebaseFirestore.instance
          .collection('salon')
          .where('owner_uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (salonQuery.docs.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardOwner(),
          ),
        );
      } else {
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
                padding: const EdgeInsets.only(top: 80.0),
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
              const SizedBox(height: 40),
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
                    const SizedBox(height: 20),
                    buildTextField(
                      'Email',
                      _emailController,
                      false,
                      _emailError,
                      Icons.email,
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                      'Password',
                      _passwordController,
                      true,
                      _passwordError,
                      Icons.lock,
                    ),
                    const SizedBox(height: 20),
                    if (_loginError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _loginError,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : _buildLoginButtons(),
                    const SizedBox(height: 30),
                    _buildSignUpOption(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButtons() {
    return Column(
      children: [
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
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _resetPasswordDialog(context),
          child: const Text(
            "Forgot Password?",
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.black,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_resetPasswordMessage.isNotEmpty)
          Text(
            _resetPasswordMessage,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildSignUpOption() {
    return Row(
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
              MaterialPageRoute(builder: (context) => const SignupPage()),
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
    );
  }

  Widget buildTextField(String hintText, TextEditingController controller,
      bool isPassword, String errorMessage, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 60,
          width: 300,
          child: TextField(
            controller: controller,
            obscureText: isPassword ? !_isPasswordVisible : false,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              prefixIcon: Icon(icon, color: Colors.black54),
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 16, color: Colors.black54),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xff355E3B),
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
