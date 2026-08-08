import 'package:flutter/material.dart';

/// Mutable ODIN palette — bound by [ThemeProvider] / MaterialApp builder
/// so existing `OdinColors.canvas` call sites flip with light/dark.
class OdinPalette {
  const OdinPalette({
    required this.canvas,
    required this.canvas2,
    required this.panelSolid,
    required this.panelBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.glassPanel,
    required this.glassRaised,
    required this.glassSheen,
    required this.navFill,
    required this.appBarFill,
    required this.gridLine,
    required this.shadow,
    required this.inputFill,
    required this.isDark,
  });

  final Color canvas;
  final Color canvas2;
  final Color panelSolid;
  final Color panelBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color glassPanel;
  final Color glassRaised;
  final Color glassSheen;
  final Color navFill;
  final Color appBarFill;
  final Color gridLine;
  final Color shadow;
  final Color inputFill;
  final bool isDark;

  static const dark = OdinPalette(
    canvas: Color(0xFF0B0B14),
    canvas2: Color(0xFF12121C),
    panelSolid: Color(0xFF16162A),
    panelBorder: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFF5F6FA),
    textSecondary: Color(0xFFCFD1D9),
    textMuted: Color(0xFFA8ABB8),
    glassPanel: Color(0xB81C1C2E),
    glassRaised: Color(0xD9282840),
    glassSheen: Color(0x12FFFFFF),
    navFill: Color(0xEE12121C),
    appBarFill: Color(0xCC0B0B14),
    gridLine: Color(0x06FFFFFF),
    shadow: Color(0x59000000),
    inputFill: Color(0x0FFFFFFF),
    isDark: true,
  );

  /// Aligné sur web `[data-theme="light"]` (index.css).
  static const light = OdinPalette(
    canvas: Color(0xFFEEF1F6),
    canvas2: Color(0xFFF8FAFC),
    panelSolid: Color(0xFFFFFFFF),
    panelBorder: Color(0x1A0F172A),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    glassPanel: Color(0xEBFFFFFF),
    glassRaised: Color(0xFFFFFFFF),
    glassSheen: Color(0x8CFFFFFF),
    navFill: Color(0xFAF8FAFC),
    appBarFill: Color(0xFAF8FAFC),
    gridLine: Color(0x0A0F172A),
    shadow: Color(0x140F172A),
    inputFill: Color(0x0A0F172A),
    isDark: false,
  );
}

/// Tokens ODIN — brand const + surfaces theme-aware via [apply].
abstract final class OdinColors {
  static OdinPalette _p = OdinPalette.dark;

  static OdinPalette get palette => _p;
  static bool get isDark => _p.isDark;

  static void apply(OdinPalette palette) => _p = palette;

  static void applyBrightness(Brightness brightness) {
    _p = brightness == Brightness.dark ? OdinPalette.dark : OdinPalette.light;
  }

  // Brand (shared)
  static const ink = Color(0xFF1A1A2E);
  static const red = Color(0xFFC0392B);
  static const playerCoral = Color(0xFFFF6B57);
  static const accent = Color(0xFFFF7A00);
  static const accentStrong = Color(0xFFE66000);

  // Surfaces (theme-aware)
  static Color get canvas => _p.canvas;
  static Color get canvas2 => _p.canvas2;
  static Color get panelSolid => _p.panelSolid;
  static Color get panelBorder => _p.panelBorder;

  // Text (theme-aware)
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;

  // States (shared)
  static const success = Color(0xFF2E9E5B);
  static const warning = Color(0xFFD99A1F);
  static const danger = Color(0xFFC0392B);
  static const info = Color(0xFF3A7BD5);

  // Glass (theme-aware)
  static Color get glassPanel => _p.glassPanel;
  static Color get glassRaised => _p.glassRaised;
  static Color get glassSheen => _p.glassSheen;
  static Color get navFill => _p.navFill;
  static Color get appBarFill => _p.appBarFill;
  static Color get gridLine => _p.gridLine;
  static Color get shadow => _p.shadow;
  static Color get inputFill => _p.inputFill;

  // FIFA card
  static const fifaGold = Color(0xFFFFD86E);
  static const fifaStat = Color(0xFF1A1008);
}
