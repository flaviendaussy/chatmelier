import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF8B1E3F);
  static const secondaryColor = Color(0xFFC9A84C);
  static const surfaceColor = Color(0xFFFAF7F2);
  static const backgroundColor = Color(0xFFF5F0E8);

  static ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      onPrimary: Colors.white,
      secondary: secondaryColor,
      surface: surfaceColor,
    );

    return ThemeData(
      colorScheme: baseColorScheme,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(),
        bodyLarge: GoogleFonts.inter(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    const darkPrimary = Color(0xFF9E2A2B);
    final baseColorScheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: darkPrimary,
      primary: darkPrimary,
      onPrimary: Colors.white,
      secondary: secondaryColor,
    );

    return ThemeData(
      colorScheme: baseColorScheme,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(),
        bodyLarge: GoogleFonts.inter(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      useMaterial3: true,
    );
  }
}
