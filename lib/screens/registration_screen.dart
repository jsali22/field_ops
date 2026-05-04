import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_form_scaffold.dart';
import 'login_screen.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  // ConsumerStatefulWidget is used to access Riverpod providers in a stateful widget
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState(); // Create the mutable state for the registration screen, which will handle user input and interactions related to creating a new account
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Key to identify the form and validate it
  final TextEditingController _emailController =
      TextEditingController(); // Controller to hold and manage the text input for the email field, allowing us to retrieve the email entered by the user when they submit the form
  final TextEditingController _passwordController =
      TextEditingController(); // Controller to hold and manage the text input for the password field
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Controller to hold and manage the text input for the confirm password field, allowing us to compare it with the password field to ensure they match before allowing registration

  bool _isLoading =
      false; // State variable to track if a registration operation is in progress, used to disable inputs and show a loading indicator while the registration process is happening

  @override
  void dispose() {
    // Dispose of the controllers (and their data) when the widget is removed from the widget tree to free up resources and prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      // Check if already loading or if form is not valid by calling validate() on the form key, which will run all the validators on the form fields and return true if they are all valid, or false if any field is invalid
      return;
    }

    setState(() {
      _isLoading =
          true; // Set loading state (local) to true to disable inputs and show a loading indicator while the registration operation is in progress
    });

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
      context,
    ); // Get the ScaffoldMessengerState to show SnackBars for user feedback (e.g., error messages if registration fails)
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // Attempt to register a new user using the auth service provider, and handle any exceptions that may occur during the registration process, providing user feedback based on the error message from FirebaseAuthException or a generic message for any other exceptions
    try {
      await ref
          .read(
            auth_service_provider,
          ) // Access the authentication service provider from Riverpod (going through the service layer to perform the registration operation, which allows for better separation of concerns and easier testing)
          .registerWithEmailPassword(email, password);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        // Check if the widget is still mounted before trying to show a SnackBar, to avoid calling setState or showing a SnackBar on a widget that has been disposed, which would cause an error
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to create account.')),
      );
    } catch (_) {
      if (!mounted) {
        // Check if the widget is still mounted before trying to show a SnackBar, to avoid calling setState or showing a SnackBar on a widget that has been disposed, which would cause an error
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while creating your account.'),
        ),
      );
    } finally {
      if (mounted) {
        // Check if the widget is still mounted before trying to update the state, to avoid calling setState on a widget that has been disposed, which would cause an error
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper function to navigate back to the login screen when the "Back to Sign In" button is pressed, which checks if we can pop the current route (i.e., go back) and if so, pops it to return to the previous screen (login), otherwise it pushes a new route to show the LoginScreen, ensuring that we return to the login screen regardless of how we got to the registration screen
  void _backToLogin() {
    if (Navigator.of(context).canPop()) {
      // Check if we can pop the current route (i.e., go back to the previous screen)
      Navigator.of(context).pop();
      return;
    }

    // If we can't pop (i.e., we're at the root), push a new route to show the LoginScreen, ensuring that we return to the login screen regardless of how we got to the registration screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginScreen(),
      ),
    );
  }

  // Helper function to check if a string looks like an email address by checking for the presence of '@' and '.' characters, used in the email field validator to provide basic validation for email input
  bool _looksLikeEmail(String value) {
    return value.contains('@') &&
        value.contains(
          '.',
        ); // Kept it simple to build screen and auth logic cleanly, this is not a comprehensive email validation but serves the purpose for basic validation in the form
  }

  // Build method to construct the UI of the registration screen, including a form with email, password, and confirm password fields, a button to create an account, and a button to navigate back to the login screen (currently showing a placeholder message)
  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      appBarTitle: 'Create Account',
      title: 'Create your account',
      subtitle: 'Register with your email and password.',
      icon: Icons.person_add_alt_1_rounded, // An icon that visually represents the registration action, adding some visual interest to the screen and helping users quickly identify the purpose of the form
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
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
              autofillHints: const <String>[AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Password'),
              textInputAction: TextInputAction.next,
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _backToLogin,
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
