// auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Register with email and password
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update display name after registration
      await credential.user?.updateDisplayName(displayName);
      // Send email verification
      await credential.user?.sendEmailVerification();
      return credential;
    } on FirebaseAuthException catch (e) {
      // Handle specific errors
      switch (e.code) {
        case 'weak-password':
          throw AuthException('Password must be at least 6 characters');
        case 'email-already-in-use':
          throw AuthException('An account with this email already exists');
        case 'invalid-email':
          throw AuthException('Please enter a valid email address');
        default:
          throw AuthException('Registration failed: ${e.message}');
      }
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
        await FirebaseCrashlytics.instance.setCustomKey('plan', 'premium');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw AuthException('No account found with this email');
        case 'wrong-password':
          throw AuthException('Incorrect password');
        case 'user-disabled':
          throw AuthException('This account has been disabled');
        case 'too-many-requests':
          throw AuthException('Too many attempts. Try again later');
        default:
          throw AuthException('Sign in failed: ${e.message}');
      }
    }
  }

  // Password reset
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

// Custom exception for clean error handling in UI
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}