import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Protocole Colmi/QC / H59 (Nordic UART) — même stack que Viiv GX17 companion.
/// Réf: OpenH59 + Colmi BLE API.
class ViivH59Protocol {
  static const rxUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const txUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';
  static const serviceUuid = '6e40fff0-b5a3-f393-e0a9-e50e24dcca9e';
  // Canal "bc" riche (SpO₂ historique QWatch Pro / OpenH59)
  static const bcWriteUuid = 'de5bf72a-d711-4e47-af26-65e3012a5dc7';
  static const bcNotifyUuid = 'de5bf729-d711-4e47-af26-65e3012a5dc7';
  static const bcMagic = 0xbc;
  static const bcSpo2 = 0x2a;
  static const bcInit = 0x30;

  static const cmdSetTime = 1;
  static const cmdBattery = 3;
  static const cmdSleepHistory = 13;
  static const cmdHrHistory = 21;
  static const cmdStressHistory = 55;
  static const cmdHrvHistory = 57;
  static const cmdSteps = 67;
  static const cmdHrLog = 22;
  static const cmdFindDevice = 80;
  static const cmdBlink = 15;
  static const cmdPushMessage = 114;
  static const cmdRealtime = 105;
  static const cmdRealtimeStop = 106;
  static const pushPhoneAction = 4;

  static const rtHeartRate = 1;
  static const rtBloodPressure = 2;
  static const rtSpo2 = 3;
  static const rtStress = 8;
  static const rtHrv = 10;

  BluetoothCharacteristic? rx;
  BluetoothCharacteristic? tx;
  BluetoothCharacteristic? bcWrite;
  BluetoothCharacteristic? bcNotify;

  final _txCtrl = StreamController<List<int>>.broadcast();
  final _bcCtrl = StreamController<List<int>>.broadcast();
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<int>>? _bcSub;
  final Map<int, List<int>> _lastByCmd = {};
  final List<List<int>> _histBuffer = [];
  bool _collecting = false;
  final _bcBuf = BytesBuilder();

  Stream<List<int>> get txStream => _txCtrl.stream;

  static bool _uuidEq(Guid a, String b) => a.str128.toLowerCase() == b.toLowerCase();

  /// Bind RX/TX après discoverServices.
  Future<bool> bind(BluetoothDevice device) async {
    await unbind();
    final services = await device.discoverServices();
    for (final s in services) {
      for (final c in s.characteristics) {
        if (_uuidEq(c.uuid, rxUuid)) rx = c;
        if (_uuidEq(c.uuid, txUuid)) tx = c;
        if (_uuidEq(c.uuid, bcWriteUuid)) bcWrite = c;
        if (_uuidEq(c.uuid, bcNotifyUuid)) bcNotify = c;
      }
    }
    // Fallback: chercher dans tout service Nordic-like
    if (rx == null || tx == null) {
      for (final s in services) {
        for (final c in s.characteristics) {
          final u = c.uuid.str128.toLowerCase();
          if (u.contains('6e400002') || u.endsWith('0002-b5a3-f393-e0a9-e50e24dcca9e')) {
            rx = c;
          }
          if (u.contains('6e400003') || u.endsWith('0003-b5a3-f393-e0a9-e50e24dcca9e')) {
            tx = c;
          }
        }
      }
    }

    if (rx == null || tx == null) return false;

    if (tx!.properties.notify || tx!.properties.indicate) {
      await tx!.setNotifyValue(true);
      await _notifySub?.cancel();
      _notifySub = tx!.onValueReceived.listen((data) {
        if (data.isEmpty) return;
        _lastByCmd[data[0]] = List<int>.from(data);
        if (_collecting) _histBuffer.add(List<int>.from(data));
        if (!_txCtrl.isClosed) _txCtrl.add(List<int>.from(data));
      });
    }

    if (bcNotify != null && (bcNotify!.properties.notify || bcNotify!.properties.indicate)) {
      try {
        await bcNotify!.setNotifyValue(true);
        await _bcSub?.cancel();
        _bcSub = bcNotify!.onValueReceived.listen((data) {
          if (data.isEmpty || _bcCtrl.isClosed) return;
          _bcBuf.add(data);
          _flushBcFrames();
        });
      } catch (_) {
        bcWrite = null;
        bcNotify = null;
      }
    }
    return true;
  }

  void _flushBcFrames() {
    final buf = _bcBuf.toBytes();
    var offset = 0;
    while (true) {
      final i = buf.indexOf(bcMagic, offset);
      if (i < 0) {
        _bcBuf.clear();
        if (offset < buf.length) _bcBuf.add(buf.sublist(offset));
        return;
      }
      if (i + 6 > buf.length) {
        _bcBuf.clear();
        _bcBuf.add(buf.sublist(i));
        return;
      }
      final ln = buf[i + 2] | (buf[i + 3] << 8);
      final total = 6 + ln;
      if (i + total > buf.length) {
        _bcBuf.clear();
        _bcBuf.add(buf.sublist(i));
        return;
      }
      _bcCtrl.add(buf.sublist(i, i + total));
      offset = i + total;
    }
  }

  static int _crc16Modbus(List<int> data) {
    var crc = 0xFFFF;
    for (final b in data) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? ((crc >> 1) ^ 0xA001) : (crc >> 1);
      }
    }
    return crc & 0xFFFF;
  }

  Uint8List _bcFrame(int typ, [List<int> body = const []]) {
    final crc = _crc16Modbus(body);
    return Uint8List.fromList([
      bcMagic,
      typ & 0xff,
      body.length & 0xff,
      (body.length >> 8) & 0xff,
      crc & 0xff,
      (crc >> 8) & 0xff,
      ...body,
    ]);
  }

  Future<void> unbind() async {
    await _notifySub?.cancel();
    await _bcSub?.cancel();
    _notifySub = null;
    _bcSub = null;
    rx = null;
    tx = null;
    bcWrite = null;
    bcNotify = null;
    _lastByCmd.clear();
    _bcBuf.clear();
  }

  static int checksum(List<int> packet) {
    var s = 0;
    for (final b in packet) {
      s += b;
    }
    return s & 255;
  }

  static Uint8List makePacket(int cmd, [List<int> sub = const []]) {
    final p = Uint8List(16);
    p[0] = cmd & 0xff;
    for (var i = 0; i < sub.length && i < 14; i++) {
      p[i + 1] = sub[i] & 0xff;
    }
    p[15] = checksum(p.sublist(0, 15));
    return p;
  }

  static int _toBcd(int v) => ((v ~/ 10) << 4) | (v % 10);

  Future<void> _write(Uint8List packet) async {
    final c = rx;
    if (c == null) throw StateError('RX characteristic manquante');
    // OpenH59 / Colmi: write without response sur RX UART
    final noRsp = c.properties.writeWithoutResponse;
    try {
      await c.write(packet, withoutResponse: noRsp || !c.properties.write);
    } catch (_) {
      await c.write(packet, withoutResponse: false);
    }
  }

  Future<List<int>?> _waitCmd(int cmd, {Duration timeout = const Duration(seconds: 3)}) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final p = _lastByCmd[cmd];
      if (p != null) return p;
      await Future<void>.delayed(const Duration(milliseconds: 80));
    }
    return _lastByCmd[cmd];
  }

  Future<void> setTime() async {
    final now = DateTime.now();
    final sub = [
      _toBcd(now.year % 100),
      _toBcd(now.month),
      _toBcd(now.day),
      _toBcd(now.hour),
      _toBcd(now.minute),
      _toBcd(now.second),
      1,
    ];
    _lastByCmd.remove(cmdSetTime);
    await _write(makePacket(cmdSetTime, sub));
    await _waitCmd(cmdSetTime, timeout: const Duration(seconds: 2));
  }

  /// Active le moteur / bip de la montre (pas le téléphone).
  /// Colmi Find Device (0x50) + push appel (0x72) + blink (0x0F).
  Future<void> findDevice() async {
    // 1) Find Device officiel Colmi — sur montres = vibration
    for (var i = 0; i < 3; i++) {
      await _write(makePacket(cmdFindDevice, [85, 170]));
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    // 2) Simulation notification appel → moteur vibratoire H59/QWatch
    await _write(makePacket(cmdPushMessage, [pushPhoneAction, 1, 0, 0]));
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await _write(makePacket(cmdPushMessage, [pushPhoneAction, 2, 0, 0]));
    // 3) Blink / alertes firmware variantes
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _write(makePacket(cmdBlink));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await _write(makePacket(0x61));
  }

  Future<void> enableHrLogging() async {
    await _write(makePacket(cmdHrLog, [2, 1, 5]));
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// Démarre un stream realtime sans attendre la fin (FC live).
  Future<void> startRealtimeStream(int type) async {
    try {
      await _write(makePacket(cmdRealtime, [type, 1]));
    } catch (_) {}
  }

  Future<void> stopRealtimeStream(int type) async {
    try {
      await _write(makePacket(cmdRealtimeStop, [type, 0, 0]));
    } catch (_) {}
  }

  Future<int?> battery() async {
    _lastByCmd.remove(cmdBattery);
    await _write(makePacket(cmdBattery));
    final p = await _waitCmd(cmdBattery);
    if (p == null || p.length < 2) return null;
    return p[1];
  }

  /// Passes + calories du jour (slots 15 min).
  Future<({int steps, int calories, int distanceM})> stepsToday() async {
    _histBuffer.clear();
    _collecting = true;
    await _write(makePacket(cmdSteps, [0, 0x0f, 0x00, 0x5f, 0x01]));
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    _collecting = false;

    var steps = 0;
    var cal = 0;
    var dist = 0;
    for (final p in _histBuffer) {
      if (p.isEmpty || p[0] != cmdSteps) continue;
      if (p.length < 13) continue;
      if (p[1] == 0xff || p[1] == 0xf0) continue;
      cal += p[7] | (p[8] << 8);
      steps += p[9] | (p[10] << 8);
      dist += p[11] | (p[12] << 8);
    }
    return (steps: steps, calories: cal, distanceM: dist);
  }

  /// Mesure temps réel (FC / SpO2 / stress / HRV) — aligné OpenH59 + Colmi.
  Future<int?> measureRealtime(
    int type, {
    Duration timeout = const Duration(seconds: 28),
    int want = 5,
    int minValid = 1,
    int maxValid = 255,
  }) async {
    final values = <int>[];
    // Queue dédiée pour ne pas perdre de paquets pendant la mesure
    final q = StreamController<List<int>>();
    final subListen = txStream.listen((p) {
      if (!q.isClosed) q.add(p);
    });

    // Pause courte pour laisser le capteur se libérer après une mesure précédente
    await Future<void>.delayed(const Duration(milliseconds: 500));

    await _write(makePacket(cmdRealtime, [type, 1])); // START
    final deadline = DateTime.now().add(timeout);
    try {
      while (DateTime.now().isBefore(deadline) && values.length < want) {
        final packet = await q.stream.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => <int>[],
        );
        if (packet.isEmpty) continue;
        if (packet[0] != cmdRealtime) continue;
        if (packet.length < 4 || packet[1] != type) continue;
        // byte[2] != 0 → fin / erreur (OpenH59 + Colmi)
        if (packet[2] != 0) break;
        final v = packet[3];
        if (v >= minValid && v <= maxValid) values.add(v);
      }
    } catch (_) {
    } finally {
      try {
        await _write(makePacket(cmdRealtimeStop, [type, 0, 0]));
      } catch (_) {}
      try {
        // Stop alternatif (action=4 sur cmd 105) — certains firmwares QWatch
        await _write(makePacket(cmdRealtime, [type, 4]));
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await subListen.cancel();
      await q.close();
    }

    if (values.isEmpty) return null;
    values.sort();
    return values[values.length ~/ 2];
  }

  /// SpO₂ — plusieurs variantes firmware (Colmi 105/3, legacy 0x6B, notify 115, canal bc).
  Future<int?> measureSpo2() async {
    var v = await _measureSpo2Colmi();
    if (v != null) return v;

    v = await _measureSpo2Legacy6B();
    if (v != null) return v;

    v = await _measureSpo2HealthCheck();
    if (v != null) return v;

    // Dernier recours : dernière SpO₂ horaire via canal "bc" (sans compte app)
    v = await _spo2FromBcHistory();
    return v;
  }

  Future<int?> _measureSpo2Colmi() async {
    final values = <int>[];
    final q = StreamController<List<int>>();
    final sub = txStream.listen((p) {
      if (!q.isClosed) q.add(p);
    });

    await Future<void>.delayed(const Duration(milliseconds: 600));
    await _write(makePacket(cmdRealtime, [rtSpo2, 1]));

    final deadline = DateTime.now().add(const Duration(seconds: 50));
    try {
      while (DateTime.now().isBefore(deadline) && values.length < 5) {
        final packet = await q.stream.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => <int>[],
        );
        if (packet.isEmpty) continue;

        // Réponse classique realtime 105
        if (packet[0] == cmdRealtime && packet.length >= 4 && packet[1] == rtSpo2) {
          if (packet[2] != 0) {
            // Fin : parfois la dernière valeur utile est encore dans le paquet
            for (final b in packet.skip(3).take(4)) {
              if (b >= 70 && b <= 100) values.add(b);
            }
            break;
          }
          for (final b in packet.skip(3).take(4)) {
            if (b >= 70 && b <= 100) values.add(b);
          }
          continue;
        }

        // Device Notify 115 / BloodOxygen=3
        if (packet[0] == 115 && packet.length >= 4 && packet[1] == 3) {
          for (final b in packet.skip(2).take(4)) {
            if (b >= 70 && b <= 100) values.add(b);
          }
        }
      }
    } catch (_) {
    } finally {
      try {
        await _write(makePacket(cmdRealtimeStop, [rtSpo2, 0, 0]));
      } catch (_) {}
      try {
        await _write(makePacket(cmdRealtime, [rtSpo2, 4]));
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await sub.cancel();
      await q.close();
    }

    if (values.isEmpty) return null;
    values.sort();
    return values[values.length ~/ 2];
  }

  Future<int?> _measureSpo2Legacy6B() async {
    final values = <int>[];
    final q = StreamController<List<int>>();
    final sub = txStream.listen((p) {
      if (!q.isClosed) q.add(p);
    });

    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Format Colmi 16 bytes + write brut court (selon firmwares)
    await _write(makePacket(0x6b, [0x00]));
    try {
      await rx?.write(Uint8List.fromList([0x6b, 0x00]), withoutResponse: true);
    } catch (_) {}

    final deadline = DateTime.now().add(const Duration(seconds: 40));
    try {
      while (DateTime.now().isBefore(deadline) && values.length < 4) {
        final packet = await q.stream.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => <int>[],
        );
        if (packet.isEmpty) continue;
        // Accepte 0x6B ou 105/type3 ou 115/type3
        if (packet[0] == 0x6b ||
            (packet[0] == cmdRealtime && packet.length > 1 && packet[1] == rtSpo2) ||
            (packet[0] == 115 && packet.length > 1 && packet[1] == 3)) {
          for (final b in packet.skip(1).take(6)) {
            if (b >= 70 && b <= 100) values.add(b);
          }
        } else {
          // Heuristique : cherche une SpO₂ plausible dans le paquet
          for (final b in packet) {
            if (b >= 90 && b <= 100) values.add(b);
          }
        }
      }
    } catch (_) {
    } finally {
      try {
        await _write(makePacket(0x6b, [0xff]));
      } catch (_) {}
      try {
        await rx?.write(Uint8List.fromList([0x6b, 0xff]), withoutResponse: true);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await sub.cancel();
      await q.close();
    }

    if (values.isEmpty) return null;
    values.sort();
    return values[values.length ~/ 2];
  }

  Future<int?> _measureSpo2HealthCheck() async {
    final values = <int>[];
    final q = StreamController<List<int>>();
    final sub = txStream.listen((p) {
      if (!q.isClosed) q.add(p);
    });

    await Future<void>.delayed(const Duration(milliseconds: 400));
    await _write(makePacket(cmdRealtime, [5, 1])); // HEALTH_CHECK start

    final deadline = DateTime.now().add(const Duration(seconds: 35));
    try {
      while (DateTime.now().isBefore(deadline) && values.length < 4) {
        final packet = await q.stream.first.timeout(
          const Duration(seconds: 2),
          onTimeout: () => <int>[],
        );
        if (packet.isEmpty || packet[0] != cmdRealtime) continue;
        if (packet.length < 4) continue;
        if (packet[1] != 5 && packet[1] != rtSpo2) continue;
        if (packet[2] != 0) {
          for (final b in packet.skip(3).take(5)) {
            if (b >= 70 && b <= 100) values.add(b);
          }
          break;
        }
        for (final b in packet.skip(3).take(5)) {
          if (b >= 70 && b <= 100) values.add(b);
        }
      }
    } catch (_) {
    } finally {
      try {
        await _write(makePacket(cmdRealtimeStop, [5, 0, 0]));
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await sub.cancel();
      await q.close();
    }

    if (values.isEmpty) return null;
    values.sort();
    return values[values.length ~/ 2];
  }

  /// SpO₂ historique horaire via canal bc (OpenH59) — max de la dernière heure non nulle.
  Future<int?> _spo2FromBcHistory() async {
    final w = bcWrite;
    if (w == null || bcNotify == null) return null;

    try {
      // Init soft sans compte QWatch
      await w.write(_bcFrame(bcInit), withoutResponse: w.properties.writeWithoutResponse);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      List<int>? bestBody;
      final sub = _bcCtrl.stream.listen((frame) {
        if (frame.length < 6 || frame[1] != bcSpo2) return;
        final ln = frame[2] | (frame[3] << 8);
        final body = frame.sublist(6, mathMin(6 + ln, frame.length));
        if (bestBody == null || body.length > bestBody!.length) {
          bestBody = body;
        }
      });

      await w.write(
        _bcFrame(bcSpo2, [0]), // day = 0 (aujourd'hui)
        withoutResponse: w.properties.writeWithoutResponse,
      );

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline) && (bestBody == null || bestBody!.length < 3)) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      await sub.cancel();

      final body = bestBody;
      if (body == null || body.length < 3) return null;
      // body[0]=day, puis paires (min,max) par heure — on prend le dernier max > 0
      int? last;
      for (var h = 0; h < 24 && 1 + h * 2 + 1 < body.length; h++) {
        final hi = body[1 + h * 2 + 1];
        if (hi >= 70 && hi <= 100) last = hi;
      }
      return last;
    } catch (_) {
      return null;
    }
  }

  int mathMin(int a, int b) => a < b ? a : b;

  Future<({int? last, List<({String hour, int bpm})> points})> heartRateCurveToday() async {
    final now = DateTime.now();
    final mid = DateTime(now.year, now.month, now.day);
    final ts = mid.millisecondsSinceEpoch ~/ 1000;
    final offset = now.timeZoneOffset.inSeconds;
    final bandTs = ts + offset;
    final bytes = [
      bandTs & 0xff,
      (bandTs >> 8) & 0xff,
      (bandTs >> 16) & 0xff,
      (bandTs >> 24) & 0xff,
    ];
    _histBuffer.clear();
    _collecting = true;
    await _write(makePacket(cmdHrHistory, bytes));
    await Future<void>.delayed(const Duration(milliseconds: 3500));
    _collecting = false;

    var size = 0;
    final raw = <int>[];
    var index = 0;
    for (final p in _histBuffer) {
      if (p.isEmpty || p[0] != cmdHrHistory) continue;
      final sub = p[1];
      if (sub == 0xff) break;
      if (sub == 0) {
        size = p.length > 2 ? p[2] : 0;
        raw
          ..clear()
          ..addAll(List<int>.filled(size * 13, 0));
        index = 0;
      } else if (sub == 1) {
        final chunk = p.skip(6).take(9).toList();
        for (var i = 0; i < chunk.length && index < raw.length; i++) {
          raw[index++] = chunk[i];
        }
      } else {
        final chunk = p.skip(2).take(13).toList();
        for (var i = 0; i < chunk.length && index < raw.length; i++) {
          raw[index++] = chunk[i];
        }
      }
    }

    final points = <({String hour, int bpm})>[];
    int? last;
    final take = raw.isEmpty ? <int>[] : raw.take(288).toList();
    for (var i = 0; i < take.length; i++) {
      final hr = take[i];
      if (hr < 40 || hr > 220) continue;
      last = hr;
      if (i % 6 == 0 || i == take.length - 1) {
        final mins = i * 5;
        final h = (mins ~/ 60).toString().padLeft(2, '0');
        final m = (mins % 60).toString().padLeft(2, '0');
        points.add((hour: '$h:$m', bpm: hr));
      }
    }
    return (last: last, points: points);
  }

  Future<int?> lastHeartRateToday() async {
    final curve = await heartRateCurveToday();
    return curve.last;
  }

  Future<int?> hrvTodayMedian() async {
    _histBuffer.clear();
    _collecting = true;
    await _write(makePacket(cmdHrvHistory, [0]));
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    _collecting = false;
    final vals = <int>[];
    for (final p in _histBuffer) {
      if (p.isEmpty || p[0] != cmdHrvHistory) continue;
      if (p[1] == 0 || p[1] == 0xff) continue;
      for (final v in p.skip(2).take(13)) {
        if (v >= 20 && v <= 200) vals.add(v);
      }
    }
    if (vals.isEmpty) return null;
    vals.sort();
    return vals[vals.length ~/ 2];
  }

  Future<int?> stressTodayMedian() async {
    _histBuffer.clear();
    _collecting = true;
    await _write(makePacket(cmdStressHistory, [0]));
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    _collecting = false;
    final vals = <int>[];
    for (final p in _histBuffer) {
      if (p.isEmpty || p[0] != cmdStressHistory) continue;
      if (p[1] == 0 || p[1] == 0xff) continue;
      for (final v in p.skip(2).take(13)) {
        if (v > 0 && v <= 100) vals.add(v);
      }
    }
    if (vals.isEmpty) return null;
    vals.sort();
    return vals[vals.length ~/ 2];
  }

  Future<({double hours, int light, int deep, int rem, int awake})?> sleepEstimate() async {
    _histBuffer.clear();
    _collecting = true;
    await _write(makePacket(cmdSleepHistory));
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    _collecting = false;
    var minutes = 0;
    for (final p in _histBuffer) {
      if (p.isEmpty || p[0] != cmdSleepHistory) continue;
      if (p[1] == 0xff) break;
      if (p[1] == 0) continue;
      for (final v in p.skip(2).take(13)) {
        if (v > 0) minutes += 5;
      }
    }
    if (minutes < 60) return null;
    final h = minutes / 60.0;
    return (
      hours: h.clamp(3.0, 12.0),
      light: (minutes * 0.45).round(),
      deep: (minutes * 0.25).round(),
      rem: (minutes * 0.2).round(),
      awake: (minutes * 0.1).round(),
    );
  }

  void dispose() {
    unbind();
    _txCtrl.close();
    _bcCtrl.close();
  }
}
