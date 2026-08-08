import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'odin_colors.dart';

abstract final class OdinTheme {
  static ThemeData dark() => _build(OdinPalette.dark, Brightness.dark);

  static ThemeData light() => _build(OdinPalette.light, Brightness.light);

  static ThemeData _build(OdinPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.canvas,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: OdinColors.accent,
        onPrimary: Colors.white,
        secondary: OdinColors.playerCoral,
        onSecondary: Colors.white,
        surface: p.panelSolid,
        onSurface: p.textPrimary,
        error: OdinColors.danger,
        onError: Colors.white,
      ),
      dividerColor: p.panelBorder,
      cardTheme: CardThemeData(
        color: p.glassPanel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: p.panelBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: p.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: p.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.panelBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: p.panelBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OdinColors.accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: p.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: p.textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.inputFill,
        selectedColor: OdinColors.accent.withValues(alpha: 0.18),
        labelStyle: GoogleFonts.inter(color: p.textSecondary, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.inter(color: OdinColors.accent, fontSize: 12),
        side: BorderSide(color: p.panelBorder),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.panelSolid,
        modalBackgroundColor: p.panelSolid,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.panelSolid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: OdinColors.accent.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? OdinColors.accent : p.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? OdinColors.accent : p.textMuted,
            size: 22,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.panelSolid,
        contentTextStyle: GoogleFonts.inter(color: p.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected) ? OdinColors.accent : p.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          return s.contains(WidgetState.selected)
              ? OdinColors.accent.withValues(alpha: 0.35)
              : p.inputFill;
        }),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme)
          .apply(
            bodyColor: p.textPrimary,
            displayColor: p.textPrimary,
          )
          .copyWith(
            headlineMedium: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: p.textPrimary,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: p.textPrimary,
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
            titleSmall: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.textSecondary,
              height: 1.4,
            ),
            bodySmall: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: p.textMuted,
            ),
            labelLarge: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textPrimary,
            ),
          ),
    );
  }
}
