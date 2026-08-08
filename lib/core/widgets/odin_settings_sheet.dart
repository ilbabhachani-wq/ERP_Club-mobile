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
    backgroundColor: OdinColors.panelSolid,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) {
      return Consumer2<ThemeProvider, LocaleProvider>(
        builder: (ctx, theme, locale, _) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: OdinColors.panelBorder,
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
                                color: OdinColors.textPrimary,
                              ),
                            ),
                            if (roleLabel != null)
                              Text(
                                roleLabel,
                                style: TextStyle(fontSize: 12, color: OdinColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionLabel('Apparence'),
                  const SizedBox(height: 8),
                  _ThemeModeRow(theme: theme),
                  const SizedBox(height: 16),
                  _SectionLabel('Langue'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final e in [('fr', 'FR'), ('en', 'EN'), ('ar', 'AR')])
                        ChoiceChip(
                          label: Text(e.$2),
                          selected: locale.locale == e.$1,
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
                    style: TextStyle(fontSize: 11, color: OdinColors.textMuted),
                  ),
                  if (links.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionLabel('Espace'),
                    const SizedBox(height: 8),
                    for (final link in links)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(link.icon, color: OdinColors.accent),
                        title: Text(link.label, style: TextStyle(color: OdinColors.textPrimary, fontWeight: FontWeight.w700)),
                        subtitle: link.subtitle == null
                            ? null
                            : Text(link.subtitle!, style: TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right_rounded, color: OdinColors.textMuted),
                        onTap: () {
                          Navigator.pop(ctx);
                          context.go(link.route);
                        },
                      ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
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
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: OdinColors.textMuted,
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
          color: selected ? OdinColors.accent.withValues(alpha: 0.16) : OdinColors.inputFill,
          border: Border.all(
            color: selected ? OdinColors.accent.withValues(alpha: 0.45) : OdinColors.panelBorder,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? OdinColors.accent : OdinColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: selected ? OdinColors.accent : OdinColors.textSecondary,
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
