import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salon_hub/client/salonHomepage_client.dart';
import 'package:salon_hub/client/user_preferences.dart';
import 'package:salon_hub/owner/banned_page.dart';
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
  String _loginError = '';
  String _resetPasswordMessage = '';

  @override
  void initState() {
    super.initState();
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

  bool _validateEmail() {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _loginError = 'Please enter your email';
      });
      return false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$').hasMatch(email)) {
      setState(() {
        _loginError = 'Please enter a valid email';
      });
      return false;
    } else {
      setState(() {
        _loginError = '';
      });
      return true;
    }
  }

  bool _validatePassword() {
    String password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _loginError = 'Please enter your password';
      });
      return false;
    } else if (password.length < 8) {
      setState(() {
        _loginError = 'Password must be at least 8 characters';
      });
      return false;
    } else {
      setState(() {
        _loginError = '';
      });
      return true;
    }
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
              TextField(
                controller: resetEmailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  filled: true,
                  fillColor: Colors.grey[200],
                  prefixIcon: const Icon(Icons.email, color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  errorText:
                      resetEmailError.isNotEmpty ? resetEmailError : null,
                ),
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
                          'Password reset link sent to your email. Check your inbox.';
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

  Future<void> loginUser() async {
    if (!mounted) return; // Ensure widget is in the tree

    setState(() {
      _isLoading = true;
      _loginError = '';
    });

    // Validate email and password
    if (!_validateEmail() || !_validatePassword()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Sign in the user
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Wait for Firebase to sync user data
      await FirebaseAuth.instance.currentUser!.reload();

      // Check if the user is a salon owner
      DocumentSnapshot salonDoc =
          await FirebaseFirestore.instance.collection('salon').doc(uid).get();

      if (salonDoc.exists) {
        final salonData = salonDoc.data() as Map<String, dynamic>?;

        // Check if the account is banned
        if (salonData?['isBanned'] == true) {
          DateTime? banEndDate;

          // Parse banEndDate if it exists
          if (salonData?['banEndDate'] != null) {
            banEndDate = DateTime.parse(salonData?['banEndDate']);
          }

          // If ban has expired, unban the account
          if (banEndDate != null && DateTime.now().isAfter(banEndDate)) {
            await FirebaseFirestore.instance
                .collection('salon')
                .doc(uid)
                .update({
              'isBanned': false,
              'banEndDate': null,
              'missedAppointmentCount': 0, // Reset missed count after unbanning
            });
          } else {
            // Redirect to the BannedPage if the account is still banned
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BannedPage(),
              ),
            );
            return;
          }
        }

        // Check if the owner profile is complete
        if (salonData?['profileComplete'] == null ||
            salonData?['profileComplete'] == false) {
          // Redirect to FormOwner if profile is not complete
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const FormOwner(),
            ),
          );
        } else {
          // Redirect to DashboardOwner if profile is complete
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardOwner(),
            ),
          );
        }
        return;
      }

      // Check user's role if not a salon owner
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final role = userData?['role'];

        if (role == 'client') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SalonhomepageClient(),
            ),
          );
        } else {
          setState(() {
            _loginError = 'Role not recognized. Please contact support.';
          });
        }
      } else {
        // If user document is not found, sign out
        await FirebaseAuth.instance.signOut();
        setState(() {
          _loginError = 'User not found. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = 'An unexpected error occurred. Please try again later.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateBasedOnRole(String uid) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      String role = userDoc['role'];

      if (role == 'client') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UserPreferencesPage(),
          ),
        );
      } else if (role == 'owner') {
        await _checkSalonDetails(uid);
      } else {
        setState(() {
          _loginError = 'An error occurred. Please try again.';
        });
      }
    } else {
      setState(() {
        _loginError = 'An error occurred. Please try again.';
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
        _loginError = 'An error occurred while loading your account.';
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
                      Icons.email,
                    ),
                    const SizedBox(height: 10),
                    buildTextField(
                      'Password',
                      _passwordController,
                      true,
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
      bool isPassword, IconData icon) {
    return SizedBox(
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
    );
  }
}
