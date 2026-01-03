import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  // Color Palette - Rebranded
  static const Color creamBackground = Color(0xFFF1ECE6);
  static const Color primaryBlue = Color(0xFF2A2B2D); // Charcoal
  static const Color accentTeal = Color(0xFFDDF487); // Lime
  static const Color accentCoral = Color(0xFF790000); // Wine Red
  static const Color accentYellow = Color(0xFFF4D394); // Gold
  static const Color accentLightBlue = Color(0xFFB5D8FF);
  
  static const Color neutralGrey = Color(0xFF9E9E9E);
  static const Color white = Colors.white;

  // Additional Interactive Colors
  static const Color secondaryPink = Color(0xFFE4839D);
  static const Color secondaryLilac = Color(0xFFEDC3F6);

  // Text Styles using Raleway for headings and Montserrat for body
  // Text Styles using Raleway for headings and Montserrat for body
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900, // black
      letterSpacing: -0.5,
      color: primaryBlue,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800, // bold
      color: primaryBlue,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: primaryBlue,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: primaryBlue,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: primaryBlue,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: primaryBlue,
    ),
    labelLarge: TextStyle( // Buttons
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: primaryBlue, 
    ),
  );

  // Main Theme Data
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: creamBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryBlue,
        onPrimary: white,
        secondary: accentTeal,
        onSecondary: primaryBlue,
        error: accentCoral,
        onError: white,
        surface: creamBackground,
        onSurface: primaryBlue,
      ),
      fontFamily: 'Roboto',
      textTheme: textTheme,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: creamBackground,
        foregroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryBlue,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: IconThemeData(color: primaryBlue),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow, // Default to yellow button like "Start"
          foregroundColor: primaryBlue,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Pill shape
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'Roboto',
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      // Input Decoration (Rounded)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        labelStyle: TextStyle(color: primaryBlue.withOpacity(0.7)),
      ),

      // Card Theme
      // Card Theme
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentTeal,
        foregroundColor: primaryBlue,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryBlue,
      ),
    );
  }
}
