import 'package:flutter/material.dart';
import 'odin_colors.dart';

/// Design tokens SaaS — délégués à [OdinColors] (light/dark).
abstract final class AppColors {
  static Color get bg => OdinColors.canvas;
  static Color get bg2 => OdinColors.canvas2;
  static Color get card => OdinColors.panelSolid;
  static const accent = OdinColors.accent;
  static const accentStrong = OdinColors.accentStrong;
  static const coral = OdinColors.playerCoral;
  static const success = Color(0xFF22C55E);
  static const warning = OdinColors.warning;
  static const danger = OdinColors.danger;
  static const info = OdinColors.info;
  static Color get text => OdinColors.textPrimary;
  static Color get textSecondary => OdinColors.textSecondary;
  static Color get muted => OdinColors.textMuted;
  static Color get border => OdinColors.panelBorder;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
  static const page = 16.0;
  /// Padding sous les listes pour passer au-dessus de la glass nav.
  static const bottomNav = 128.0;
  static const glassNavBar = 68.0;
  static const glassNavGap = 16.0;

  /// Scaffold FAB: la safe area est déjà gérée, on relève seulement la barre.
  static double fabLift(BuildContext context) => glassNavBar + glassNavGap;

  /// `bottom` d’un FAB `Positioned` dans un body `extendBody`.
  static double fabBottom(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return (safe > 0 ? safe : 10) + glassNavBar + glassNavGap;
  }
}

abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const pill = 999.0;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
}

abstract final class AppShadows {
  static List<BoxShadow> soft([Color? tint]) => [
        BoxShadow(
          color: OdinColors.shadow,
          blurRadius: OdinColors.isDark ? 20 : 16,
          offset: const Offset(0, 8),
        ),
        if (tint != null)
          BoxShadow(
            color: tint.withValues(alpha: OdinColors.isDark ? 0.12 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
      ];
}
