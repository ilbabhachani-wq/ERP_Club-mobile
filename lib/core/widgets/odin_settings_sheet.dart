import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/odin_colors.dart';
import '../../providers/app_providers.dart';
import '../../providers/theme_provider.dart';

/// Shared settings sheet — theme, language, logout (+ optional deep links).
Future<void> showOdinSettingsSheet(
  BuildContext context, {
  String? roleLabel,
  List<OdinSettingsLink> links = const [],
}) async {
  HapticFeedback.lightImpact();
  await showModalBottomSheet<void>(
    context: context,
    // Transparent so the Consumer can paint a live theme background.
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Consumer2<ThemeProvider, LocaleProvider>(
        builder: (ctx, theme, locale, _) {
          // Keep palette in sync while the sheet is open (theme chips live here).
          if (theme.mode == ThemeMode.light) {
            OdinColors.apply(OdinPalette.light);
          } else if (theme.mode == ThemeMode.dark) {
            OdinColors.apply(OdinPalette.dark);
          } else {
            OdinColors.applyBrightness(MediaQuery.platformBrightnessOf(ctx));
          }

          final isDark = OdinColors.isDark;
          final panel = OdinColors.panelSolid;
          final text = OdinColors.textPrimary;
          final muted = OdinColors.textMuted;
          final secondary = OdinColors.textSecondary;
          final border = OdinColors.panelBorder;
          final fill = OdinColors.inputFill;

          return Theme(
            data: Theme.of(ctx).copyWith(
              brightness: isDark ? Brightness.dark : Brightness.light,
              colorScheme: Theme.of(ctx).colorScheme.copyWith(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                    surface: panel,
                    onSurface: text,
                  ),
              chipTheme: Theme.of(ctx).chipTheme.copyWith(
                    backgroundColor: fill,
                    selectedColor: OdinColors.accent.withValues(alpha: 0.18),
                    labelStyle: TextStyle(color: secondary, fontSize: 12),
                    secondaryLabelStyle: const TextStyle(color: OdinColors.accent, fontSize: 12),
                    side: BorderSide(color: border),
                  ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.viewInsetsOf(ctx).bottom + 8,
                ),
                child: Material(
                  key: ValueKey('settings-skin-${theme.mode.name}-$isDark'),
                  color: panel,
                  elevation: 8,
                  shadowColor: OdinColors.shadow,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: border,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: OdinColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.settings_rounded, color: OdinColors.accent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Paramètres',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: text,
                                    ),
                                  ),
                                  if (roleLabel != null)
                                    Text(
                                      roleLabel,
                                      style: TextStyle(fontSize: 12, color: muted),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SectionLabel('Apparence', color: muted),
                        const SizedBox(height: 8),
                        _ThemeModeRow(theme: theme),
                        const SizedBox(height: 16),
                        _SectionLabel('Langue', color: muted),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final e in [('fr', 'FR'), ('en', 'EN'), ('ar', 'AR')])
                              ChoiceChip(
                                label: Text(e.$2),
                                selected: locale.locale == e.$1,
                                labelStyle: TextStyle(
                                  color: locale.locale == e.$1 ? OdinColors.accent : secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                                selectedColor: OdinColors.accent.withValues(alpha: 0.18),
                                backgroundColor: fill,
                                side: BorderSide(
                                  color: locale.locale == e.$1
                                      ? OdinColors.accent.withValues(alpha: 0.45)
                                      : border,
                                ),
                                onSelected: (_) async {
                                  await locale.setLocale(e.$1);
                                  if (!ctx.mounted) return;
                                  final label = switch (e.$1) {
                                    'en' => 'English',
                                    'ar' => 'العربية',
                                    _ => 'Français',
                                  };
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.$1 == 'ar'
                                            ? 'اللغة: $label (واجهة من اليمين لليسار)'
                                            : 'Langue: $label',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          locale.locale == 'ar'
                              ? 'التواريخ واتجاه النص يتبعان اللغة المختارة'
                              : locale.locale == 'en'
                                  ? 'Dates & system UI follow the selected language'
                                  : 'Les dates et l’interface système suivent la langue',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                        if (links.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SectionLabel('Espace', color: muted),
                          const SizedBox(height: 8),
                          for (final link in links)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(link.icon, color: OdinColors.accent),
                              title: Text(
                                link.label,
                                style: TextStyle(color: text, fontWeight: FontWeight.w700),
                              ),
                              subtitle: link.subtitle == null
                                  ? null
                                  : Text(link.subtitle!, style: TextStyle(color: muted, fontSize: 12)),
                              trailing: Icon(Icons.chevron_right_rounded, color: muted),
                              onTap: () {
                                Navigator.pop(ctx);
                                context.go(link.route);
                              },
                            ),
                        ],
                        const SizedBox(height: 12),
                        Divider(height: 1, color: border),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.logout_rounded, color: OdinColors.danger),
                          title: const Text(
                            'Déconnexion',
                            style: TextStyle(color: OdinColors.danger, fontWeight: FontWeight.w800),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.read<AuthProvider>().logout();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class OdinSettingsLink {
  const OdinSettingsLink({
    required this.label,
    required this.route,
    required this.icon,
    this.subtitle,
  });

  final String label;
  final String route;
  final IconData icon;
  final String? subtitle;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow({required this.theme});
  final ThemeProvider theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final opt in [
          (ThemeMode.light, Icons.light_mode_rounded, 'Clair'),
          (ThemeMode.dark, Icons.dark_mode_rounded, 'Sombre'),
          (ThemeMode.system, Icons.brightness_auto_rounded, 'Auto'),
        ]) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ThemeChip(
                selected: theme.mode == opt.$1,
                icon: opt.$2,
                label: opt.$3,
                onTap: () => theme.setMode(opt.$1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = OdinColors.textMuted;
    final secondary = OdinColors.textSecondary;
    final border = OdinColors.panelBorder;
    final fill = OdinColors.inputFill;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? OdinColors.accent.withValues(alpha: 0.16) : fill,
          border: Border.all(
            color: selected ? OdinColors.accent.withValues(alpha: 0.45) : border,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? OdinColors.accent : muted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? OdinColors.accent : secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gear button for all shells.
class OdinSettingsButton extends StatelessWidget {
  const OdinSettingsButton({
    super.key,
    this.roleLabel,
    this.links = const [],
    this.color,
  });

  final String? roleLabel;
  final List<OdinSettingsLink> links;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Paramètres',
      icon: Icon(Icons.settings_outlined, color: color ?? OdinColors.textSecondary),
      onPressed: () => showOdinSettingsSheet(
        context,
        roleLabel: roleLabel,
        links: links,
      ),
    );
  }
}
