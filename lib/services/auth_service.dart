import 'package:firebase_auth/firebase_auth.dart';

// This class is the authentication service that will be used to handle all authentication related tasks.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance; // Allowing dependency injection (if an auth instance is provided for testing, use it; otherwise, use the default FirebaseAuth instance)

  final FirebaseAuth _auth; // The FirebaseAuth instance that will be used to perform authentication operations. (_ means file private)

  // A stream that emits the current user whenever the authentication state changes. This allows the app to react to changes in the user's authentication status (e.g., when they sign in or out).
  // Firebase emits an update whenever the user's authentication state changes, allowing the app to respond accordingly (e.g., by showing a login screen or the main app content).
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Method to sign in anonymously. This allows users to use the app without creating an account, but they will have limited functionality and their data may not be saved across sessions.
  Future<UserCredential> signInAnonymously() {
    return _auth.signInAnonymously();
  }

  // Method to sign in with an existing email and password. This allows users to create an account and sign in with their credentials. The method takes an email and password as parameters and returns a Future that resolves to a UserCredential object if the sign-in is successful.
  // Will be later used in the login screen to authenticate users with their email and password.
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Method to register a new user with an email and password. This allows users to create an account and sign in with their credentials. The method takes an email and password as parameters and returns a Future that resolves to a UserCredential object if the registration is successful.
  // Will be later used in the registration screen to create new user accounts.
  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Method to sign out the current user. This will end the user's session and update the authentication state, causing the app to react accordingly (e.g., by showing the login screen).
  Future<void> signOut() {
    return _auth.signOut();
  }
}
