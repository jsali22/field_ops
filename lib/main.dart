import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/theme_providers.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final SharedPreferences preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [shared_preferences_provider.overrideWithValue(preferences)],
      child: const FieldOpsApp(),
    ),
  );
}

class FieldOpsApp extends ConsumerWidget {
  const FieldOpsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(theme_mode_provider);

    return MaterialApp(
      title: 'FieldOps',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home:
          const AuthGate(), // The AuthGate widget listens to the authentication state and displays the appropriate screen based on whether the user is signed in or not.
    );
  }
}
