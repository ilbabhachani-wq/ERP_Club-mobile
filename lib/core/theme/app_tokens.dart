import 'package:flutter/material.dart';
import 'odin_colors.dart';

/// Design tokens SaaS — palette web ODIN (`src/index.css`).
abstract final class AppColors {
  static const bg = OdinColors.canvas; // #0B0B14
  static const bg2 = OdinColors.canvas2; // #12121C
  static const card = OdinColors.panelSolid; // #16162A
  static const accent = OdinColors.accent; // #FF7A00
  static const accentStrong = OdinColors.accentStrong;
  static const coral = OdinColors.playerCoral;
  static const success = Color(0xFF22C55E);
  static const warning = OdinColors.warning;
  static const danger = OdinColors.danger;
  static const info = OdinColors.info;
  static const text = OdinColors.textPrimary;
  static const textSecondary = OdinColors.textSecondary;
  static const muted = OdinColors.textMuted;
  static const border = OdinColors.panelBorder;
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 16.0;
  static const l = 24.0;
  static const xl = 32.0;
  static const page = 16.0;
  static const bottomNav = 110.0;
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
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        if (tint != null)
          BoxShadow(
            color: tint.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
      ];
}
