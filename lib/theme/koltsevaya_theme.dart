import 'package:flutter/material.dart';

abstract final class KoltsevayaColors {
  static const background = Color(0xFF0B0907);
  static const panel = Color(0xFF120E0B);
  static const orange = Color(0xFFE8641B);
  static const amber = Color(0xFFFF9A3C);
  static const text = Color(0xFFE9DFD0);
  static const muted = Color(0xFF8C8174);
  static const border = Color(0x59E8641B);
}

abstract final class KoltsevayaTheme {
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: KoltsevayaColors.orange,
      onPrimary: KoltsevayaColors.background,
      secondary: KoltsevayaColors.amber,
      onSecondary: KoltsevayaColors.background,
      error: Color(0xFFFF6B5E),
      onError: KoltsevayaColors.background,
      surface: KoltsevayaColors.panel,
      onSurface: KoltsevayaColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: KoltsevayaColors.background,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: KoltsevayaColors.text, height: 1.5),
        bodyMedium: TextStyle(color: KoltsevayaColors.text, height: 1.45),
        bodySmall: TextStyle(color: KoltsevayaColors.muted, height: 1.4),
        titleLarge: TextStyle(
          color: KoltsevayaColors.text,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        titleMedium: TextStyle(
          color: KoltsevayaColors.text,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: KoltsevayaColors.text,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: KoltsevayaColors.background,
        foregroundColor: KoltsevayaColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: KoltsevayaColors.text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: KoltsevayaColors.panel,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: KoltsevayaColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KoltsevayaColors.panel,
        labelStyle: const TextStyle(color: KoltsevayaColors.muted),
        hintStyle: const TextStyle(color: KoltsevayaColors.muted),
        prefixIconColor: KoltsevayaColors.muted,
        suffixIconColor: KoltsevayaColors.muted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KoltsevayaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: KoltsevayaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: KoltsevayaColors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B5E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B5E), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KoltsevayaColors.orange,
          foregroundColor: KoltsevayaColors.background,
          disabledBackgroundColor:
              KoltsevayaColors.orange.withValues(alpha: .4),
          disabledForegroundColor: KoltsevayaColors.text,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KoltsevayaColors.amber,
          side: const BorderSide(color: KoltsevayaColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KoltsevayaColors.amber,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KoltsevayaColors.orange,
        foregroundColor: KoltsevayaColors.background,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: KoltsevayaColors.panel,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: KoltsevayaColors.border,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KoltsevayaColors.panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: KoltsevayaColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF241A13),
        contentTextStyle: const TextStyle(color: KoltsevayaColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KoltsevayaColors.orange,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: KoltsevayaColors.muted,
        textColor: KoltsevayaColors.text,
        selectedColor: KoltsevayaColors.amber,
        selectedTileColor: Color(0x1AE8641B),
      ),
    );
  }
}
