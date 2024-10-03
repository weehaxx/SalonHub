import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up user with email and password
  Future<String> signupUser(
      {required String email, required String password}) async {
    String res = 'Some error occurred';
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save the user's data in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'uid': credential.user!.uid,
      });

      res = 'Success';
    } catch (e) {
      print('Error occurred during signup: ${e.toString()}');
      res = e.toString();
    }
    return res;
  }

  // Google Sign-In function
  Future<String> signInWithGoogle() async {
    String res = 'Some error occurred';
    try {
      // Trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser != null) {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential for Firebase
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        // Check if user already exists in Firestore, else create a new entry
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // Save the user's data in Firestore
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'email': userCredential.user!.email,
            'uid': userCredential.user!.uid,
          });
        }

        res = 'Success';
      } else {
        res = 'Google sign-in cancelled by user';
      }
    } catch (e) {
      print('Error occurred during Google sign-in: ${e.toString()}');
      res = e.toString();
    }
    return res;
  }
}
