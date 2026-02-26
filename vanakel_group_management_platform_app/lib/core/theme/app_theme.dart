import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color brandBlack = Color(0xFF0a0a0a);
  static const Color brandGreen = Color(0xFF22c55e);
  static const Color brandOrange = Color(0xFFf97316);

  // Zinc Palette (Neutrals)
  static const Color zinc950 = Color(0xFF09090b);
  static const Color zinc900 = Color(0xFF18181b);
  static const Color zinc800 = Color(0xFF27272a);
  static const Color zinc500 = Color(0xFF71717a);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc300 = Color(0xFFd4d4d8);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: brandBlack,
    primaryColor: brandGreen,
    
    colorScheme: const ColorScheme.dark(
      primary: brandGreen,
      secondary: brandGreen,
      surface: zinc950,
      background: brandBlack,
      error: brandOrange,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: zinc300,
      onBackground: zinc300,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: zinc900,
      foregroundColor: zinc300,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),

    cardTheme: CardThemeData(
      color: zinc950,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: zinc800),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: zinc900,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: zinc800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: zinc800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: brandGreen),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: brandOrange),
      ),
      hintStyle: const TextStyle(color: zinc500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brandGreen,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: zinc300,
        side: const BorderSide(color: zinc800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: zinc300, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: zinc300, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: zinc300, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: zinc300, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: zinc300, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: zinc300, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: zinc300, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: zinc300, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: zinc300, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: zinc300),
      bodyMedium: TextStyle(color: zinc300),
      bodySmall: TextStyle(color: zinc500),
      labelLarge: TextStyle(color: zinc300, fontWeight: FontWeight.w600),
    ),

    dividerTheme: const DividerThemeData(
      color: zinc800,
      thickness: 1,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: zinc950,
      selectedItemColor: brandGreen,
      unselectedItemColor: zinc500,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 0,
    ),
  );
}
