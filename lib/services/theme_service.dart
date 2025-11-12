import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Globální téma pro jednoduchost
ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);

class ThemeService {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  bool _isDarkMode = false;
  final ValueNotifier<bool> darkModeNotifier = ValueNotifier<bool>(false);

  bool get isDarkMode => _isDarkMode;

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    darkModeNotifier.value = _isDarkMode;
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    darkModeNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  // Světlé téma - bílé s šedými stíny a zeleným AppBarem
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3E5F44)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3E5F44), // Tmavě zelená
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF3E5F44), // Tmavě zelená pro aktivní ikony
      unselectedItemColor: Colors.grey,
      elevation: 8,
    ),
    // Přidání indicatoru pro aktivní záložku
    tabBarTheme: const TabBarThemeData(
      indicatorColor: Color(0xFF3E5F44),
      labelColor: Color(0xFF3E5F44),
      unselectedLabelColor: Colors.grey,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.grey),
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.black87),
      titleSmall: TextStyle(color: Colors.grey),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF5E936C), // Světlejší zelená pro ikony
    ),
    dividerColor: const Color(0xFF5E936C), // Světlejší zelená pro separátory
  );

    // Tmavé téma - zelené barvy s tmavým pozadím
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Tmavě šedé pozadí
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF3E5F44),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3E5F44), // Tmavě zelená
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF2D2D2D), // Tmavě šedé karty
      elevation: 2,
      shadowColor: Colors.black54,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF3E5F44),
        foregroundColor: Colors.white,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2D2D2D),
      selectedItemColor: Color(0xFF3E5F44), // Tmavě zelená pro aktivní ikony
      unselectedItemColor: Colors.grey,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFE0E0E0)),
      bodySmall: TextStyle(color: Colors.grey),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Color(0xFFE0E0E0)),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF5E936C), // Světlejší zelená pro ikony
    ),
    dividerColor: const Color(0xFF5E936C), // Světlejší zelená pro separátory
  );
}