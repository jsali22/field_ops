// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This file defines the theme providers for the application, including a provider for SharedPreferences and a NotifierProvider for managing the app's ThemeMode (light or dark). 
// The ThemeModeNotifier handles toggling between themes and persists the user's preference using SharedPreferences.

// Provider for SharedPreferences, which allows the app to read and write user preferences related to theme settings.
final shared_preferences_provider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided at startup.');
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const String _isDarkModeKey = 'isDarkMode';

  @override
  ThemeMode build() {
    final SharedPreferences preferences = ref.watch(
      shared_preferences_provider,
    );
    final bool isDarkMode = preferences.getBool(_isDarkModeKey) ?? false;
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // This method toggles the theme mode between light and dark. It updates the state of the ThemeModeNotifier and persists the new theme preference in SharedPreferences.
  Future<void> toggleThemeMode() async {
    final SharedPreferences preferences = ref.read(shared_preferences_provider); // Value (the theme mode) is persisted locally using SharedPreferences, so we read it directly without watching for changes.
    final ThemeMode nextThemeMode = state == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    state = nextThemeMode;
    await preferences.setBool(_isDarkModeKey, nextThemeMode == ThemeMode.dark);
  }
}

// NotifierProvider for managing the ThemeMode state across the application. It allows widgets to listen for changes in the theme mode and rebuild accordingly when the user toggles between light and dark themes.
final theme_mode_provider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
