// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> toggleThemeMode() async {
    final SharedPreferences preferences = ref.read(shared_preferences_provider);
    final ThemeMode nextThemeMode = state == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;

    state = nextThemeMode;
    await preferences.setBool(_isDarkModeKey, nextThemeMode == ThemeMode.dark);
  }
}

final theme_mode_provider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
