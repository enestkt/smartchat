import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeProvider with ChangeNotifier {
  static const _key = 'dark_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Uygulama başlatılırken kaydedilmiş tercih yüklenir
  Future<void> loadThemePreference() async {
    final saved = await _storage.read(key: _key);
    if (saved == 'true') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  /// Dark mode aç/kapat
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await _storage.write(key: _key, value: 'false');
    } else {
      _themeMode = ThemeMode.dark;
      await _storage.write(key: _key, value: 'true');
    }
    notifyListeners();
  }

  /// Direkt olarak theme mode ayarla
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.write(key: _key, value: (mode == ThemeMode.dark).toString());
    notifyListeners();
  }
}
