import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../widgets/auth_form_scaffold.dart';
import 'registration_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) {
      return;
    }

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    await _runAuthAction(
      action: () => ref
          .read(auth_service_provider)
          .signInWithEmailPassword(email, password),
      defaultErrorMessage: 'Something went wrong while signing in.',
    );
  }

  Future<void> _continueAsGuest() async {
    if (_isLoading) {
      return;
    }

    await _runAuthAction(
      action: () => ref.read(auth_service_provider).signInAnonymously(),
      defaultErrorMessage: 'Something went wrong while starting guest access.',
    );
  }

  Future<void> _runAuthAction({
    required Future<void> Function() action,
    required String defaultErrorMessage,
  }) async {
    setState(() {
      _isLoading = true;
    });

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await action();
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to sign in.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(defaultErrorMessage)));
    } finally {
      // Async auth calls can finish after navigation, so guard setState.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openRegistrationScreen() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const RegistrationScreen(),
      ),
    );
  }

  bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormScaffold(
      appBarTitle: 'Sign In',
      title: 'Welcome back',
      subtitle: 'Sign in with your email and password.',
      icon: Icons.login_rounded,
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
              autofillHints: const <String>[AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password'),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _continueAsGuest,
              child: const Text('Continue as Guest'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _openRegistrationScreen,
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
