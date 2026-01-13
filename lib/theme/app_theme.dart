import 'package:flutter/material.dart';

class AppTheme {
  // New Color Palette - Based on Splash Screen Gradient
  // Gradient Colors
  static const Color gradientBlueTop = Color(0xFF6EC1E4); // Light blue from splash
  static const Color gradientBlueMid = Color(0xFF9BA8E8); // Purple-blue transition
  static const Color gradientPinkBottom = Color(0xFFE8A8D8); // Pink from splash
  
  // Primary Colors
  static const Color primaryPurple = Color(0xFF8B5CF6); // Purple for "Level UP!" text
  static const Color primaryYellow = Color(0xFFFBD38D); // Yellow/gold accents
  static const Color primaryWhite = Color(0xFFFFFFFF); // White text
  
  // Accent Colors
  static const Color accentGold = Color(0xFFFBBF24); // Bright yellow for buttons
  static const Color accentLightPurple = Color(0xFFC4B5FD); // Light purple
  static const Color accentPink = Color(0xFFF9A8D4); // Light pink
  
  // Neutral Colors
  static const Color white = Colors.white;
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);

  // Text Styles with new color scheme
  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.5,
      color: primaryPurple,
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
        primary: primaryPurple,
        onPrimary: white,
        secondary: accentGold,
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
          foregroundColor: primaryPurple,
          side: const BorderSide(color: primaryPurple, width: 2),
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
          borderSide: const BorderSide(color: primaryPurple, width: 2),
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
