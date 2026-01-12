import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _kIsDark = 'is_dark_theme';

  final ValueNotifier<ThemeData> themeNotifier =
      ValueNotifier<ThemeData>(_darkTheme);

  bool _isDark = true;

  bool get isDark => _isDark;

  /// Cargar preferencia al iniciar la app
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_kIsDark) ?? true;
    _applyTheme();
  }

  /// Cambiar tema
  Future<void> toggleTheme([bool? value]) async {
    _isDark = value ?? !_isDark;
    _applyTheme();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, _isDark);
  }

  void _applyTheme() {
    themeNotifier.value = _isDark ? _darkTheme : _lightTheme;
  }

  // ─────────────────────────────
  // THEMES DEFINITIVOS
  // ─────────────────────────────

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF1B1B1D),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1B1B1D),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blueAccent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
