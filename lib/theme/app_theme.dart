import 'package:flutter/material.dart';

class AppTheme {
  // Yellow Color Palette - Based on #f4ef8b
  // Gradient Colors
  static const Color gradientYellowTop = Color(0xFFFFF9E6); // Very light yellow
  static const Color gradientYellowMid = Color(0xFFF4EF8B); // Main yellow #f4ef8b
  static const Color gradientYellowBottom = Color(0xFFE8D96F); // Slightly darker yellow
  
  // Primary Colors
  static const Color primaryYellow = Color(0xFFF4EF8B); // Main yellow #f4ef8b
  static const Color primaryYellowDark = Color(0xFFE8D96F); // Darker yellow for contrast
  static const Color primaryWhite = Color(0xFFFFFFFF); // White text
  
  // Accent Colors
  static const Color accentGold = Color(0xFFF4EF8B); // Yellow for buttons
  static const Color accentLightYellow = Color(0xFFFFFBD6); // Very light yellow
  static const Color accentAmber = Color(0xFFFFC107); // Amber accent
  
  // Neutral Colors
  static const Color white = Colors.white;
  static const Color lightBackground = Color(0xFFFFFDF5);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);

  // Text Styles with new color scheme
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      color: textDark,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: primaryWhite,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textDark,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: textDark,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: textLight,
    ),
    labelLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: textDark, 
    ),
  );

  // Main Theme Data
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryYellow,
        onPrimary: textDark,
        secondary: accentAmber,
        onSecondary: textDark,
        error: Color(0xFFEF4444),
        onError: white,
        surface: white,
        onSurface: textDark,
      ),
      fontFamily: 'Roboto',
      textTheme: textTheme,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
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
          foregroundColor: textDark,
          side: const BorderSide(color: primaryYellowDark, width: 2),
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
          borderSide: const BorderSide(color: primaryYellowDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        labelStyle: const TextStyle(color: textLight),
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
        backgroundColor: accentGold,
        foregroundColor: textDark,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: textDark,
      ),
    );
  }
}
