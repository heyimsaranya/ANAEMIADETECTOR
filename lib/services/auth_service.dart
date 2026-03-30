import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign-In (works for Flutter Web)
  static Future<User?> signInWithGoogle() async {

    final GoogleAuthProvider googleProvider = GoogleAuthProvider();

    final UserCredential userCredential =
        await _auth.signInWithPopup(googleProvider);

    return userCredential.user;
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}