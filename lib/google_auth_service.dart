// google_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // User cancelled the sign-in
      if (googleUser == null) return null;

      // Get auth details from the Google Sign-In
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a Firebase credential from Google tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
        await FirebaseCrashlytics.instance.setCustomKey('plan', 'premium');
      }

      // First time sign-in? Create user profile in Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createUserProfile(userCredential.user!);
      }
      return userCredential;
    } catch (e, stackTrace) {
      await FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Google sign-in failed',
      );
      throw AuthException('Google sign-in failed: $e');
    }
  }

  Future<void> _createUserProfile(User user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}