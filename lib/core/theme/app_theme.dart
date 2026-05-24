import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color darkCanvas = Color(0xFF0C0B18);
  static const Color darkCanvasEnd = Color(0xFF15112B);
  static const Color darkPrimary = Color(0xFF7C3AED); // Radiant Violet
  static const Color darkSecondary = Color(0xFF3B82F6); // Ocean Blue
  static const Color darkCard = Color(0x1FFFFFFF); // Glass white (12%)
  static const Color darkCardBorder = Color(0x1BFFFFFF); // Glass border (10%)
  static const Color darkText = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  static const Color lightCanvas = Color(0xFFF9FAFB);
  static const Color lightCanvasEnd = Color(0xFFF3F4F6);
  static const Color lightPrimary = Color(0xFF6D28D9);
  static const Color lightSecondary = Color(0xFF2563EB);
  static const Color lightCard = Color(0xE6FFFFFF); // Glass light
  static const Color lightCardBorder = Color(0x1F000000);
  static const Color lightText = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);

  // Gradient configurations
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkCanvas, darkCanvasEnd],
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightCanvas, lightCanvasEnd],
  );

  static LinearGradient brandGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkPrimary, darkSecondary],
  );

  // Glassmorphic Card decoration
  static BoxDecoration glassDecoration({
    required bool isDark,
    double borderRadius = 16.0,
    double borderOpacity = 0.1,
  }) {
    return BoxDecoration(
      color: isDark ? darkCard : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(borderOpacity)
            : Colors.black.withOpacity(borderOpacity),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Get ThemeData
  static ThemeData getThemeData(bool isDark, double baseFontSize) {
    final textTheme = isDark ? _darkTextTheme(baseFontSize) : _lightTextTheme(baseFontSize);
    final primaryColor = isDark ? darkPrimary : lightPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.transparent, // Background will render via Gradient Scaffold
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primaryColor,
        secondary: isDark ? darkSecondary : lightSecondary,
        surface: isDark ? Colors.transparent : lightCanvas,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: isDark ? darkText : lightText),
      ),
    );
  }

  static TextTheme _darkTextTheme(double baseSize) {
    return GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: baseSize * 2.2, fontWeight: FontWeight.bold, color: darkText),
      titleLarge: GoogleFonts.outfit(fontSize: baseSize * 1.25, fontWeight: FontWeight.w600, color: darkText),
      bodyLarge: GoogleFonts.outfit(fontSize: baseSize, fontWeight: FontWeight.normal, color: darkText),
      bodyMedium: GoogleFonts.outfit(fontSize: baseSize * 0.875, color: darkTextSecondary),
      labelLarge: GoogleFonts.outfit(fontSize: baseSize * 0.875, fontWeight: FontWeight.w500, color: darkText),
    );
  }

  static TextTheme _lightTextTheme(double baseSize) {
    return GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.outfit(fontSize: baseSize * 2.2, fontWeight: FontWeight.bold, color: lightText),
      titleLarge: GoogleFonts.outfit(fontSize: baseSize * 1.25, fontWeight: FontWeight.w600, color: lightText),
      bodyLarge: GoogleFonts.outfit(fontSize: baseSize, fontWeight: FontWeight.normal, color: lightText),
      bodyMedium: GoogleFonts.outfit(fontSize: baseSize * 0.875, color: lightTextSecondary),
      labelLarge: GoogleFonts.outfit(fontSize: baseSize * 0.875, fontWeight: FontWeight.w500, color: lightText),
    );
  }
}
