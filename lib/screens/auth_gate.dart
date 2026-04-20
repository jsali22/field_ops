import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'login_screen.dart';
import 'projects_screen.dart';


// A widget that listens to the authentication state and displays the appropriate screen based on whether the user is signed in or not.
class AuthGate extends ConsumerWidget { // ConsumerWidget is a widget that can read providers. It is used to listen to the authentication state and display the appropriate screen based on whether the user is signed in or not.
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<User?> authState = ref.watch(auth_state_provider); // watch the authentication state provider to get the current authentication state. The provider returns an AsyncValue, which can be in one of three states: loading, error, or data. We use the when method to handle each of these states and return the appropriate screen.

    return authState.when( // handle the three states of the authentication state provider: loading, error, and data.
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Unable to determine authentication state.'),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
      data: (User? user) { // handle the data state, which contains the current authentication state.
        if (user == null) {
          return const LoginScreen();
        }

        return const ProjectsScreen();
      },
    );
  }
}
