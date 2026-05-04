import 'package:flutter/material.dart';

import 'theme_mode_toggle_button.dart';

// This widget serves as a reusable scaffold for authentication forms (e.g., login, registration). It provides a consistent layout with an app bar, title, subtitle, and a child widget for the form content.
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.appBarTitle,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.lock_outline, // A default icon that represents authentication, which can be overridden by specific forms (e.g., registration screen uses a different icon). This adds some visual interest to the form and helps users quickly identify the purpose of the screen.
  });

  final String appBarTitle;
  final String title;
  final String subtitle;
  final Widget child;
  final IconData icon;

  // The build method constructs the UI of the scaffold, including the app bar with a theme toggle button, and a centered card containing the title, subtitle, and form content. The layout is responsive and adapts to different screen sizes.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: const <Widget>[ThemeModeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Ensures the content is scrollable on smaller screens, preventing overflow issues.
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon( // An icon that visually represents the authentication form, adding some visual interest to the screen and helping users quickly identify the purpose of the form.
                        icon,
                        size: 34,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      child,
                    ],
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
