import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

// This file defines the Riverpod providers for the authentication-related data and services. It connects the AuthService to Riverpod state and then the UI.
// This provider exposes the authentication service to the UI through the auth_service_provider so the rest of the app can access the authentication methods (e.g., sign in, sign out) without directly depending on the AuthService class, allowing for better separation of concerns and easier testing.
final auth_service_provider = Provider<AuthService>((ref) { // Provides an instance of the AuthService class. This allows the rest of the app to access authentication methods and listen to authentication state changes through this provider, without needing to directly instantiate or depend on the AuthService class in the UI code.
  return AuthService();
});

// This provider listens to the authentication state changes from the AuthService and exposes it to the UI as a StreamProvider so that the UI can reactively update whenever the user's authentication status changes (e.g., when they sign in or out).
// It provides the rest of the app with live updates on the user's authentication status, allowing the UI to show different screens or content based on whether the user is signed in or not.
final auth_state_provider = StreamProvider<User?>((ref) {
  final AuthService authService = ref.watch(auth_service_provider); // ref.watch: "get the auth service instance from the provider, so we can call methods on it to get the authentication state stream.""
  return authService.authStateChanges();
});
