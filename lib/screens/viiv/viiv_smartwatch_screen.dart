import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/odin_colors.dart';
import '../../../core/widgets/odin_widgets.dart';
import '../../../models/viiv_metrics.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/viiv_provider.dart';
import '../../../services/viiv_ble_service.dart';
import 'widgets/viiv_device_panel.dart';
import 'widgets/viiv_map_card.dart';

/// Interface Viiv style QWatch Pro — accessible uniquement si la montre est connectée.
class ViivSmartwatchScreen extends StatefulWidget {
  const ViivSmartwatchScreen({super.key});

  @override
  State<ViivSmartwatchScreen> createState() => _ViivSmartwatchScreenState();
}

class _ViivSmartwatchScreenState extends State<ViivSmartwatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viiv = context.read<ViivProvider>();
      final joueur = context.read<JoueurDataProvider>();
      viiv.load(joueur);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    await context.read<ViivProvider>().sync(context.read<JoueurDataProvider>());
  }

  @override
  Widget build(BuildContext context) {
    final viiv = context.watch<ViivProvider>();
    final ble = viiv.ble;

    if (viiv.loading && !ble.isConnected) {
      return const OdinBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF22D3EE), strokeWidth: 2.5),
              SizedBox(height: 14),
              Text('Recherche Viiv…', style: TextStyle(color: OdinColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    // ─── GATE : pas d’interfaces sans montre connectée ───
    if (!ble.isConnected) {
      return OdinBackdrop(child: _ViivConnectGate(viiv: viiv));
    }

    final m = viiv.metrics;
    if (m == null) {
      return OdinBackdrop(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (viiv.syncing || ble.state == ViivBleConnectionState.syncing) ...[
                const CircularProgressIndicator(color: Color(0xFF22D3EE), strokeWidth: 2.5),
                const SizedBox(height: 14),
                Text(
                  ble.syncProgress.isNotEmpty ? ble.syncProgress : 'Sync montre…',
                  style: const TextStyle(color: OdinColors.textMuted, fontSize: 13),
                ),
              ] else ...[
                const Icon(Icons.watch_rounded, color: Color(0xFF22D3EE), size: 40),
                const SizedBox(height: 12),
                Text(viiv.error ?? ble.error ?? 'Appuyez Sync pour lire la montre'),
                const SizedBox(height: 16),
                FilledButton(onPressed: _sync, child: const Text('Synchroniser')),
              ],
            ],
          ),
        ),
      );
    }

    return OdinBackdrop(
      child: Column(
        children: [
          _QWatchHeader(m: m, liveHr: ble.liveHr, syncing: viiv.syncing, onSync: _sync),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            indicatorColor: const Color(0xFF22D3EE),
            labelColor: const Color(0xFF22D3EE),
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Accueil'),
              Tab(text: 'Sommeil'),
              Tab(text: 'Cœur'),
              Tab(text: 'Appareil'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _HomeTab(m: m, liveHr: ble.liveHr, onRefresh: _sync),
                _SleepTab(m: m, onRefresh: _sync),
                _HeartTab(m: m, liveHr: ble.liveHr, onRefresh: _sync),
                _DeviceTab(onRefresh: _sync),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// GATE CONNEXION (QWatch-like)
// ═══════════════════════════════════════════════════════════

class _ViivConnectGate extends StatelessWidget {
  const _ViivConnectGate({required this.viiv});
  final ViivProvider viiv;

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final scanPath = loc.startsWith('/analyste') ? '/analyste/viiv/scan' : '/viiv/scan';
    final ble = viiv.ble;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF22D3EE).withValues(alpha: 0.35),
                    const Color(0xFF22D3EE).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.5), width: 2),
              ),
              child: const Icon(Icons.watch_rounded, size: 56, color: Color(0xFF22D3EE)),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 1400.ms),
            const SizedBox(height: 28),
            const Text(
              'Viiv',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Text(
              'Connectez votre montre pour débloquer\nsommeil, FC, pas, SpO₂ — tout en live.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Compatible QWatch Pro · H59 · Viiv GX17',
                style: TextStyle(fontSize: 11, color: Color(0xFF22D3EE), fontWeight: FontWeight.w700),
              ),
            ),
            if (ble.error != null) ...[
              const SizedBox(height: 16),
              Text(ble.error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: () => context.push(scanPath),
              icon: const Icon(Icons.bluetooth_searching_rounded),
              label: const Text('Connecter ma Viiv'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF22D3EE),
                foregroundColor: const Color(0xFF0B0B14),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            if (ble.pairedId != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  await ble.reconnectPaired();
                  if (context.mounted) {
                    await viiv.sync(context.read<JoueurDataProvider>());
                  }
                },
                icon: const Icon(Icons.link_rounded),
                label: Text('Reconnecter ${ble.pairedName ?? 'montre'}'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF22D3EE),
                  side: BorderSide(color: const Color(0xFF22D3EE).withValues(alpha: 0.45)),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              'Les interfaces santé restent verrouillées\ntant que la montre n’est pas connectée.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════

class _QWatchHeader extends StatelessWidget {
  const _QWatchHeader({
    required this.m,
    required this.onSync,
    this.liveHr,
    this.syncing = false,
  });

  final ViivMetrics m;
  final int? liveHr;
  final bool syncing;
  final Future<void> Function() onSync;

  @override
  Widget build(BuildContext context) {
    final hr = liveHr ?? m.restingHr;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Viiv', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF22C55E)),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${m.deviceModel} · ${m.battery}% · ${hr > 0 ? '$hr bpm' : '— bpm'}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: syncing ? null : () => onSync(),
              icon: syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF22D3EE)),
                    )
                  : const Icon(Icons.sync_rounded, color: Color(0xFF22D3EE)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ACCUEIL — anneaux activité (faza)
// ═══════════════════════════════════════════════════════════

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.m, required this.onRefresh, this.liveHr});
  final ViivMetrics m;
  final int? liveHr;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final stepsGoal = 8000;
    final calGoal = 500;
    final distKm = _distFromLabel(m.gpsActivity);
    final distGoal = 5.0;

    return RefreshIndicator(
      color: const Color(0xFF22D3EE),
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          GlassCard(
            child: Column(
              children: [
                const Text('Activité du jour', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  m.lastSyncAt.isNotEmpty ? 'Sync ${m.lastSyncAt}' : m.lastSync,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 220,
                  child: _ActivityRings(
                    steps: m.steps / stepsGoal,
                    calories: m.calories / calGoal,
                    distance: distKm / distGoal,
                    centerHr: liveHr ?? m.restingHr,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _RingLegend(color: const Color(0xFF22C55E), label: 'Pas', value: '${m.steps}'),
                    _RingLegend(color: const Color(0xFFFF7A00), label: 'kcal', value: '${m.calories}'),
                    _RingLegend(
                      color: const Color(0xFF22D3EE),
                      label: 'km',
                      value: distKm > 0 ? distKm.toStringAsFixed(2) : '—',
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _MetricTile(
                icon: Icons.favorite_rounded,
                color: const Color(0xFFEF4444),
                label: 'FC',
                value: '${liveHr ?? m.restingHr}',
                unit: 'bpm',
                live: liveHr != null,
              ),
              _MetricTile(
                icon: Icons.nightlight_round,
                color: const Color(0xFF818CF8),
                label: 'Sommeil',
                value: m.sleepHours > 0 ? m.sleepHours.toStringAsFixed(1) : '—',
                unit: 'h',
              ),
              _MetricTile(
                icon: Icons.air_rounded,
                color: const Color(0xFF22D3EE),
                label: 'SpO₂',
                value: m.spo2 > 0 ? '${m.spo2}' : '—',
                unit: '%',
              ),
              _MetricTile(
                icon: Icons.monitor_heart_outlined,
                color: const Color(0xFF34D399),
                label: 'HRV',
                value: m.hrv > 0 ? '${m.hrv}' : '—',
                unit: 'ms',
              ),
              _MetricTile(
                icon: Icons.psychology_alt_rounded,
                color: OdinColors.warning,
                label: 'Stress',
                value: m.stress > 0 ? '${m.stress}' : '—',
                unit: '',
              ),
              _MetricTile(
                icon: Icons.bolt_rounded,
                color: OdinColors.accent,
                label: 'Énergie',
                value: m.viivEnergy > 0 ? '${m.viivEnergy}' : '—',
                unit: '%',
              ),
            ],
          ),
          if (m.recovery > 0) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recovery', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('${m.recovery}% · ${m.readiness}', style: const TextStyle(color: OdinColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    m.strain.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFFF7A00)),
                  ),
                  const SizedBox(width: 6),
                  const Text('strain', style: TextStyle(color: OdinColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _distFromLabel(String gps) {
    final m = RegExp(r'([\d.]+)\s*km').firstMatch(gps);
    if (m != null) return double.tryParse(m.group(1)!) ?? 0;
    return 0;
  }
}

class _RingLegend extends StatelessWidget {
  const _RingLegend({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45))),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    this.live = false,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
              if (live) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
              ],
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Anneaux concentriques animés + pouls central (faza QWatch).
class _ActivityRings extends StatefulWidget {
  const _ActivityRings({
    required this.steps,
    required this.calories,
    required this.distance,
    required this.centerHr,
  });

  final double steps;
  final double calories;
  final double distance;
  final int centerHr;

  @override
  State<_ActivityRings> createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<_ActivityRings> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pulse = 1 + (_c.value * 0.04);
        return CustomPaint(
          painter: _RingsPainter(
            steps: widget.steps.clamp(0, 1.2),
            calories: widget.calories.clamp(0, 1.2),
            distance: widget.distance.clamp(0, 1.2),
            pulse: pulse,
          ),
          child: Center(
            child: Transform.scale(
              scale: pulse,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 22),
                  const SizedBox(height: 4),
                  Text(
                    widget.centerHr > 0 ? '${widget.centerHr}' : '—',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  Text('bpm', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.steps,
    required this.calories,
    required this.distance,
    required this.pulse,
  });

  final double steps;
  final double calories;
  final double distance;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radii = [78.0, 58.0, 38.0];
    final vals = [steps, calories, distance];
    final colors = const [Color(0xFF22C55E), Color(0xFFFF7A00), Color(0xFF22D3EE)];

    for (var i = 0; i < 3; i++) {
      final r = radii[i] * pulse;
      final bg = Paint()
        ..color = colors[i].withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(c, r, bg);

      final fg = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      final sweep = 2 * math.pi * vals[i].clamp(0.0, 1.0);
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, sweep, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.steps != steps || old.calories != calories || old.distance != distance || old.pulse != pulse;
}

// ═══════════════════════════════════════════════════════════
// SOMMEIL
// ═══════════════════════════════════════════════════════════

class _SleepTab extends StatelessWidget {
  const _SleepTab({required this.m, required this.onRefresh});
  final ViivMetrics m;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = m.sleepStages;
    final total = s.awake + s.light + s.sws + s.rem;
    final hasSleep = m.sleepHours > 0 || total > 0;

    return RefreshIndicator(
      color: const Color(0xFF818CF8),
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sommeil', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  hasSleep
                      ? '${m.sleepHours.floor()} h ${((m.sleepHours % 1) * 60).round()} min'
                      : 'Pas encore de données — portez la montre la nuit puis Sync',
                  style: TextStyle(
                    fontSize: hasSleep ? 32 : 14,
                    fontWeight: hasSleep ? FontWeight.w900 : FontWeight.w500,
                    color: hasSleep ? Colors.white : Colors.white54,
                  ),
                ),
                if (hasSleep) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Performance ${m.sleepPerformance}% · besoin ${m.sleepNeed.toStringAsFixed(0)} h',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                  ),
                ],
              ],
            ),
          ),
          if (hasSleep && total > 0) ...[
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stades', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 18,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Row(
                        children: [
                          if (s.awake > 0)
                            Expanded(flex: (s.awake * 100).round().clamp(1, 999), child: Container(color: const Color(0xFF64748B))),
                          if (s.light > 0)
                            Expanded(flex: (s.light * 100).round().clamp(1, 999), child: Container(color: const Color(0xFF818CF8))),
                          if (s.sws > 0)
                            Expanded(flex: (s.sws * 100).round().clamp(1, 999), child: Container(color: const Color(0xFF4F46E5))),
                          if (s.rem > 0)
                            Expanded(flex: (s.rem * 100).round().clamp(1, 999), child: Container(color: const Color(0xFF22D3EE))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _stageRow('Éveil', s.awake, const Color(0xFF64748B)),
                  _stageRow('Léger', s.light, const Color(0xFF818CF8)),
                  _stageRow('Profond', s.sws, const Color(0xFF4F46E5)),
                  _stageRow('REM', s.rem, const Color(0xFF22D3EE)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stageRow(String label, double hours, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(
            hours > 0 ? '${hours.toStringAsFixed(1)} h' : '—',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CŒUR
// ═══════════════════════════════════════════════════════════

class _HeartTab extends StatelessWidget {
  const _HeartTab({required this.m, required this.onRefresh, this.liveHr});
  final ViivMetrics m;
  final int? liveHr;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final hr = liveHr ?? m.restingHr;
    return RefreshIndicator(
      color: const Color(0xFFEF4444),
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          GlassCard(
            child: Column(
              children: [
                Text(
                  hr > 0 ? '$hr' : '—',
                  style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 700.ms,
                    ),
                Text(
                  liveHr != null ? 'bpm · live montre' : 'bpm · dernière sync',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _mini('HRV', m.hrv > 0 ? '${m.hrv} ms' : '—'),
                    _mini('SpO₂', m.spo2 > 0 ? '${m.spo2}%' : '—'),
                    _mini('Stress', m.stress > 0 ? '${m.stress}' : '—'),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    final viiv = context.read<ViivProvider>();
                    final msg = await viiv.measureSpo2(context.read<JoueurDataProvider>());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: msg.startsWith('SpO') ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.bloodtype_outlined, size: 18),
                  label: const Text('Mesurer SpO₂ maintenant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF22D3EE),
                    side: BorderSide(color: const Color(0xFF22D3EE).withValues(alpha: 0.5)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Courbe FC (montre)', color: Color(0xFFEF4444)),
          GlassCard(
            child: SizedBox(
              height: 180,
              child: m.hourlyHr.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune courbe — Sync avec la montre au poignet',
                        style: TextStyle(color: OdinColors.textMuted, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        minY: 40,
                        maxY: 180,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 9, color: OdinColors.textMuted)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: (m.hourlyHr.length / 4).clamp(1, 20).toDouble(),
                              getTitlesWidget: (v, _) {
                                final i = v.toInt();
                                if (i < 0 || i >= m.hourlyHr.length) return const SizedBox();
                                return Text(m.hourlyHr[i].hour, style: const TextStyle(fontSize: 8, color: OdinColors.textMuted));
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: m.hourlyHr
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value.bpm.toDouble()))
                                .toList(),
                            isCurved: true,
                            color: const Color(0xFFEF4444),
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: const Color(0xFFEF4444).withValues(alpha: 0.12)),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (m.zones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionTitle('Zones FC', color: Color(0xFFEF4444)),
            ...m.zones.map(
              (z) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: _hex(z.color), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(z.zone, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text('${z.minutes} min', style: const TextStyle(color: OdinColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mini(String k, String v) => Column(
        children: [
          Text(k, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4))),
          const SizedBox(height: 4),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );

  Color _hex(String h) {
    final hex = h.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

// ═══════════════════════════════════════════════════════════
// APPAREIL
// ═══════════════════════════════════════════════════════════

class _DeviceTab extends StatelessWidget {
  const _DeviceTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final m = context.watch<ViivProvider>().metrics;
    return RefreshIndicator(
      color: const Color(0xFF22D3EE),
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          const ViivDevicePanel(),
          const SizedBox(height: 16),
          ViivMapCard(gpsLabel: m?.gpsActivity ?? '—'),
          if (m != null && m.syncLog.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionTitle('Journal sync', color: Color(0xFF22D3EE)),
            ...m.syncLog.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        e.status == 'ok' ? Icons.check_circle : Icons.warning_amber,
                        color: e.status == 'ok' ? OdinColors.success : OdinColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.type, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      Text(e.time, style: const TextStyle(color: OdinColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
