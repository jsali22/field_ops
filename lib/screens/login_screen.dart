import 'package:firebase_auth/firebase_auth.dart'; // Importing so the UI can display better error messages when sign-in fails due to authentication issues (e.g., wrong password, user not found, etc.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget { // ConsumerStatefulWidge is used to access Riverpod providers in a stateful widget
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Key to identify the form and validate it
  // Controllers to hold and manage the text input for email and password fields
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController(); 

  bool _isLoading = false; // State variable to track if a sign-in operation is in progress, used to disable inputs and show a loading indicator

  // Dispose of the controllers (and their data) when the widget is removed from the widget tree to free up resources and prevent memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose(); // Call the superclass's dispose method to ensure any additional cleanup is performed
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) { // Check if already loading or if form is not valid by calling validate() on the form key
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state (local) to true to disable inputs and show a loading indicator while the sign-in operation is in progress
    });

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // Attempt to sign in using the auth service provider, and handle any exceptions that may occur during the sign-in process
    try {
      await ref
          .read(auth_service_provider) // Access the authentication service provider from Riverpod
          .signInWithEmailPassword(email, password); // Call the signInWithEmailPassword method on the auth service to attempt signing in with the provided email and password
    } on FirebaseAuthException catch (error) { // Catch specific FirebaseAuthException to handle authentication-related errors and provide user feedback based on the error message
      if (!mounted) {
        return;
      }

      messenger.showSnackBar( // Show a SnackBar with the error message from the FirebaseAuthException, or a generic message if the error message is null
        SnackBar(content: Text(error.message ?? 'Unable to sign in.')),
      );
    } catch (_) {
      if (!mounted) { // Check if the widget is still mounted before trying to show a SnackBar, to avoid calling setState or showing a SnackBar on a widget that has been disposed, which would cause an error
        return;
      }

      messenger.showSnackBar( // Show a generic SnackBar message for any other exceptions that may occur during the sign-in process, indicating that something went wrong
        const SnackBar(content: Text('Something went wrong while signing in.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Placeholder function to show a SnackBar indicating that the registration screen will be added in the next step, used as a temporary action for the "Create an account" button
  void _showRegistrationPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration screen will be added in the next step.'),
      ),
    );
  }

  // Helper function to check if a string looks like an email address by checking for the presence of '@' and '.' characters, used in the email field validator to provide basic validation for email input
  bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.'); // Kept it simple to build screen and auth logic cleanly
  }

  // Build method to construct the UI of the login screen, including a form with email and password fields, a sign-in button, and a button to navigate to the registration screen (currently showing a placeholder message)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
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
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : _showRegistrationPlaceholder,
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
