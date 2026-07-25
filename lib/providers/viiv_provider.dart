import 'package:flutter/foundation.dart';
import '../models/viiv_metrics.dart';
import '../providers/app_providers.dart';
import '../services/api_client.dart';
import '../services/viiv_ble_service.dart';
import '../config/api_config.dart';

/// Viiv = données montre uniquement (style QWatch Pro). Pas de page statique.
class ViivProvider extends ChangeNotifier {
  ViivProvider(this._api) {
    ble = ViivBleService();
    ble.addListener(_onBleChanged);
    ble.init();
  }

  final ApiClient _api;
  late final ViivBleService ble;

  ViivMetrics? metrics;
  bool syncing = false;
  bool loading = false;
  String? error;
  String dataSource = '';
  List<String> endpointsTried = const [];

  bool get isLiveFromWatch => ble.isConnected && metrics != null;
  bool get canAccessDashboard => ble.isConnected;

  void _onBleChanged() {
    if (!ble.isConnected) {
      if (metrics != null && metrics!.connected) {
        metrics = metrics!.copyWith(connected: false);
      }
      notifyListeners();
      return;
    }

    if (metrics == null && ble.lastSnapshot != null) {
      metrics = ble.mergeIntoMetrics(null, ble.lastSnapshot!);
      dataSource = 'ble';
      notifyListeners();
      return;
    }

    if (metrics != null) {
      final now = DateTime.now();
      final time =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      var changed = false;
      var m = metrics!;

      if (ble.liveHr != null && ble.liveHr != m.restingHr) {
        m = m.copyWith(
          restingHr: ble.liveHr,
          hourlyHr: [
            ...m.hourlyHr.where((e) => e.hour != time).take(40),
            ViivHourlyHr(hour: time, bpm: ble.liveHr!),
          ],
        );
        changed = true;
      }
      if (ble.liveBattery != null && ble.liveBattery != m.battery) {
        m = m.copyWith(battery: ble.liveBattery);
        changed = true;
      }
      // SpO₂ / HRV / stress / énergie — live constant
      if (ble.liveSpo2 != null && ble.liveSpo2 != m.spo2) {
        m = m.copyWith(spo2: ble.liveSpo2);
        changed = true;
      }
      if (ble.liveHrv != null && ble.liveHrv != m.hrv) {
        m = m.copyWith(hrv: ble.liveHrv, hrvBaseline: ble.liveHrv);
        changed = true;
      }
      if (ble.liveStress != null && ble.liveStress != m.stress) {
        m = m.copyWith(stress: ble.liveStress);
        changed = true;
      }
      if (ble.liveEnergy != null && ble.liveEnergy != m.viivEnergy) {
        m = m.copyWith(viivEnergy: ble.liveEnergy);
        changed = true;
      }

      if (changed) {
        metrics = m.copyWith(
          connected: true,
          lastSync: 'Live',
          lastSyncAt: time,
          dataSourceLabel: 'Montre · live constant',
        );
        dataSource = 'ble';
      }
    }
    notifyListeners();
  }

  /// Au chargement : reconnecte la montre appairée, sinon écran connexion.
  Future<void> load(JoueurDataProvider joueur) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (ble.pairedId != null && ble.isSupported && !ble.isConnected) {
        await ble.reconnectPaired();
      }
      if (ble.isConnected) {
        await _applyBleSnapshot(joueur, forceSync: ble.lastSnapshot == null);
      } else {
        metrics = null;
        dataSource = '';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Sync montre uniquement — pas de fallback cloud/statique.
  Future<void> sync(JoueurDataProvider joueur) async {
    if (!ble.isConnected && ble.pairedId == null) {
      error = 'Connectez la Viiv pour synchroniser.';
      notifyListeners();
      return;
    }
    syncing = true;
    error = null;
    notifyListeners();
    try {
      if (!ble.isConnected && ble.pairedId != null) {
        await ble.reconnectPaired();
      }
      final ok = await _applyBleSnapshot(joueur, forceSync: true);
      if (!ok) {
        error = ble.error ?? 'Sync montre échouée.';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<bool> _applyBleSnapshot(JoueurDataProvider joueur, {bool forceSync = false}) async {
    final snap = forceSync || ble.lastSnapshot == null
        ? await ble.syncFromDevice()
        : ble.lastSnapshot;
    if (snap == null) return false;

    metrics = ble.mergeIntoMetrics(null, snap);
    dataSource = 'ble';
    endpointsTried = const ['bluetooth://viiv-h59'];
    await _uploadToClub(metrics!);
    notifyListeners();
    return true;
  }

  Future<void> connectDevice(ViivBleDeviceInfo info, JoueurDataProvider joueur) async {
    await ble.connect(info);
    if (ble.isConnected) {
      await _applyBleSnapshot(joueur, forceSync: true);
    }
  }

  Future<void> disconnectDevice() => ble.disconnect();

  Future<void> forgetDevice() async {
    await ble.forget();
    metrics = null;
    dataSource = '';
    notifyListeners();
  }

  Future<String> findViiv() async {
    if (!ble.isConnected) return 'Connectez la montre d’abord';
    final sent = await ble.findDeviceVibrate();
    if (sent) return 'Commande envoyée — la Viiv doit vibrer maintenant';
    return ble.error ?? 'Échec vibration montre (UART / Santé ouverte?)';
  }

  /// Mesure SpO₂ seule puis rafraîchit la page.
  Future<String> measureSpo2(JoueurDataProvider joueur) async {
    if (!ble.isConnected) return 'Connectez la montre d’abord';
    final v = await ble.measureSpo2Only();
    if (v != null) {
      if (ble.lastSnapshot != null) {
        metrics = ble.mergeIntoMetrics(null, ble.lastSnapshot!);
        dataSource = 'ble';
        notifyListeners();
      } else if (metrics != null) {
        metrics = metrics!.copyWith(spo2: v);
        notifyListeners();
      }
      return 'SpO₂ $v%';
    }
    return ble.error ?? 'SpO₂ non reçue';
  }

  Future<void> _uploadToClub(ViivMetrics m) async {
    try {
      await _api.post(ViivApiPaths.meViiv, body: {
        'deviceModel': m.deviceModel,
        'deviceId': m.deviceId,
        'firmware': m.firmware,
        'connected': m.connected,
        'lastSync': m.lastSync,
        'lastSyncAt': m.lastSyncAt,
        'battery': m.battery,
        'recovery': m.recovery,
        'recoveryDelta': m.recoveryDelta,
        'strain': m.strain,
        'strainTarget': m.strainTarget,
        'viivEnergy': m.viivEnergy,
        'sleepHours': m.sleepHours,
        'sleepPerformance': m.sleepPerformance,
        'hrv': m.hrv,
        'hrvBaseline': m.hrvBaseline,
        'restingHr': m.restingHr,
        'spo2': m.spo2,
        'stress': m.stress,
        'calories': m.calories,
        'steps': m.steps,
        'dataSourceLabel': m.dataSourceLabel,
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    ble.removeListener(_onBleChanged);
    ble.dispose();
    super.dispose();
  }
}
