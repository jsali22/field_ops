import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

// Keeps auth access aligned with the same service -> provider -> UI structure
// used elsewhere in the app.
final auth_service_provider = Provider<AuthService>((ref) {
  return AuthService();
});

// AuthGate watches this stream so startup routing follows Firebase auth state.
final auth_state_provider = StreamProvider<User?>((ref) {
  final AuthService authService = ref.watch(auth_service_provider);
  return authService.authStateChanges();
});
