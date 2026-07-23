import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/animations/odin_motion.dart';
import '../../../core/theme/odin_colors.dart';
import '../../../core/widgets/odin_widgets.dart';
import '../../../models/player_models.dart';
import '../../../models/viiv_metrics.dart';

/// Hero profil Viiv GX17 — style WhoopHero web avec montre 3D animée.
class ViivHeroProfile extends StatelessWidget {
  const ViivHeroProfile({
    super.key,
    required this.metrics,
    required this.player,
    required this.syncing,
    required this.onSync,
  });

  final ViivMetrics metrics;
  final BackendPlayer? player;
  final bool syncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final name = player?.name ?? metrics.deviceModel;
    final firstName = name.split(' ').first;
    final position = player?.position ?? 'Joueur';
    final photo = player?.photoUrl;
    final rc = viivRecoveryColor(metrics.recovery);

    return GlassCard(
      raised: true,
      accentColor: const Color(0xFF22D3EE),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _PlayerAvatar(name: name, photoUrl: photo, color: rc),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            firstName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _LiveBadge(connected: metrics.connected),
                      ],
                    ),
                    Text(
                      '$position · Viiv GX17',
                      style: const TextStyle(color: OdinColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _SyncButton(syncing: syncing, onSync: onSync),
            ],
          ),
          const SizedBox(height: 18),
          ViivGx17WatchShowcase(
            recovery: metrics.recovery,
            energy: metrics.viivEnergy,
            battery: metrics.battery,
            syncing: syncing,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedArcGauge(
                value: metrics.recovery.toDouble(),
                label: 'RECOVERY',
                size: 128,
                lowColor: OdinColors.danger,
                highColor: OdinColors.success,
              ),
              AnimatedArcGauge(
                value: metrics.viivEnergy.toDouble(),
                label: 'ÉNERGIE',
                size: 128,
                lowColor: OdinColors.warning,
                highColor: const Color(0xFF22D3EE),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Strain', value: metrics.strain.toStringAsFixed(1), color: OdinColors.accent)
                    .animate()
                    .fadeIn(delay: 100.ms)
                    .slideY(begin: 0.2, end: 0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(label: 'HRV', value: '${metrics.hrv} ms', color: const Color(0xFF34D399))
                    .animate()
                    .fadeIn(delay: 180.ms)
                    .slideY(begin: 0.2, end: 0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(label: 'Readiness', value: metrics.readiness, color: rc)
                    .animate()
                    .fadeIn(delay: 260.ms)
                    .slideY(begin: 0.2, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.watch_rounded, label: metrics.deviceModel),
              _InfoChip(icon: Icons.memory_rounded, label: metrics.firmware),
              _InfoChip(icon: Icons.battery_5_bar_rounded, label: '${metrics.battery}%'),
              _InfoChip(icon: Icons.sync_rounded, label: metrics.lastSync),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.04, end: 0);
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.name, this.photoUrl, required this.color});

  final String name;
  final String? photoUrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12)],
      ),
      clipBehavior: Clip.antiAlias,
      child: photoUrl != null
          ? Image.network(photoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _initials(initials))
          : _initials(initials),
    );
  }

  Widget _initials(String initials) {
    return Container(
      color: const Color(0xFF1A1A28),
      alignment: Alignment.center,
      child: Text(initials, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16)),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (connected ? OdinColors.success : OdinColors.danger).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (connected ? OdinColors.success : OdinColors.danger).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? OdinColors.success : OdinColors.danger,
              boxShadow: connected ? [BoxShadow(color: OdinColors.success.withValues(alpha: 0.8), blurRadius: 6)] : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            connected ? 'LIVE' : 'OFF',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: connected ? OdinColors.success : OdinColors.danger,
            ),
          ),
        ],
      ),
    );
    if (!connected) return badge;
    return badge
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 1, end: 0.5, duration: 1500.ms, curve: Curves.easeInOut);
  }
}

class _SyncButton extends StatefulWidget {
  const _SyncButton({required this.syncing, required this.onSync});

  final bool syncing;
  final VoidCallback onSync;

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void didUpdateWidget(covariant _SyncButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.syncing && !oldWidget.syncing) {
      _done = false;
      _spin.repeat();
    } else if (!widget.syncing && oldWidget.syncing) {
      _spin.stop();
      setState(() => _done = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _done = false);
      });
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.syncing ? null : widget.onSync,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [Color(0xFF22D3EE), Color(0xFF0891B2)]),
            boxShadow: [BoxShadow(color: const Color(0xFF22D3EE).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _done
                      ? const Icon(Icons.check_rounded, key: ValueKey('ok'), size: 18, color: Colors.black)
                      : RotationTransition(
                          key: const ValueKey('spin'),
                          turns: _spin,
                          child: const Icon(Icons.sync_rounded, size: 18, color: Colors.black),
                        ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.syncing ? '…' : (_done ? 'OK' : 'Sync'),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: OdinColors.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF22D3EE)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: OdinColors.textSecondary)),
        ],
      ),
    );
  }
}

/// Showcase montre — glow + pseudo-3D animé.
class ViivGx17WatchShowcase extends StatefulWidget {
  const ViivGx17WatchShowcase({
    super.key,
    required this.recovery,
    required this.energy,
    required this.battery,
    this.syncing = false,
  });

  final int recovery;
  final int energy;
  final int battery;
  final bool syncing;

  @override
  State<ViivGx17WatchShowcase> createState() => _ViivGx17WatchShowcaseState();
}

class _ViivGx17WatchShowcaseState extends State<ViivGx17WatchShowcase> with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _rotate;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
    _rotate = AnimationController(vsync: this, duration: const Duration(milliseconds: 7000))..repeat(reverse: true);
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    _rotate.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _rotate, _pulse]),
        builder: (_, __) {
          final floatY = math.sin(_float.value * math.pi) * 8;
          final rotY = (math.sin(_rotate.value * math.pi) * 0.28);
          final pulse = 0.85 + math.sin(_pulse.value * math.pi * 2) * 0.15;

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 200 * pulse,
                height: 200 * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22D3EE).withValues(alpha: 0.18),
                      const Color(0xFF0891B2).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF22D3EE).withValues(alpha: 0.2), blurRadius: 40, spreadRadius: 8),
                  ],
                ),
              ),
              ...List.generate(3, (i) {
                final t = (_pulse.value + i * 0.33) % 1.0;
                return Positioned(
                  child: Transform.scale(
                    scale: 0.7 + t * 0.5,
                    child: Opacity(
                      opacity: (1 - t) * 0.35,
                      child: Container(
                        width: 160 + i * 20,
                        height: 160 + i * 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.25), width: 1),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateY(rotY)
                  ..translate(0.0, floatY),
                child: ViivGx17Watch3D(
                  recovery: widget.recovery,
                  energy: widget.energy,
                  battery: widget.battery,
                  syncing: widget.syncing,
                  spin: widget.syncing ? _pulse.value : 0,
                ),
              ),
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Text(
                    'Viiv GX17 · Glisser · 360°',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: OdinColors.textMuted, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Montre pseudo-3D — reproduction design Tripo Viiv (sans GLB 11MB).
class ViivGx17Watch3D extends StatelessWidget {
  const ViivGx17Watch3D({
    super.key,
    required this.recovery,
    required this.energy,
    required this.battery,
    this.syncing = false,
    this.spin = 0,
  });

  final int recovery;
  final int energy;
  final int battery;
  final bool syncing;
  final double spin;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Gx17ProPainter(recovery: recovery, energy: energy, battery: battery, spin: spin),
      child: const SizedBox(width: 200, height: 240),
    );
  }
}

class _Gx17ProPainter extends CustomPainter {
  _Gx17ProPainter({
    required this.recovery,
    required this.energy,
    required this.battery,
    required this.spin,
  });

  final int recovery;
  final int energy;
  final int battery;
  final double spin;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const bodyW = 148.0;
    const bodyH = 172.0;

    _shadow(canvas, Offset(cx, cy + bodyH * 0.42), bodyW * 0.55);

    // Straps
    _strap(canvas, Offset(cx, cy - bodyH / 2 - 28), 52, 44);
    _strap(canvas, Offset(cx, cy + bodyH / 2 + 28), 52, 44);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: bodyW, height: bodyH),
      const Radius.circular(32),
    );

    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Color(0xFF3A3A48), Color(0xFF12121A), Color(0xFF0A0A10), Color(0xFF222230)],
        ).createShader(bodyRect.outerRect),
    );

    // Chrome side button
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + bodyW / 2 + 4, cy - 12), width: 6, height: 28),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFE4E4E7), Color(0xFF71717A), Color(0xFFD4D4D8)]).createShader(
          Rect.fromLTWH(cx + bodyW / 2, cy - 26, 8, 28),
        ),
    );

    canvas.drawRRect(
      bodyRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          colors: [const Color(0xFF22D3EE).withValues(alpha: 0.7), Colors.white.withValues(alpha: 0.15), const Color(0xFF0891B2).withValues(alpha: 0.5)],
        ).createShader(bodyRect.outerRect),
    );

    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: bodyW - 20, height: bodyH - 26),
      const Radius.circular(24),
    );

    canvas.save();
    canvas.clipRRect(screenRect);
    canvas.drawRRect(screenRect, Paint()..color = const Color(0xFF040408));
    _ribbedFace(canvas, screenRect.outerRect);
    canvas.restore();

    canvas.drawRRect(
      screenRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    _ring(canvas, Offset(cx, cy), 52, recovery / 100, viivRecoveryColor(recovery), 6);
    _ring(canvas, Offset(cx, cy), 40, energy / 100, viivEnergyColor(energy), 4);

    if (spin > 0) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(spin * math.pi * 2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 62),
        0,
        math.pi / 2.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..shader = SweepGradient(colors: [Colors.transparent, const Color(0xFF22D3EE), Colors.transparent]).createShader(
            Rect.fromCircle(center: Offset.zero, radius: 62),
          ),
      );
      canvas.restore();
    }

    _text(canvas, 'VIIV', Offset(cx, cy - 28), 10, const Color(0xFF22D3EE), FontWeight.w900);
    _text(canvas, 'GX17', Offset(cx, cy - 14), 8, Colors.white54, FontWeight.w700);
    _text(canvas, '$recovery%', Offset(cx, cy + 8), 26, Colors.white, FontWeight.w300);
    _text(canvas, 'REC', Offset(cx, cy + 28), 8, viivRecoveryColor(recovery), FontWeight.w800);
    _text(canvas, '⚡ $energy%', Offset(cx, cy + 42), 8, viivEnergyColor(energy), FontWeight.w600);

    // Battery pill
    final pill = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 58), width: 52, height: 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(pill, Paint()..color = Colors.white.withValues(alpha: 0.08));
    _text(canvas, '🔋 $battery%', Offset(cx, cy + 58), 7, Colors.white60, FontWeight.w600);

    // Glass reflection
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW / 2 + 8, cy - bodyH / 2 + 8, bodyW * 0.35, bodyH * 0.45),
        const Radius.circular(20),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.12), Colors.transparent],
        ).createShader(Rect.fromLTWH(cx - bodyW / 2, cy - bodyH / 2, bodyW, bodyH)),
    );
  }

  void _shadow(Canvas canvas, Offset c, double w) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: w, height: 18),
      Paint()
        ..shader = RadialGradient(colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent]).createShader(
          Rect.fromCenter(center: c, width: w, height: 18),
        ),
    );
  }

  void _strap(Canvas canvas, Offset c, double w, double h) {
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: w, height: h), const Radius.circular(10));
    canvas.drawRRect(r, Paint()..color = const Color(0xFF111114));
    for (var y = c.dy - h / 2; y < c.dy + h / 2; y += 3) {
      canvas.drawLine(
        Offset(c.dx - w / 2, y),
        Offset(c.dx + w / 2, y),
        Paint()..color = (y.toInt() % 6 == 0 ? const Color(0xFF1A1A20) : const Color(0xFF0C0C0E))..strokeWidth = 1,
      );
    }
  }

  void _ribbedFace(Canvas canvas, Rect rect) {
    for (var x = rect.left; x < rect.right; x += 3) {
      canvas.drawLine(
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        Paint()
          ..color = (x.toInt() % 6 == 0 ? const Color(0xFF141418) : const Color(0xFF0A0A0E))
          ..strokeWidth = 1,
      );
    }
  }

  void _ring(Canvas canvas, Offset c, double r, double v, Color color, double stroke) {
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = stroke);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * v.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, color == viivRecoveryColor(recovery) ? 2 : 1),
    );
  }

  void _text(Canvas canvas, String t, Offset c, double size, Color color, FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: size, color: color, fontWeight: w)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_Gx17ProPainter old) =>
      old.recovery != recovery || old.energy != energy || old.battery != battery || old.spin != spin;
}

class ViivGlassMetric extends StatelessWidget {
  const ViivGlassMetric({
    super.key,
    required this.label,
    required this.value,
    this.suffix = '',
    this.delta,
    this.progress,
    this.color = const Color(0xFF22D3EE),
  });

  final String label;
  final dynamic value;
  final String suffix;
  final String? delta;
  final int? progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x80111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: OdinColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            '$value$suffix',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: OdinColors.textPrimary),
          ),
          if (delta != null)
            Text(delta!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (progress! / 100).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color viivRecoveryColor(int v) {
  if (v >= 67) return const Color(0xFF34D399);
  if (v >= 34) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

Color viivEnergyColor(int v) {
  if (v >= 70) return const Color(0xFF22D3EE);
  if (v >= 40) return const Color(0xFF3B82F6);
  return const Color(0xFF64748B);
}
