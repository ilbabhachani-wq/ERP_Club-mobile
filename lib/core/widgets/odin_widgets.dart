import 'dart:ui';
import 'package:flutter/material.dart';
import '../animations/odin_animations.dart';
import '../theme/odin_colors.dart';

/// Carte auth — glass panel statique (AUTH_CARD_STYLE, sans animation continue).
class AuthGlassCard extends StatelessWidget {
  const AuthGlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(28)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: OdinColors.panelBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 60, offset: Offset(0, 24)),
          BoxShadow(color: Color(0x266366F1), blurRadius: 80),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: padding,
            decoration: const BoxDecoration(
              color: Color(0x8C0F1423),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x8C0F1423), Color(0x73101420)],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Champ glass-input web — label au-dessus, bordure accent au focus.
class OdinGlassTextField extends StatefulWidget {
  const OdinGlassTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.validator,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;

  @override
  State<OdinGlassTextField> createState() => _OdinGlassTextFieldState();
}

class _OdinGlassTextFieldState extends State<OdinGlassTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _focused ? OdinColors.accent : OdinColors.textSecondary,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: OdinColors.accent.withValues(alpha: 0.32),
                      blurRadius: 14,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: widget.validator,
            autofillHints: widget.autofillHints,
            style: const TextStyle(color: OdinColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: OdinColors.textMuted, fontSize: 14),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _focused ? OdinColors.accent : OdinColors.textSecondary,
                    )
                  : null,
              filled: true,
              fillColor: _focused ? const Color(0xFF1E2438) : const Color(0xB81C1C2E),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _focused ? OdinColors.accent : OdinColors.panelBorder,
                  width: _focused ? 1.6 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: OdinColors.panelBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: OdinColors.accent, width: 1.6),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: OdinColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: OdinColors.danger, width: 1.6),
              ),
              errorStyle: const TextStyle(color: OdinColors.danger, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fond premium — aurora animée + grille subtile.
class OdinBackdrop extends StatelessWidget {
  const OdinBackdrop({super.key, required this.child, this.showGrid = true});

  final Widget child;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B0B14), Color(0xFF10101C), Color(0xFF0B0B14)],
            ),
          ),
        ),
        const _AuroraLayer(),
        if (showGrid) CustomPaint(painter: _GridPainter()),
        child,
      ],
    );
  }
}

class _AuroraLayer extends StatefulWidget {
  const _AuroraLayer();

  @override
  State<_AuroraLayer> createState() => _AuroraLayerState();
}

class _AuroraLayerState extends State<_AuroraLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.7 + _ctrl.value * 0.2, -0.75),
                  radius: 1.1,
                  colors: [OdinColors.playerCoral.withValues(alpha: 0.14), Colors.transparent],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.85 - _ctrl.value * 0.15, 0.15),
                  radius: 0.85,
                  colors: [OdinColors.accent.withValues(alpha: 0.1), Colors.transparent],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, 0.9),
                  radius: 0.7,
                  colors: [const Color(0xFF22D3EE).withValues(alpha: 0.06), Colors.transparent],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Scaffold page pro — backdrop + transition + padding safe.
class OdinPageScaffold extends StatelessWidget {
  const OdinPageScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 100),
    this.animate = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return OdinBackdrop(
      child: animate ? OdinAnimations.page(body) : body,
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.raised = false,
    this.accentColor,
    this.blur = true,
    this.clipContent = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool raised;
  final Color? accentColor;
  final bool blur;
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? OdinColors.accent;
    final radius = BorderRadius.circular(22);

    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: raised ? accent.withValues(alpha: 0.25) : OdinColors.panelBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: raised ? accent.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.35),
            blurRadius: raised ? 36 : 20,
            offset: Offset(0, raised ? 14 : 8),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: raised
              ? [const Color(0xD9282840), const Color(0xB816162A)]
              : [const Color(0xB81C1C2E), const Color(0x9616162A)],
        ),
      ),
      child: clipContent
          ? ClipRRect(
              borderRadius: radius,
              child: blur
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Padding(padding: padding, child: child),
                    )
                  : Padding(padding: padding, child: child),
            )
          : blur
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Padding(padding: padding, child: child),
                )
              : Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      card = AnimatedGlassCard(onTap: onTap!, child: card);
    }
    return card;
  }
}

class AnimatedGlassCard extends StatefulWidget {
  const AnimatedGlassCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<AnimatedGlassCard> createState() => _AnimatedGlassCardState();
}

class _AnimatedGlassCardState extends State<AnimatedGlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _pressed = false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class JoueurPageTransition extends StatelessWidget {
  const JoueurPageTransition({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => OdinAnimations.page(child);
}

class JoueurKpiCard extends StatelessWidget {
  const JoueurKpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.color = OdinColors.accent,
    this.index = 0,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return OdinAnimations.fadeUp(
      KeyedSubtree(
        key: ValueKey('kpi-$label-$index'),
        child: GlassCard(
          accentColor: color,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.08)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: OdinColors.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: color.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      index: index,
    );
  }
}

class OvrRing extends StatelessWidget {
  const OvrRing({
    super.key,
    required this.ovr,
    this.size = 80,
    this.color = OdinColors.playerCoral,
  });

  final int ovr;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (ovr / 99).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              color: color,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$ovr',
                style: TextStyle(
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  color: OdinColors.textPrimary,
                ),
              ),
              Text(
                'OVR',
                style: TextStyle(
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w700,
                  color: OdinColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.color = OdinColors.playerCoral});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}

class OdinPrimaryButton extends StatelessWidget {
  const OdinPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.gradient = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient
              ? const LinearGradient(
                  colors: [OdinColors.accent, Color(0xFFE66000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: gradient ? null : OdinColors.accent,
          boxShadow: [
            BoxShadow(
              color: OdinColors.accent.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 8)],
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class OdinGlassNavBar extends StatelessWidget {
  const OdinGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xE60B0B14),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemW = constraints.maxWidth / destinations.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      left: itemW * selectedIndex + 8,
                      width: itemW - 16,
                      top: 8,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: OdinColors.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(destinations.length, (i) {
                        final d = destinations[i];
                        final active = i == selectedIndex;
                        return Expanded(
                          child: InkWell(
                            onTap: () => onSelected(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  active ? (d.selectedIcon as Icon?)?.icon ?? (d.icon as Icon).icon : (d.icon as Icon).icon,
                                  size: 22,
                                  color: active ? OdinColors.accent : OdinColors.textMuted,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    color: active ? OdinColors.accent : OdinColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class OdinProAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OdinProAppBar({
    super.key,
    required this.club,
    this.subtitle = 'Mon Espace',
    this.actions,
  });

  final String club;
  final String subtitle;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AppBar(
          backgroundColor: const Color(0x990B0B14),
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: OdinColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                club,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.3),
              ),
            ],
          ),
          actions: actions,
        ),
      ),
    );
  }
}
