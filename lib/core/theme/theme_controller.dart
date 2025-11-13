import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._private();

  static final ThemeController instance = ThemeController._private();

  final ValueNotifier<ThemeData> themeNotifier = ValueNotifier(_buildDefaultTheme());

  static const _kIsDark = 'theme_is_dark';
  static const _kPrimary = 'theme_primary';
  static const _kBackground = 'theme_background';
  static const _kPreset = 'theme_preset';

  bool isDark = true;
  Color primary = Colors.blueAccent;
  Color background = const Color(0xFF1B1B1D);
  String? currentPreset;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    isDark = prefs.getBool(_kIsDark) ?? true;
    final primaryHex = prefs.getInt(_kPrimary);
    final bgHex = prefs.getInt(_kBackground);
    currentPreset = prefs.getString(_kPreset);

    if (primaryHex != null) primary = Color(primaryHex);
    if (bgHex != null) background = Color(bgHex);

    if (!isDark && _isDarkColor(background)) background = Colors.white;
    if (isDark && !_isDarkColor(background)) background = const Color(0xFF1B1B1D);

    themeNotifier.value = _buildTheme(isDark: isDark, primary: primary, background: background);
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDark, isDark);
    await prefs.setInt(_kPrimary, primary.value);
    await prefs.setInt(_kBackground, background.value);
    if (currentPreset != null) {
      await prefs.setString(_kPreset, currentPreset!);
    } else {
      await prefs.remove(_kPreset);
    }
  }

  void toggleDark([bool? force]) {
    isDark = force ?? !isDark;
    _normalizeBackgroundForMode();
    _updateTheme();
  }

  void setPrimaryColor(Color c, {String? presetName}) {
    primary = c;
    currentPreset = presetName;
    _updateTheme();
  }

  void setBackgroundColor(Color c) {
    background = c;
    currentPreset = null;
    _normalizeBackgroundForMode();
    _updateTheme();
  }

  void applyPreset(String name) {
    final p = _presets[name];
    if (p == null) return;
    isDark = p.isDark;
    primary = p.primary;
    background = p.background;
    currentPreset = name;
    _updateTheme();
  }

  void _normalizeBackgroundForMode() {
    if (!isDark && _isDarkColor(background)) {
      background = Colors.white;
    }
    if (isDark && !_isDarkColor(background)) {
      background = const Color(0xFF1B1B1D);
    }
  }

  void _updateTheme() {
    themeNotifier.value = _buildTheme(isDark: isDark, primary: primary, background: background);
    _saveToPrefs();
  }

  static bool _isDarkColor(Color c) => c.computeLuminance() < 0.5;

  static ThemeData _buildDefaultTheme() {
    return _buildTheme(isDark: true, primary: Colors.blueAccent, background: const Color(0xFF1B1B1D));
  }

  static ThemeData _buildTheme({
    required bool isDark,
    required Color primary,
    required Color background,
  }) {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: primary, brightness: isDark ? Brightness.dark : Brightness.light);
    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Map<String, _ThemePreset> get presets => _presets;

  static final Map<String, _ThemePreset> _presets = {
    'Corporate Dark': _ThemePreset(
      isDark: true,
      primary: Colors.blueAccent,
      background: const Color(0xFF121214),
    ),
    'Dark Blue': _ThemePreset(
      isDark: true,
      primary: Colors.indigoAccent,
      background: const Color(0xFF061025),
    ),
    'Light Minimal': _ThemePreset(
      isDark: false,
      primary: Colors.teal,
      background: Colors.white,
    ),
    'Warm Light': _ThemePreset(
      isDark: false,
      primary: Colors.deepOrangeAccent,
      background: const Color(0xFFF7F5F2),
    ),
  };
}

class _ThemePreset {
  final bool isDark;
  final Color primary;
  final Color background;
  const _ThemePreset({required this.isDark, required this.primary, required this.background});
}
