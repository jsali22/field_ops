import 'package:flutter/material.dart';

// This class defines the application's light and dark themes, including color schemes, text styles, and component themes.
class AppTheme {
  static ThemeData light() { // widgets inherit using Theme.of(context) and automatically update when the theme changes, ensuring a consistent look and feel across the app.
    return _buildTheme(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF234A66),
        onPrimary: Colors.white,
        secondary: Color(0xFF6D8A8F),
        onSecondary: Colors.white,
        error: Color(0xFFB3261E),
        onError: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF17212B),
        outline: Color(0xFFD2DAE3),
        outlineVariant: Color(0xFFE3E8EE),
        shadow: Color(0x14000000),
        scrim: Color(0x66000000),
        inverseSurface: Color(0xFF2B3440),
        onInverseSurface: Colors.white,
        inversePrimary: Color(0xFF8FB7D4),
        tertiary: Color(0xFF4D6C77),
        onTertiary: Colors.white,
        surfaceContainerHighest: Color(0xFFE7ECF0),
      ),
      scaffoldBackgroundColor: const Color(0xFFF3F5F7),
      textPrimary: const Color(0xFF17212B),
      textSecondary: const Color(0xFF5C6876),
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF8FB7D4),
        onPrimary: Color(0xFF102636),
        secondary: Color(0xFF9CB7BC),
        onSecondary: Color(0xFF173036),
        error: Color(0xFFF2B8B5),
        onError: Color(0xFF601410),
        surface: Color(0xFF182028),
        onSurface: Color(0xFFE7EDF3),
        outline: Color(0xFF3A4655),
        outlineVariant: Color(0xFF2B3642),
        shadow: Color(0x33000000),
        scrim: Color(0x99000000),
        inverseSurface: Color(0xFFE7EDF3),
        onInverseSurface: Color(0xFF182028),
        inversePrimary: Color(0xFF234A66),
        tertiary: Color(0xFF88A9B4),
        onTertiary: Color(0xFF112C36),
        surfaceContainerHighest: Color(0xFF263240),
      ),
      scaffoldBackgroundColor: const Color(0xFF11161B),
      textPrimary: const Color(0xFFE7EDF3),
      textSecondary: const Color(0xFFA5B1BE),
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    // Start with a base theme generated from the color scheme, then customize it with specific component themes and text styles.
    final ThemeData baseTheme = ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
    );

    // Build a custom text theme based on the base theme's text styles, applying the specified primary and secondary text colors.
    final TextTheme textTheme = _buildTextTheme(
      baseTextTheme: baseTheme.textTheme,
      brightness: colorScheme.brightness,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
    );

    // Return a copy of the base theme with customized properties for scaffold background, card color, text themes, and various component themes (AppBar, Card, InputDecoration, Buttons, etc.) to create a cohesive look and feel across the app.
    return baseTheme.copyWith(
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardColor: colorScheme.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.38),
          disabledForegroundColor: colorScheme.onPrimary.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      listTileTheme: ListTileThemeData(
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium,
      ),
      dividerColor: colorScheme.outlineVariant,
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.bodyLarge,
      ),
    );
  }

  // This method builds a custom TextTheme based on the provided base TextTheme and applies specific styles for different text categories (headline, title, body, label) using the primary and secondary text colors.
  static TextTheme _buildTextTheme({
    required TextTheme baseTextTheme,
    required Brightness brightness,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final TextTheme themedBaseTextTheme = baseTextTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
      decorationColor: textPrimary,
    );

    return themedBaseTextTheme.copyWith(
      headlineSmall: themedBaseTextTheme.headlineSmall?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.4,
      ),
      titleLarge: themedBaseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: themedBaseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: themedBaseTextTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.45,
        color: textPrimary,
      ),
      bodyMedium: themedBaseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
        color: textSecondary,
      ),
      bodySmall: themedBaseTextTheme.bodySmall?.copyWith(color: textSecondary),
      labelLarge: themedBaseTextTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      labelMedium: themedBaseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
    );
  }
}
