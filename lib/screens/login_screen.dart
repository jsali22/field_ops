import 'package:firebase_auth/firebase_auth.dart'; // Importing so the UI can display better error messages when sign-in fails due to authentication issues (e.g., wrong password, user not found, etc.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/theme_mode_toggle_button.dart';
import 'registration_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  // ConsumerStatefulWidge is used to access Riverpod providers in a stateful widget
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Key to identify the form and validate it
  // Controllers to hold and manage the text input for email and password fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading =
      false; // State variable to track if a sign-in operation is in progress, used to disable inputs and show a loading indicator

  // Dispose of the controllers (and their data) when the widget is removed from the widget tree to free up resources and prevent memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super
        .dispose(); // Call the superclass's dispose method to ensure any additional cleanup is performed
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      // Check if already loading or if form is not valid by calling validate() on the form key
      return;
    }

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    await _runAuthAction(
      action: () => ref
          .read(
            // .read is used to read the current value of a provider without listening to it for changes, which is appropriate here because we just want to call a method on the auth service and don't need to rebuild the UI when the auth state changes
            auth_service_provider,
          ) // Access the authentication service provider from Riverpod
          .signInWithEmailPassword(
            email,
            password,
          ), // Call the signInWithEmailPassword method on the auth service to attempt signing in with the provided email and password
      defaultErrorMessage: 'Something went wrong while signing in.',
    );
  }

  Future<void> _continueAsGuest() async {
    // Function to handle the "Continue as Guest" button press, which attempts to sign in anonymously using the auth service provider, and handles any exceptions that may occur during the sign-in process
    if (_isLoading) {
      // Check if already loading to prevent multiple sign-in attempts at the same time, which could cause unexpected behavior or errors
      return;
    }

    await _runAuthAction(
      action: () => ref
          .read(auth_service_provider)
          .signInAnonymously(), // Call the signInAnonymously method on the auth service to attempt signing in anonymously, allowing users to use the app without creating an account
      defaultErrorMessage:
          'Something went wrong while starting guest access.', // Provide a default error message for any exceptions that may occur during the anonymous sign-in process, which will be shown in a SnackBar if an error occurs
    );
  }

  Future<void> _runAuthAction({
    // Helper function to run an authentication action (e.g., sign in, sign in anonymously) and handle loading state and error handling in a consistent way across different authentication actions (e.g., sign in with email/password, and sign in anonymously)
    required Future<void> Function()
    action, // The authentication action to perform, passed as a function that returns a Future (e.g., the sign-in method from the auth service)
    required String
    defaultErrorMessage, // A default error message to show in case of any exceptions that may occur during the authentication process, used for exceptions that are not FirebaseAuthExceptions or when the error message from FirebaseAuthException is null
  }) async {
    setState(() {
      _isLoading =
          true; // Set loading state (local) to true to disable inputs and show a loading indicator while the sign-in operation is in progress
    });

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await action();
    } on FirebaseAuthException catch (error) {
      // Catch specific FirebaseAuthException to handle authentication-related errors and provide user feedback based on the error message
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        // Show a SnackBar with the error message from the FirebaseAuthException, or a generic message if the error message is null
        SnackBar(content: Text(error.message ?? 'Unable to sign in.')),
      );
    } catch (_) {
      if (!mounted) {
        // Check if the widget is still mounted before trying to show a SnackBar, to avoid calling setState or showing a SnackBar on a widget that has been disposed, which would cause an error
        return;
      }

      messenger.showSnackBar(
        // Show a generic SnackBar message for any other exceptions that may occur during the sign-in process, indicating that something went wrong
        SnackBar(content: Text(defaultErrorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper function to navigate to the registration screen when the "Create an account" button is pressed, which pushes a new route onto the navigation stack to show the RegistrationScreen, allowing users to create a new account if they don't have one
  Future<void> _openRegistrationScreen() {
    return Navigator.of(context).push(
      // Use Navigator to push a new route onto the navigation stack, which will display the RegistrationScreen when the "Create an account" button is pressed
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const RegistrationScreen(),
      ),
    );
  }

  // Helper function to check if a string looks like an email address by checking for the presence of '@' and '.' characters, used in the email field validator to provide basic validation for email input
  bool _looksLikeEmail(String value) {
    return value.contains('@') &&
        value.contains(
          '.',
        ); // Kept it simple to build screen and auth logic cleanly
  }

  // Build method to construct the UI of the login screen, including a form with email and password fields, a sign-in button, and a button to navigate to the registration screen (currently showing a placeholder message)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        actions: const <Widget>[ThemeModeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in with your email and password.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email'),
                          textInputAction: TextInputAction.next,
                          validator: (String? value) {
                            final String email = value?.trim() ?? '';
                            if (email.isEmpty) {
                              return 'Email is required';
                            }
                            if (!_looksLikeEmail(email)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          autofillHints: const <String>[AutofillHints.password],
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          // Button to allow users to continue as a guest by signing in anonymously, which will give them limited access to the app without creating an account
                          onPressed: _isLoading ? null : _continueAsGuest,
                          child: const Text('Continue as Guest'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : _openRegistrationScreen,
                          child: const Text('Create an account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
