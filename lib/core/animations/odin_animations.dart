import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Presets pro — alignés Framer Motion / SaaS mobile.
abstract final class OdinAnimations {
  static const pageEnter = (
    duration: Duration(milliseconds: 420),
    begin: Offset(0, 18),
  );

  static const staggerDelay = Duration(milliseconds: 70);
  static const staggerInitialDelay = Duration(milliseconds: 40);
  static const curve = Curves.easeOutCubic;

  static Animate fadeUp(Widget child, {int index = 0}) {
    final delay = staggerInitialDelay + (staggerDelay * index);
    return child
        .animate()
        .fadeIn(duration: pageEnter.duration, delay: delay, curve: curve)
        .slideY(
          begin: pageEnter.begin.dy / 100,
          end: 0,
          duration: pageEnter.duration,
          delay: delay,
          curve: curve,
        );
  }

  static Animate scaleIn(Widget child, {Duration? delay}) {
    return child
        .animate()
        .fadeIn(duration: 380.ms, delay: delay ?? 0.ms, curve: curve)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          duration: 420.ms,
          delay: delay ?? 0.ms,
          curve: Curves.easeOutBack,
        );
  }

  static Animate slideInRight(Widget child) {
    return child
        .animate()
        .fadeIn(duration: 350.ms, curve: curve)
        .slideX(begin: 0.08, end: 0, duration: 400.ms, curve: curve);
  }

  static Widget page(Widget child) {
    return child
        .animate()
        .fadeIn(duration: pageEnter.duration, curve: curve)
        .slideY(begin: 0.04, end: 0, duration: pageEnter.duration, curve: curve);
  }

  static Animate glowPulse(Widget child, Color color) {
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .boxShadow(
          begin: BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12),
          end: BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 28),
          duration: 2.seconds,
        );
  }
}
