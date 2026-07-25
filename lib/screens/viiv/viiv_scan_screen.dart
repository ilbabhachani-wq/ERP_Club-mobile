import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/viiv_haptics.dart';
import '../../core/widgets/odin_widgets.dart';
import '../../providers/app_providers.dart';
import '../../providers/viiv_provider.dart';
import '../../services/viiv_ble_service.dart';

/// Page dédiée — scan Viiv uniquement + connexion à la plus proche.
class ViivScanScreen extends StatefulWidget {
  const ViivScanScreen({super.key});

  @override
  State<ViivScanScreen> createState() => _ViivScanScreenState();
}

class _ViivScanScreenState extends State<ViivScanScreen> {
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ViivProvider>().ble.startScan(viivOnly: true);
    });
  }

  @override
  void dispose() {
    // Ne pas stopper le scan ici si connecté — le service gère stop avant connect
    super.dispose();
  }

  Future<void> _connect(ViivBleDeviceInfo d) async {
    if (_connecting) return;
    setState(() => _connecting = true);
    final viiv = context.read<ViivProvider>();
    final joueur = context.read<JoueurDataProvider>();
    await ViivHaptics.scanPulse();
    try {
      await viiv.connectDevice(d, joueur);
      if (!mounted) return;
      if (viiv.ble.isConnected) {
        await ViivHaptics.connected();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Viiv connectée · données live · ${d.name}'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          final p = GoRouterState.of(context).uri.path;
          context.go(p.startsWith('/analyste') ? '/analyste/viiv' : '/viiv');
        }
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _connectNearest(List<ViivBleDeviceInfo> list) async {
    if (list.isEmpty) return;
    final nearest = list.first; // déjà trié par RSSI / priorité Viiv
    await _connect(nearest);
  }

  @override
  Widget build(BuildContext context) {
    final viiv = context.watch<ViivProvider>();
    final ble = viiv.ble;
    final devices = ble.viivNearby;
    final nearest = devices.isNotEmpty ? devices.first : null;

    return OdinBackdrop(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ble.stopScan();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/viiv');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Scan Viiv GX17',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (ble.scanning)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF22D3EE)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Fermez l’app Santé / Health Life sur le téléphone, mettez la montre près du téléphone, puis scannez.',
                style: TextStyle(fontSize: 13, height: 1.35, color: Colors.white.withValues(alpha: 0.55)),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: ble.scanning || _connecting
                          ? null
                          : () async {
                              await ViivHaptics.scanPulse();
                              ble.startScan(viivOnly: true, timeout: const Duration(seconds: 18));
                            },
                      icon: Icon(ble.scanning ? Icons.hourglass_top_rounded : Icons.bluetooth_searching_rounded),
                      label: Text(ble.scanning ? 'Scan en cours…' : 'Relancer le scan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF22D3EE),
                        foregroundColor: const Color(0xFF0B0B14),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                      ),
                    ),
                  ),
                  if (nearest != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _connecting ? null : () => _connectNearest(devices),
                        icon: _connecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.near_me_rounded),
                        label: const Text('Plus proche'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (ble.error != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  ble.error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12, height: 1.3),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'MONTRES VIIV / H59 (${devices.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ble.scanning ? Icons.bluetooth_searching_rounded : Icons.watch_off_outlined,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              ble.scanning
                                  ? 'Recherche Viiv GX17 / H59…'
                                  : 'Aucune montre Viiv détectée.\nAssurez-vous qu’elle n’est pas déjà liée à Santé.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                      itemCount: devices.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final d = devices[i];
                        final isNearest = i == 0;
                        return GlassCard(
                          onTap: _connecting ? null : () => _connect(d),
                          accentColor: isNearest ? const Color(0xFF22D3EE) : AppColors.accent,
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                                ),
                                child: const Icon(Icons.watch_rounded, color: Color(0xFF22D3EE)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            d.name,
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isNearest) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF22C55E).withValues(alpha: 0.18),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'PLUS PROCHE',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF22C55E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      d.id,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${d.rssi} dBm',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                  Text(
                                    _signalLabel(d.rssi),
                                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0);
                      },
                    ),
            ),
            if (_connecting)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF22D3EE),
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }

  String _signalLabel(int rssi) {
    if (rssi >= -55) return 'Excellent';
    if (rssi >= -70) return 'Bon';
    if (rssi >= -85) return 'Moyen';
    return 'Faible';
  }
}
