import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'odin_colors.dart';

abstract final class OdinTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OdinColors.canvas,
      colorScheme: const ColorScheme.dark(
        primary: OdinColors.accent,
        secondary: OdinColors.playerCoral,
        surface: OdinColors.panelSolid,
        error: OdinColors.danger,
        onPrimary: Colors.white,
        onSurface: OdinColors.textPrimary,
      ),
      dividerColor: OdinColors.panelBorder,
      cardTheme: CardThemeData(
        color: OdinColors.glassPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: OdinColors.panelBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: OdinColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: OdinColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0FFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OdinColors.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OdinColors.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OdinColors.accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: OdinColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: OdinColors.textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: OdinColors.accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? OdinColors.accent : OdinColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? OdinColors.accent : OdinColors.textMuted,
            size: 22,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: OdinColors.panelSolid,
        contentTextStyle: GoogleFonts.inter(color: OdinColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: OdinColors.textPrimary,
        displayColor: OdinColors.textPrimary,
      ),
    );
  }
}
