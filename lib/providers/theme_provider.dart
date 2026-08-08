import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/odin_colors.dart';

/// Persisted light / dark / system mode for the whole app.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _load();
  }

  static const _key = 'odin_theme_mode';

  ThemeMode _mode = ThemeMode.dark;
  bool _ready = false;

  ThemeMode get mode => _mode;
  bool get ready => _ready;

  bool isDark(BuildContext context) {
    if (_mode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      switch (raw) {
        case 'light':
          _mode = ThemeMode.light;
        case 'system':
          _mode = ThemeMode.system;
        default:
          _mode = ThemeMode.dark;
      }
    } catch (_) {
      _mode = ThemeMode.dark;
    }
    _applyPaletteForMode();
    _ready = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    _applyPaletteForMode();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      };
      await prefs.setString(_key, value);
    } catch (_) {}
  }

  void syncFromPlatformBrightness(Brightness brightness) {
    if (_mode != ThemeMode.system) return;
    OdinColors.applyBrightness(brightness);
  }

  void _applyPaletteForMode() {
    if (_mode == ThemeMode.light) {
      OdinColors.apply(OdinPalette.light);
    } else if (_mode == ThemeMode.dark) {
      OdinColors.apply(OdinPalette.dark);
    } else {
      // System: apply platform brightness if available later in builder.
      OdinColors.apply(OdinPalette.dark);
    }
  }

  void applyOverlay(BuildContext context) {
    final dark = isDark(context);
    SystemChrome.setSystemUIOverlayStyle(
      dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }
}
