import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/odin_colors.dart';

/// Logo officiel ODIN ERP — aligné sur AuthShell.tsx
class OdinLogo extends StatelessWidget {
  const OdinLogo({
    super.key,
    this.width = 220,
    this.animated = true,
  });

  final double width;
  final bool animated;

  static const _asset = 'assets/images/odin-logo.png';

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox(
      width: width,
      child: Image.asset(
        _asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );

    if (!animated) return logo;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width * 0.7,
          height: width * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                OdinColors.accent.withValues(alpha: 0.35),
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1.05, 1.05),
              duration: 3.seconds,
              curve: Curves.easeInOut,
            ),
        logo
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -4, duration: 4.seconds, curve: Curves.easeInOut),
      ],
    );
  }
}
