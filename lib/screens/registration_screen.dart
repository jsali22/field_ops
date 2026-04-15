import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class RegistrationScreen extends ConsumerStatefulWidget { // ConsumerStatefulWidget is used to access Riverpod providers in a stateful widget
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState(); // Create the mutable state for the registration screen, which will handle user input and interactions related to creating a new account
}
class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Key to identify the form and validate it
  final TextEditingController _emailController = TextEditingController(); // Controller to hold and manage the text input for the email field, allowing us to retrieve the email entered by the user when they submit the form
  final TextEditingController _passwordController = TextEditingController(); // Controller to hold and manage the text input for the password field
  final TextEditingController _confirmPasswordController =
      TextEditingController(); // Controller to hold and manage the text input for the confirm password field, allowing us to compare it with the password field to ensure they match before allowing registration

  bool _isLoading = false; // State variable to track if a registration operation is in progress, used to disable inputs and show a loading indicator while the registration process is happening

  @override
  void dispose() { // Dispose of the controllers (and their data) when the widget is removed from the widget tree to free up resources and prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) { // Check if already loading or if form is not valid by calling validate() on the form key, which will run all the validators on the form fields and return true if they are all valid, or false if any field is invalid
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state (local) to true to disable inputs and show a loading indicator while the registration operation is in progress
    });

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context); // Get the ScaffoldMessengerState to show SnackBars for user feedback (e.g., error messages if registration fails)
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    // Attempt to register a new user using the auth service provider, and handle any exceptions that may occur during the registration process, providing user feedback based on the error message from FirebaseAuthException or a generic message for any other exceptions
    try {
      await ref
          .read(auth_service_provider) // Access the authentication service provider from Riverpod (going through the service layer to perform the registration operation, which allows for better separation of concerns and easier testing)
          .registerWithEmailPassword(email, password);
    } on FirebaseAuthException catch (error) {
      if (!mounted) { // Check if the widget is still mounted before trying to show a SnackBar, to avoid calling setState or showing a SnackBar on a widget that has been disposed, which would cause an error
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to create account.')),
      );
    } catch (_) {
      if (!mounted) { // Check if the widget is still mounted before trying to show a SnackBar, to avoid calling setState or showing a SnackBar on a widget that has been disposed, which would cause an error
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while creating your account.'),
        ),
      );
    } finally {
      if (mounted) { // Check if the widget is still mounted before trying to update the state, to avoid calling setState on a widget that has been disposed, which would cause an error
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  // Placeholder function to show a SnackBar indicating that the login screen will be added in the next step, used as a temporary action for the "Back to Sign In" button
  void _showLoginPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login screen navigation will be added later.'),
      ),
    );
  }
  // Helper function to check if a string looks like an email address by checking for the presence of '@' and '.' characters, used in the email field validator to provide basic validation for email input
  bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.'); // Kept it simple to build screen and auth logic cleanly, this is not a comprehensive email validation but serves the purpose for basic validation in the form
  }

  // Build method to construct the UI of the registration screen, including a form with email, password, and confirm password fields, a button to create an account, and a button to navigate back to the login screen (currently showing a placeholder message)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
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
                          'Create your account',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register with your email and password.',
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
                          autofillHints: const <String>[
                            AutofillHints.newPassword,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                          ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create Account'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isLoading ? null : _showLoginPlaceholder,
                          child: const Text('Back to Sign In'),
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
