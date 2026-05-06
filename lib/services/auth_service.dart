import 'package:firebase_auth/firebase_auth.dart';

// Thin wrapper around FirebaseAuth so the UI can go through one service layer.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // AuthGate listens to this stream to swap between signed-out and signed-in UI.
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // The remaining methods stay close to FirebaseAuth so later UI and provider
  // layers can handle auth errors without extra translation logic.
  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
