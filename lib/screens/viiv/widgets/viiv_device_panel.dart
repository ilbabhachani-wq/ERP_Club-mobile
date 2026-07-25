import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/viiv_haptics.dart';
import '../../../core/widgets/odin_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/viiv_provider.dart';
import '../../../services/viiv_ble_service.dart';

/// Panneau Dispositif — scan page + trouver montre (vibration) + flux live.
class ViivDevicePanel extends StatelessWidget {
  const ViivDevicePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final viiv = context.watch<ViivProvider>();
    final ble = viiv.ble;
    final joueur = context.watch<JoueurDataProvider>();
    final m = viiv.metrics;
    final loc = GoRouterState.of(context).uri.path;
    final scanPath = loc.startsWith('/analyste') ? '/analyste/viiv/scan' : '/viiv/scan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionTitle('Dispositif · Bluetooth', color: Color(0xFF22D3EE)),
            ),
            if (viiv.isLiveFromWatch)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'LIVE VIIV',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF22C55E)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (!ble.isSupported)
          GlassCard(
            child: Text(
              'Le Bluetooth Viiv nécessite l’app iOS ou Android (pas le navigateur).',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), height: 1.4),
            ),
          )
        else ...[
          _ConnectedCard(
            ble: ble,
            battery: ble.liveBattery ?? m?.battery ?? 0,
            firmware: m?.firmware ?? 'Viiv OS 2.4',
            liveHr: ble.liveHr ?? m?.restingHr,
            onDetach: () async {
              await ViivHaptics.scanPulse();
              await viiv.forgetDevice();
            },
            onSync: () async {
              HapticFeedback.selectionClick();
              await viiv.sync(joueur);
            },
            syncing: viiv.syncing || ble.state == ViivBleConnectionState.syncing,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await ViivHaptics.scanPulse();
              if (context.mounted) context.push(scanPath);
            },
            icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
            label: const Text('Scanner Viiv'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF22D3EE),
              foregroundColor: const Color(0xFF0B0B14),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: ble.isConnected
                ? () async {
                    // Vibration montre uniquement (pas le téléphone)
                    final msg = await viiv.findViiv();
                    if (context.mounted) {
                      final ok = msg.toLowerCase().contains('envoy');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: ok ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                        ),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.vibration_rounded, size: 18),
            label: const Text('Vibrer la montre Viiv'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            ),
          ),
          if (!ble.isConnected)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Connectez d’abord la Viiv — la vibration va sur la montre, pas le téléphone.',
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
              ),
            ),
          if (ble.pairedId != null && !ble.isConnected) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await ViivHaptics.scanPulse();
                await ble.reconnectPaired();
                await viiv.sync(joueur);
              },
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Reconnecter la montre appairée'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22D3EE),
                side: BorderSide(color: const Color(0xFF22D3EE).withValues(alpha: 0.5)),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              ),
            ),
          ],
          if (ble.error != null) ...[
            const SizedBox(height: 8),
            Text(ble.error!, style: const TextStyle(color: AppColors.danger, fontSize: 12, height: 1.35)),
          ],
          if (ble.lastSnapshot != null) ...[
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Flux Viiv (données montre)', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip('Batt ${ble.lastSnapshot!.battery}%'),
                      if (ble.lastSnapshot!.heartRate != null) _Chip('${ble.lastSnapshot!.heartRate} bpm'),
                      if (ble.lastSnapshot!.steps != null) _Chip('${ble.lastSnapshot!.steps} pas'),
                      if (ble.lastSnapshot!.calories != null) _Chip('${ble.lastSnapshot!.calories} kcal'),
                      if (ble.lastSnapshot!.hrv != null) _Chip('HRV ${ble.lastSnapshot!.hrv}'),
                      if (ble.lastSnapshot!.spo2 != null) _Chip('SpO₂ ${ble.lastSnapshot!.spo2}%'),
                      if (ble.lastSnapshot!.sleepMinutes != null)
                        _Chip('Sommeil ${(ble.lastSnapshot!.sleepMinutes! / 60).toStringAsFixed(1)}h'),
                      _Chip('${ble.lastSnapshot!.servicesFound.length} services'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({
    required this.ble,
    required this.battery,
    required this.firmware,
    required this.liveHr,
    required this.onDetach,
    required this.onSync,
    required this.syncing,
  });

  final ViivBleService ble;
  final int battery;
  final String firmware;
  final int? liveHr;
  final VoidCallback onDetach;
  final VoidCallback onSync;
  final bool syncing;

  @override
  Widget build(BuildContext context) {
    final connected = ble.isConnected;
    final name = ble.pairedName ?? 'Viiv GX17';
    final id = ble.pairedId ?? '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF22D3EE).withValues(alpha: connected ? 0.22 : 0.08),
            const Color(0xFF16162A),
          ],
        ),
        border: Border.all(
          color: connected
              ? const Color(0xFF22D3EE).withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.35),
                ),
                child: const Icon(Icons.watch_rounded, size: 34, color: Color(0xFF22D3EE)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: connected ? const Color(0xFF22C55E) : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          connected ? 'LIVE' : (ble.pairedId != null ? 'Appairée' : 'Hors ligne'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: connected ? const Color(0xFF22C55E) : Colors.white38,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MiniStat(Icons.battery_charging_full_rounded, '$battery%'),
                        _MiniStat(Icons.memory_rounded, firmware),
                        if (liveHr != null) _MiniStat(Icons.favorite_rounded, '$liveHr bpm'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: syncing ? null : onSync,
                  icon: syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    syncing
                        ? (ble.syncProgress.isNotEmpty ? ble.syncProgress : 'Sync…')
                        : 'Sync depuis Viiv',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (ble.pairedId != null) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: onDetach,
                  child: const Text(
                    'Détacher',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF22D3EE)),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF22D3EE).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF22D3EE).withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF22D3EE)),
      ),
    );
  }
}
