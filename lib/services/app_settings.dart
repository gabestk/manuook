import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppColorOption {
  final String name;
  final Color color;
  const AppColorOption(this.name, this.color);
}

const List<AppColorOption> kAppColors = [
  AppColorOption('Verde escuro', Color(0xFF1B5E20)),
  AppColorOption('Verde-água', Color(0xFF00796B)),
  AppColorOption('Azul', Color(0xFF1565C0)),
  AppColorOption('Azul-marinho', Color(0xFF1A237E)),
  AppColorOption('Roxo', Color(0xFF6A1B9A)),
  AppColorOption('Rosa', Color(0xFFC2185B)),
  AppColorOption('Vinho', Color(0xFF7B1F2E)),
  AppColorOption('Vermelho', Color(0xFFC62828)),
  AppColorOption('Laranja', Color(0xFFE65100)),
  AppColorOption('Dourado', Color(0xFFB8860B)),
  AppColorOption('Marrom', Color(0xFF5D4037)),
  AppColorOption('Grafite', Color(0xFF455A64)),
];

/// Preferências do app: modo claro/noturno e cor principal.
class AppSettings extends ChangeNotifier {
  static const _modeKey = 'manuook_theme_mode';
  static const _colorKey = 'manuook_seed_color';

  ThemeMode themeMode = ThemeMode.dark;
  Color seedColor = kAppColors.first.color;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_modeKey)) {
      case 'light':
        themeMode = ThemeMode.light;
      case 'system':
        themeMode = ThemeMode.system;
      default:
        themeMode = ThemeMode.dark;
    }
    final c = prefs.getInt(_colorKey);
    if (c != null) seedColor = Color(c);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _modeKey,
        switch (m) {
          ThemeMode.light => 'light',
          ThemeMode.system => 'system',
          ThemeMode.dark => 'dark',
        });
  }

  Future<void> setSeedColor(Color c) async {
    seedColor = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, c.toARGB32());
  }
}
