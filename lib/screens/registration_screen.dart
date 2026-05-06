import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_form_scaffold.dart';
import 'login_screen.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      await ref
          .read(auth_service_provider)
          .registerWithEmailPassword(email, password);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to create account.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while creating your account.'),
        ),
      );
    } finally {
      // Async auth calls can finish after navigation, so guard setState.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _backToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LoginScreen(),
      ),
    );
  }

  bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      appBarTitle: 'Create Account',
      title: 'Create your account',
      subtitle: 'Register with your email and password.',
      icon: Icons.person_add_alt_1_rounded,
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
