import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'login_screen.dart';
import 'projects_screen.dart';

// Startup routing stays simple here: signed-out users see auth UI, and
// signed-in users go straight to their projects.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<User?> authState = ref.watch(auth_state_provider);

    // AsyncValue.when keeps startup auth states explicit: loading, error, or a
    // real signed-in/signed-out result.
    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking your session...'),
              ],
            ),
          ),
        ),
      ),
      error: (Object error, StackTrace stackTrace) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.error_outline, size: 48),
                SizedBox(height: 16),
                Text('We could not verify your sign-in state.'),
                SizedBox(height: 8),
                Text(
                  'Please restart the app and try again.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      data: (User? user) {
        if (user == null) {
          return const LoginScreen();
        }

        return const ProjectsScreen();
      },
    );
  }
}
