import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/viiv_metrics.dart';
import 'viiv_h59_protocol.dart';

/// Snapshot BLE lu depuis la montre (protocole H59 / QWatch).
class ViivBleSnapshot {
  const ViivBleSnapshot({
    required this.deviceName,
    required this.deviceId,
    this.firmware = 'Viiv OS · H59',
    this.battery = 0,
    this.heartRate,
    this.steps,
    this.calories,
    this.distanceM,
    this.spo2,
    this.hrv,
    this.stress,
    this.sleepMinutes,
    this.sleepLightMin,
    this.sleepDeepMin,
    this.sleepRemMin,
    this.sleepAwakeMin,
    this.hourlyHr = const [],
    this.servicesFound = const [],
    this.rawHints = const {},
  });

  final String deviceName;
  final String deviceId;
  final String firmware;
  final int battery;
  final int? heartRate;
  final int? steps;
  final int? calories;
  final int? distanceM;
  final int? spo2;
  final int? hrv;
  final int? stress;
  final int? sleepMinutes;
  final int? sleepLightMin;
  final int? sleepDeepMin;
  final int? sleepRemMin;
  final int? sleepAwakeMin;
  final List<ViivHourlyHr> hourlyHr;
  final List<String> servicesFound;
  final Map<String, String> rawHints;
}

class ViivBleDeviceInfo {
  const ViivBleDeviceInfo({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
  });

  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice device;
}

enum ViivBleConnectionState { disconnected, scanning, connecting, connected, syncing, error }

/// Connexion Bluetooth directe Viiv GX17 / H59 (chipset compagnon).
class ViivBleService extends ChangeNotifier {
  static const _prefDeviceId = 'viiv_ble_device_id';
  static const _prefDeviceName = 'viiv_ble_device_name';

  /// Noms / préfixes typiques Viiv + companion H59 (écran Dispositif).
  static final _nameMatchers = [
    RegExp(r'viiv', caseSensitive: false),
    RegExp(r'gx\s?17', caseSensitive: false),
    RegExp(r'^h59', caseSensitive: false),
    RegExp(r'whoop', caseSensitive: false),
    RegExp(r'band', caseSensitive: false),
  ];

  static const batteryService = '0000180f-0000-1000-8000-00805f9b34fb';
  static const batteryLevelChar = '00002a19-0000-1000-8000-00805f9b34fb';
  static const hrService = '0000180d-0000-1000-8000-00805f9b34fb';
  static const hrMeasurementChar = '00002a37-0000-1000-8000-00805f9b34fb';
  static const deviceInfoService = '0000180a-0000-1000-8000-00805f9b34fb';
  static const firmwareChar = '00002a26-0000-1000-8000-00805f9b34fb';

  ViivBleConnectionState state = ViivBleConnectionState.disconnected;
  String? error;
  List<ViivBleDeviceInfo> nearby = [];
  /// Uniquement Viiv / H59 / GX17 (pour la page scan).
  List<ViivBleDeviceInfo> get viivNearby =>
      nearby.where((d) => _looksLikeViiv(d.name)).toList();

  BluetoothDevice? connectedDevice;
  String? pairedName;
  String? pairedId;
  int? liveBattery;
  int? liveHr;
  int? liveSpo2;
  int? liveHrv;
  int? liveStress;
  int? liveEnergy;
  ViivBleSnapshot? lastSnapshot;
  bool scanning = false;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _hrSub;
  Timer? _vitalsTimer;
  bool _vitalsBusy = false;
  int _vitalsRound = 0;
  final ViivH59Protocol _h59 = ViivH59Protocol();
  String syncProgress = '';

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  bool get isConnected =>
      state == ViivBleConnectionState.connected || state == ViivBleConnectionState.syncing;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    pairedId = prefs.getString(_prefDeviceId);
    pairedName = prefs.getString(_prefDeviceName);
    notifyListeners();
  }

  Future<bool> _ensurePermissions() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return statuses.values.every((s) => s.isGranted || s.isLimited);
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted || status.isLimited;
    }
    return false;
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 15),
    bool viivOnly = true,
  }) async {
    if (!isSupported) {
      error = 'Bluetooth indisponible sur cette plateforme (utilisez iOS/Android).';
      state = ViivBleConnectionState.error;
      notifyListeners();
      return;
    }

    final ok = await _ensurePermissions();
    if (!ok) {
      error = 'Autorisez Bluetooth (et Localisation) pour scanner la Viiv GX17.';
      state = ViivBleConnectionState.error;
      notifyListeners();
      return;
    }

    if (await FlutterBluePlus.isSupported == false) {
      error = 'Bluetooth LE non supporté sur cet appareil.';
      state = ViivBleConnectionState.error;
      notifyListeners();
      return;
    }

    await FlutterBluePlus.adapterState.where((s) => s == BluetoothAdapterState.on).first.timeout(
          const Duration(seconds: 8),
          onTimeout: () => BluetoothAdapterState.off,
        );

    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      error = 'Activez le Bluetooth pour connecter la montre.';
      state = ViivBleConnectionState.error;
      notifyListeners();
      return;
    }

    // Libérer toute connexion en cours avant scan (évite status 133)
    try {
      if (connectedDevice != null) {
        await connectedDevice!.disconnect();
      }
      for (final d in FlutterBluePlus.connectedDevices) {
        await d.disconnect().catchError((_) {});
      }
    } catch (_) {}

    nearby = [];
    scanning = true;
    state = ViivBleConnectionState.scanning;
    error = null;
    notifyListeners();

    await _scanSub?.cancel();
    await FlutterBluePlus.stopScan();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      final map = <String, ViivBleDeviceInfo>{};
      for (final r in results) {
        final name = r.device.platformName.trim().isNotEmpty
            ? r.device.platformName.trim()
            : (r.advertisementData.advName.trim().isNotEmpty
                ? r.advertisementData.advName.trim()
                : '');

        // Mode Viiv only : ignorer les "Appareil" anonymes (cause des timeouts)
        if (viivOnly) {
          if (!_looksLikeViiv(name)) continue;
        } else {
          if (name.isEmpty) continue;
          if (!_looksLikeViiv(name) && r.rssi < -70) continue;
        }

        map[r.device.remoteId.str] = ViivBleDeviceInfo(
          id: r.device.remoteId.str,
          name: name,
          rssi: r.rssi,
          device: r.device,
        );
      }
      nearby = map.values.toList()
        ..sort((a, b) {
          final aScore = _looksLikeViiv(a.name) ? 0 : 1;
          final bScore = _looksLikeViiv(b.name) ? 0 : 1;
          if (aScore != bScore) return aScore - bScore;
          return b.rssi.compareTo(a.rssi);
        });
      notifyListeners();
    });

    await FlutterBluePlus.startScan(
      timeout: timeout,
      androidUsesFineLocation: true,
      continuousUpdates: true,
    );
    scanning = false;
    if (state == ViivBleConnectionState.scanning) {
      state = connectedDevice != null
          ? ViivBleConnectionState.connected
          : ViivBleConnectionState.disconnected;
      if (viivOnly && nearby.isEmpty) {
        error =
            'Aucune Viiv / H59 trouvée. Fermez l’app Santé, rapprochez la montre, puis relancez.';
      }
    }
    notifyListeners();
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    scanning = false;
    if (state == ViivBleConnectionState.scanning) {
      state = ViivBleConnectionState.disconnected;
    }
    notifyListeners();
  }

  bool _looksLikeViiv(String name) {
    if (name.isEmpty) return false;
    return _nameMatchers.any((r) => r.hasMatch(name));
  }

  Future<void> connect(ViivBleDeviceInfo info) async {
    await stopScan();
    state = ViivBleConnectionState.connecting;
    error = null;
    notifyListeners();

    if (!_looksLikeViiv(info.name)) {
      error = 'Cet appareil n’est pas une Viiv / H59. Choisissez une montre listée Viiv.';
      state = ViivBleConnectionState.error;
      notifyListeners();
      return;
    }

    try {
      // Annuler toute connexion GATT précédente
      try {
        for (final d in FlutterBluePlus.connectedDevices) {
          await d.disconnect().catchError((_) {});
        }
        await info.device.disconnect().catchError((_) {});
        await Future<void>.delayed(const Duration(milliseconds: 600));
      } catch (_) {}

      Object? lastErr;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          await info.device.connect(
            timeout: const Duration(seconds: 35),
            autoConnect: false,
            mtu: null,
          );
          lastErr = null;
          break;
        } catch (e) {
          lastErr = e;
          await info.device.disconnect().catchError((_) {});
          await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
        }
      }
      if (lastErr != null) throw lastErr;

      try {
        await info.device.requestMtu(512);
      } catch (_) {}

      connectedDevice = info.device;
      pairedId = info.id;
      pairedName = info.name;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefDeviceId, info.id);
      await prefs.setString(_prefDeviceName, info.name);

      await _connSub?.cancel();
      _connSub = info.device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          state = ViivBleConnectionState.disconnected;
          connectedDevice = null;
          liveHr = null;
          notifyListeners();
        }
      });

      state = ViivBleConnectionState.connected;
      notifyListeners();
      // Sync + merge faits par ViivProvider.connectDevice / sync
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('133') || msg.contains('timeout') || msg.contains('Timed out')) {
        error =
            'Timeout connexion. Fermez l’app Santé, mettez la montre en mode appairage, rapprochez-la, réessayez.';
      } else {
        error = 'Connexion échouée: $e';
      }
      state = ViivBleConnectionState.error;
      notifyListeners();
    }
  }

  Future<void> reconnectPaired() async {
    if (pairedId == null) return;
    await startScan(timeout: const Duration(seconds: 8));
    final match = nearby.where((d) => d.id == pairedId).toList();
    if (match.isNotEmpty) {
      await connect(match.first);
      return;
    }
    // Essai direct par ID
    try {
      final device = BluetoothDevice.fromId(pairedId!);
      await connect(ViivBleDeviceInfo(
        id: pairedId!,
        name: pairedName ?? 'Viiv GX17',
        rssi: 0,
        device: device,
      ));
    } catch (e) {
      error = 'Montre appairée introuvable. Relancez un scan.';
      state = ViivBleConnectionState.error;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    stopLiveVitalsLoop();
    await _hrSub?.cancel();
    try {
      await _h59.stopRealtimeStream(ViivH59Protocol.rtHeartRate);
    } catch (_) {}
    await _h59.unbind();
    await connectedDevice?.disconnect();
    connectedDevice = null;
    liveHr = null;
    liveBattery = null;
    // garder liveSpo2/hrv/stress/energy en mémoire jusqu’à reconnect
    syncProgress = '';
    state = ViivBleConnectionState.disconnected;
    notifyListeners();
  }

  Future<void> forget() async {
    await disconnect();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDeviceId);
    await prefs.remove(_prefDeviceName);
    pairedId = null;
    pairedName = null;
    lastSnapshot = null;
    notifyListeners();
  }

  void _setProgress(String msg) {
    syncProgress = msg;
    notifyListeners();
  }

  /// Sync protocole H59/Colmi (Nordic UART) — données réelles montre.
  Future<ViivBleSnapshot?> syncFromDevice() async {
    final device = connectedDevice;
    if (device == null) {
      error = 'Aucune montre connectée.';
      notifyListeners();
      return null;
    }

    state = ViivBleConnectionState.syncing;
    error = null;
    _setProgress('Découverte services…');

    try {
      final bound = await _h59.bind(device);
      if (!bound) {
        error =
            'Protocole Viiv/H59 introuvable (UART). Fermez Santé, reconnectez, réessayez.';
        state = ViivBleConnectionState.connected;
        notifyListeners();
        return null;
      }

      _setProgress('Sync horloge…');
      await _h59.setTime();
      await _h59.enableHrLogging();

      _setProgress('Batterie…');
      final battery = await _h59.battery() ?? liveBattery ?? 0;
      liveBattery = battery;

      // SpO₂ en premier — capteur plus fiable avant les autres mesures
      _setProgress('SpO₂ (immobile ~40–50s, montre serrée)…');
      var spo2 = await _h59.measureSpo2();
      if (spo2 != null) {
        _setProgress('SpO₂ $spo2% OK');
        await Future<void>.delayed(const Duration(milliseconds: 400));
      } else {
        _setProgress('SpO₂ non reçu — on continue…');
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      _setProgress('Pas & calories…');
      final activity = await _h59.stepsToday();

      _setProgress('Mesure FC (gardez la montre au poignet)…');
      var hr = await _h59.measureRealtime(
        ViivH59Protocol.rtHeartRate,
        timeout: const Duration(seconds: 28),
        want: 5,
      );

      _setProgress('Courbe FC du jour…');
      final hrCurve = await _h59.heartRateCurveToday();
      hr ??= hrCurve.last;
      hr ??= liveHr;
      if (hr != null) liveHr = hr;

      _setProgress('HRV / stress…');
      final hrv = await _h59.hrvTodayMedian() ??
          await _h59.measureRealtime(
            ViivH59Protocol.rtHrv,
            timeout: const Duration(seconds: 18),
            want: 3,
          );
      final stress = await _h59.stressTodayMedian() ??
          await _h59.measureRealtime(
            ViivH59Protocol.rtStress,
            timeout: const Duration(seconds: 15),
            want: 3,
          );

      _setProgress('Sommeil…');
      final sleep = await _h59.sleepEstimate();

      if (spo2 == null) {
        _setProgress('SpO₂ 2e tentative…');
        spo2 = await _h59.measureSpo2();
        if (spo2 != null) _setProgress('SpO₂ $spo2% OK');
      }

      lastSnapshot = ViivBleSnapshot(
        deviceName: pairedName ?? device.platformName,
        deviceId: device.remoteId.str,
        firmware: 'Viiv OS · H59/QWatch',
        battery: battery,
        heartRate: hr,
        steps: activity.steps > 0 ? activity.steps : 0,
        calories: activity.calories > 0 ? activity.calories : 0,
        distanceM: activity.distanceM > 0 ? activity.distanceM : 0,
        spo2: spo2,
        hrv: hrv,
        stress: stress,
        sleepMinutes: sleep != null ? (sleep.hours * 60).round() : null,
        sleepLightMin: sleep?.light,
        sleepDeepMin: sleep?.deep,
        sleepRemMin: sleep?.rem,
        sleepAwakeMin: sleep?.awake,
        hourlyHr: [
          ...hrCurve.points.map((p) => ViivHourlyHr(hour: p.hour, bpm: p.bpm)),
          if (hr != null)
            ViivHourlyHr(
              hour:
                  '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              bpm: hr,
            ),
        ],
        servicesFound: const [ViivH59Protocol.serviceUuid],
        rawHints: {
          'protocol': 'colmi-h59-uart',
          'steps': '${activity.steps}',
          'cal': '${activity.calories}',
          'dist_m': '${activity.distanceM}',
          'spo2': spo2?.toString() ?? 'null',
          if (stress != null) 'stress': '$stress',
          if (sleep != null) 'sleep_h': sleep.hours.toStringAsFixed(1),
        },
      );

      // Seed live vitals depuis le sync
      if (spo2 != null) liveSpo2 = spo2;
      if (hrv != null) liveHrv = hrv;
      if (stress != null) liveStress = stress;
      _recomputeLiveEnergy();

      // Continuer les notifs FC + boucle SpO₂/HRV/stress/énergie
      // ignore: unawaited_futures
      _listenLiveHr();
      startLiveVitalsLoop();

      _setProgress('Sync terminée');
      state = ViivBleConnectionState.connected;
      notifyListeners();
      return lastSnapshot;
    } catch (e) {
      error = 'Sync Viiv échouée: $e';
      _setProgress('');
      state = ViivBleConnectionState.connected;
      notifyListeners();
      return null;
    }
  }

  Future<void> _listenLiveHr() async {
    await _hrSub?.cancel();
    _hrSub = _h59.txStream.listen((p) {
      if (p.length < 4) return;
      if (p[0] == ViivH59Protocol.cmdRealtime &&
          p[1] == ViivH59Protocol.rtHeartRate &&
          p[2] == 0 &&
          p[3] > 0) {
        liveHr = p[3];
        _recomputeLiveEnergy();
        notifyListeners();
      }
      if (p[0] == ViivH59Protocol.cmdRealtime && p.length >= 4 && p[2] == 0) {
        final v = p[3];
        if (p[1] == ViivH59Protocol.rtSpo2 && v >= 70 && v <= 100) {
          liveSpo2 = v;
          _patchLiveIntoSnapshot();
          _recomputeLiveEnergy();
          notifyListeners();
        } else if (p[1] == ViivH59Protocol.rtHrv && v >= 20 && v <= 200) {
          liveHrv = v;
          _patchLiveIntoSnapshot();
          _recomputeLiveEnergy();
          notifyListeners();
        } else if (p[1] == ViivH59Protocol.rtStress && v > 0 && v <= 100) {
          liveStress = v;
          _patchLiveIntoSnapshot();
          _recomputeLiveEnergy();
          notifyListeners();
        }
      }
    });
    // ignore: unawaited_futures
    _h59.startRealtimeStream(ViivH59Protocol.rtHeartRate);
  }

  /// Boucle continue : SpO₂ / HRV / stress / énergie (touré).
  void startLiveVitalsLoop() {
    _vitalsTimer?.cancel();
    _vitalsTimer = Timer.periodic(const Duration(seconds: 50), (_) {
      // ignore: unawaited_futures
      _tickLiveVitals();
    });
    // Première mesure rapide après sync
    // ignore: unawaited_futures
    Future<void>.delayed(const Duration(seconds: 3), _tickLiveVitals);
  }

  void stopLiveVitalsLoop() {
    _vitalsTimer?.cancel();
    _vitalsTimer = null;
  }

  Future<void> _tickLiveVitals() async {
    if (_vitalsBusy) return;
    if (!isConnected || state == ViivBleConnectionState.syncing) return;
    if (_h59.rx == null || connectedDevice == null) return;

    _vitalsBusy = true;
    try {
      final round = _vitalsRound++ % 3;
      if (round == 0) {
        syncProgress = 'Live HRV…';
        notifyListeners();
        final h = await _h59.measureRealtime(
          ViivH59Protocol.rtHrv,
          timeout: const Duration(seconds: 22),
          want: 2,
          minValid: 20,
          maxValid: 200,
        );
        if (h != null) liveHrv = h;
      } else if (round == 1) {
        syncProgress = 'Live stress…';
        notifyListeners();
        final s = await _h59.measureRealtime(
          ViivH59Protocol.rtStress,
          timeout: const Duration(seconds: 20),
          want: 2,
          minValid: 1,
          maxValid: 100,
        );
        if (s != null) liveStress = s;
      } else {
        syncProgress = 'Live SpO₂…';
        notifyListeners();
        final o = await _h59.measureRealtime(
          ViivH59Protocol.rtSpo2,
          timeout: const Duration(seconds: 35),
          want: 2,
          minValid: 70,
          maxValid: 100,
        );
        if (o != null) {
          liveSpo2 = o;
        } else {
          // Fallback rapide Colmi-only sans les 3 protocoles longs
          final o2 = await _h59.measureSpo2();
          if (o2 != null) liveSpo2 = o2;
        }
      }

      _recomputeLiveEnergy();
      _patchLiveIntoSnapshot();
      syncProgress = '';
      // Relancer FC stream après une mesure
      // ignore: unawaited_futures
      _h59.startRealtimeStream(ViivH59Protocol.rtHeartRate);
      notifyListeners();
    } catch (_) {
      syncProgress = '';
      notifyListeners();
    } finally {
      _vitalsBusy = false;
    }
  }

  void _recomputeLiveEnergy() {
    final hrv = liveHrv ?? lastSnapshot?.hrv ?? 0;
    final spo2 = liveSpo2 ?? lastSnapshot?.spo2 ?? 0;
    final stress = liveStress ?? lastSnapshot?.stress ?? 0;
    final hr = liveHr ?? lastSnapshot?.heartRate ?? 0;
    final steps = lastSnapshot?.steps ?? 0;
    final sleepMin = lastSnapshot?.sleepMinutes ?? 0;
    final sleepH = sleepMin / 60.0;

    final recovery = (hrv == 0 && sleepH == 0 && spo2 == 0)
        ? (liveEnergy ?? 0)
        : _clampInt(
            ((hrv > 0 ? (hrv / 55.0) * 50 : 30) +
                    (sleepH / 8.0 * 35) +
                    (spo2 >= 96 ? 12 : spo2 > 0 ? 5 : 0) +
                    (hr > 0 && hr < 70 ? 8 : 0) -
                    (stress > 60 ? 10 : 0))
                .round(),
            0,
            99,
          );
    final strain = (steps / 1100.0) + (hr > 110 ? (hr - 110) / 18.0 : 0);
    liveEnergy = _clampInt(100 - (strain * 3.5).round() + (recovery ~/ 8), 0, 100);
  }

  void _patchLiveIntoSnapshot() {
    final s = lastSnapshot;
    if (s == null) return;
    lastSnapshot = ViivBleSnapshot(
      deviceName: s.deviceName,
      deviceId: s.deviceId,
      firmware: s.firmware,
      battery: liveBattery ?? s.battery,
      heartRate: liveHr ?? s.heartRate,
      steps: s.steps,
      calories: s.calories,
      distanceM: s.distanceM,
      spo2: liveSpo2 ?? s.spo2,
      hrv: liveHrv ?? s.hrv,
      stress: liveStress ?? s.stress,
      sleepMinutes: s.sleepMinutes,
      sleepLightMin: s.sleepLightMin,
      sleepDeepMin: s.sleepDeepMin,
      sleepRemMin: s.sleepRemMin,
      sleepAwakeMin: s.sleepAwakeMin,
      hourlyHr: s.hourlyHr,
      servicesFound: s.servicesFound,
      rawHints: {
        ...s.rawHints,
        if (liveSpo2 != null) 'spo2': '$liveSpo2',
        if (liveHrv != null) 'hrv': '$liveHrv',
        if (liveStress != null) 'stress': '$liveStress',
        if (liveEnergy != null) 'energy': '$liveEnergy',
      },
    );
  }

  /// Mesure SpO₂ seule (bouton dédié) et met à jour le snapshot.
  Future<int?> measureSpo2Only() async {
    final device = connectedDevice;
    if (device == null) {
      error = 'Connectez d’abord la Viiv.';
      notifyListeners();
      return null;
    }
    try {
      if (_h59.rx == null) {
        final ok = await _h59.bind(device);
        if (!ok) {
          error = 'UART Viiv introuvable.';
          notifyListeners();
          return null;
        }
      }
      _setProgress('SpO₂ (immobile ~40–50s)…');
      state = ViivBleConnectionState.syncing;
      notifyListeners();
      final spo2 = await _h59.measureSpo2();
      if (spo2 != null && lastSnapshot != null) {
        lastSnapshot = ViivBleSnapshot(
          deviceName: lastSnapshot!.deviceName,
          deviceId: lastSnapshot!.deviceId,
          firmware: lastSnapshot!.firmware,
          battery: lastSnapshot!.battery,
          heartRate: lastSnapshot!.heartRate,
          steps: lastSnapshot!.steps,
          calories: lastSnapshot!.calories,
          distanceM: lastSnapshot!.distanceM,
          spo2: spo2,
          hrv: lastSnapshot!.hrv,
          stress: lastSnapshot!.stress,
          sleepMinutes: lastSnapshot!.sleepMinutes,
          sleepLightMin: lastSnapshot!.sleepLightMin,
          sleepDeepMin: lastSnapshot!.sleepDeepMin,
          sleepRemMin: lastSnapshot!.sleepRemMin,
          sleepAwakeMin: lastSnapshot!.sleepAwakeMin,
          hourlyHr: lastSnapshot!.hourlyHr,
          servicesFound: lastSnapshot!.servicesFound,
          rawHints: {...lastSnapshot!.rawHints, 'spo2': '$spo2'},
        );
        _setProgress('SpO₂ $spo2% OK');
        error = null;
      } else if (spo2 == null) {
        error = 'SpO₂ non reçu. Montre serrée, immobile, doigt/poignet bien en place.';
        _setProgress('');
      }
      state = ViivBleConnectionState.connected;
      notifyListeners();
      return spo2;
    } catch (e) {
      error = 'SpO₂ échouée: $e';
      _setProgress('');
      state = ViivBleConnectionState.connected;
      notifyListeners();
      return null;
    }
  }

  /// Vibration sur la montre (commande Find Device Colmi 0x50).
  Future<bool> findDeviceVibrate() async {
    final device = connectedDevice;
    if (device == null) {
      error = 'Connectez d’abord la Viiv.';
      notifyListeners();
      return false;
    }
    try {
      if (_h59.rx == null) {
        final ok = await _h59.bind(device);
        if (!ok) {
          error = 'UART Viiv introuvable — impossible de vibrer la montre.';
          notifyListeners();
          return false;
        }
      }
      await _h59.findDevice();
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = 'Vibration montre échouée: $e';
      notifyListeners();
      return false;
    }
  }

  /// Construit les métriques page UNIQUEMENT depuis la montre (rien de statique).
  ViivMetrics mergeIntoMetrics(ViivMetrics? _, ViivBleSnapshot snap) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final hr = liveHr ?? snap.heartRate ?? 0;
    final steps = snap.steps ?? 0;
    final calories = snap.calories ?? 0;
    final distM = snap.distanceM ?? 0;
    final spo2 = liveSpo2 ?? snap.spo2 ?? 0;
    final hrv = liveHrv ?? snap.hrv ?? 0;
    final stress = liveStress ??
        snap.stress ??
        int.tryParse(snap.rawHints['stress'] ?? '') ??
        0;
    final sleepH = snap.sleepMinutes != null ? snap.sleepMinutes! / 60.0 : 0.0;
    final sleepNeed = 8.0;
    final sleepPerf = sleepH > 0 ? ((sleepH / sleepNeed) * 100).round().clamp(0, 100) : 0;

    final recovery = hr == 0 && hrv == 0 && sleepH == 0
        ? 0
        : _clampInt(
            ((hrv > 0 ? (hrv / 55.0) * 50 : 30) +
                    (sleepH / 8.0 * 35) +
                    (spo2 >= 96 ? 12 : spo2 > 0 ? 5 : 0) +
                    (hr > 0 && hr < 70 ? 8 : 0))
                .round(),
            0,
            99,
          );
    final strain = steps == 0 && hr == 0
        ? 0.0
        : _clampDouble(
            (steps / 1100.0) + (hr > 110 ? (hr - 110) / 18.0 : 0),
            0,
            21,
          );
    final energy = liveEnergy ??
        (recovery == 0 && strain == 0
            ? 0
            : _clampInt(100 - (strain * 3.5).round() + (recovery ~/ 8), 0, 100));

    final stages = ViivSleepStages(
      awake: (snap.sleepAwakeMin ?? 0) / 60.0,
      light: (snap.sleepLightMin ?? 0) / 60.0,
      sws: (snap.sleepDeepMin ?? 0) / 60.0,
      rem: (snap.sleepRemMin ?? 0) / 60.0,
    );

    // Zones FC dérivées de la courbe réelle uniquement
    final zones = <ViivHrZone>[];
    if (snap.hourlyHr.isNotEmpty) {
      var z1 = 0, z2 = 0, z3 = 0, z4 = 0, z5 = 0;
      for (final p in snap.hourlyHr) {
        final b = p.bpm;
        if (b < 100) {
          z1 += 5;
        } else if (b < 120) {
          z2 += 5;
        } else if (b < 140) {
          z3 += 5;
        } else if (b < 160) {
          z4 += 5;
        } else {
          z5 += 5;
        }
      }
      if (z1 > 0) zones.add(ViivHrZone(zone: 'Repos', minutes: z1, color: '#64748B'));
      if (z2 > 0) zones.add(ViivHrZone(zone: 'Fatburn', minutes: z2, color: '#22D3EE'));
      if (z3 > 0) zones.add(ViivHrZone(zone: 'Cardio', minutes: z3, color: '#F59E0B'));
      if (z4 > 0) zones.add(ViivHrZone(zone: 'Seuil', minutes: z4, color: '#F97316'));
      if (z5 > 0) zones.add(ViivHrZone(zone: 'Peak', minutes: z5, color: '#EF4444'));
    }

    final log = <ViivSyncEvent>[
      ViivSyncEvent(time: time, type: 'Sync QWatch/H59', status: 'ok'),
      ViivSyncEvent(time: time, type: 'Batterie ${snap.battery}%', status: 'ok'),
      if (hr > 0) ViivSyncEvent(time: time, type: 'FC $hr bpm', status: 'ok'),
      if (steps > 0) ViivSyncEvent(time: time, type: 'Pas $steps', status: 'ok'),
      if (calories > 0) ViivSyncEvent(time: time, type: 'Calories $calories', status: 'ok'),
      if (distM > 0) ViivSyncEvent(time: time, type: 'Distance ${(distM / 1000).toStringAsFixed(2)} km', status: 'ok'),
      if (spo2 > 0) ViivSyncEvent(time: time, type: 'SpO₂ $spo2%', status: 'ok'),
      if (hrv > 0) ViivSyncEvent(time: time, type: 'HRV $hrv ms', status: 'ok'),
      if (stress > 0) ViivSyncEvent(time: time, type: 'Stress $stress', status: 'ok'),
      if (sleepH > 0) ViivSyncEvent(time: time, type: 'Sommeil ${sleepH.toStringAsFixed(1)} h', status: 'ok'),
    ];

    return ViivMetrics(
      connected: true,
      lastSync: 'Viiv live',
      lastSyncAt: time,
      battery: snap.battery,
      deviceId: snap.deviceId,
      deviceModel: 'Viiv GX17',
      firmware: snap.firmware,
      restingHr: hr,
      steps: steps,
      calories: calories,
      spo2: spo2,
      hrv: hrv,
      hrvBaseline: hrv > 0 ? hrv : 0,
      sleepHours: sleepH,
      sleepPerformance: sleepPerf,
      sleepNeed: sleepNeed,
      sleepStages: stages,
      recovery: recovery,
      recoveryDelta: 0,
      strain: strain,
      strainTarget: 15,
      viivEnergy: energy,
      stress: stress,
      skinTemp: 0,
      respiratoryRate: 0,
      vo2Max: 0,
      gpsActivity: distM > 0
          ? 'Distance ${(distM / 1000).toStringAsFixed(2)} km'
          : 'Viiv BLE · ${snap.deviceName}',
      readiness: recovery >= 70
          ? 'Prêt'
          : recovery >= 50
              ? 'Modéré'
              : recovery > 0
                  ? 'Repos'
                  : '—',
      fitToPlay: recovery >= 45 && (stress == 0 || stress < 85),
      fitnessScore: recovery > 0 || stress > 0
          ? _clampInt(((recovery + (100 - stress.clamp(0, 100))) / 2).round(), 0, 99)
          : 0,
      injuryRisk: stress > 70 ? 'High' : stress > 40 ? 'Med' : 'Low',
      syncLog: log,
      dataSourceLabel: 'Montre · QWatch/H59',
      hourlyHr: snap.hourlyHr,
      zones: zones,
      weeklyStrain: const [],
      aiInsight: '',
      aiRecommendations: const [],
      aiConfidence: 0,
      todayGoals: const [],
    );
  }

  int get battery => liveBattery ?? lastSnapshot?.battery ?? 0;

  int _clampInt(int v, int min, int max) => v < min ? min : (v > max ? max : v);
  double _clampDouble(double v, double min, double max) => v < min ? min : (v > max ? max : v);

  @override
  void dispose() {
    stopLiveVitalsLoop();
    _scanSub?.cancel();
    _connSub?.cancel();
    _hrSub?.cancel();
    _h59.dispose();
    super.dispose();
  }
}
