import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔥 Firebase initialized");

  runApp(const ProviderScope(child: FieldOpsApp()));
}

class FieldOpsApp extends StatelessWidget {
  const FieldOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldOps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(), // The AuthGate widget listens to the authentication state and displays the appropriate screen based on whether the user is signed in or not.
    );
  }
}
