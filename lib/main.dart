import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/projects_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔥 Firebase initialized");

  // Temporary development bootstrap so Firestore paths always have a UID.
  final User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    final UserCredential credential = await FirebaseAuth.instance
        .signInAnonymously();
    print(
      '👤 No existing user found. Signed in anonymously as ${credential.user?.uid}.',
    );
  } else {
    print('👤 Existing Firebase user found: ${currentUser.uid}');
  }

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
      home: const ProjectsScreen(),
    );
  }
}
