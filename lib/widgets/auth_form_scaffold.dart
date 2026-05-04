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
  });

  final String appBarTitle;
  final String title;
  final String subtitle;
  final Widget child;

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
          child: SingleChildScrollView( // Ensures the content is scrollable on smaller screens, preventing overflow issues.
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
