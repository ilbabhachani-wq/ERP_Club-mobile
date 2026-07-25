import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/odin_widgets.dart';

/// Carte GPS — position live. Tap → plein écran.
class ViivMapCard extends StatefulWidget {
  const ViivMapCard({
    super.key,
    this.gpsLabel = 'GPS Viiv',
    this.height = 220,
  });

  final String gpsLabel;
  final double height;

  @override
  State<ViivMapCard> createState() => _ViivMapCardState();
}

class _ViivMapCardState extends State<ViivMapCard> {
  LatLng? _pos;
  String? _error;
  bool _loading = true;
  double? _accuracy;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _error = 'Activez la localisation GPS';
          _loading = false;
        });
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Autorisez la localisation pour la carte';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _pos = LatLng(pos.latitude, pos.longitude);
        _accuracy = pos.accuracy;
        _loading = false;
      });

      await _sub?.cancel();
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 8,
        ),
      ).listen((p) {
        if (!mounted) return;
        setState(() {
          _pos = LatLng(p.latitude, p.longitude);
          _accuracy = p.accuracy;
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'GPS indisponible: $e';
        _loading = false;
      });
    }
  }

  void _openFullscreen() {
    if (_pos == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _ViivMapFullscreen(
          initial: _pos!,
          gpsLabel: widget.gpsLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionTitle('Carte · Position live', color: Color(0xFF22D3EE)),
            ),
            if (_pos != null)
              IconButton(
                tooltip: 'Plein écran',
                onPressed: _openFullscreen,
                icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF22D3EE)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: EdgeInsets.zero,
          onTap: _pos != null ? _openFullscreen : null,
          child: ClipRRect(
            borderRadius: AppRadius.lgAll,
            child: SizedBox(
              height: widget.height,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF22D3EE), strokeWidth: 2),
                    )
                  : _error != null || _pos == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error ?? 'Position inconnue',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                                ),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: _init,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Réessayer GPS'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            IgnorePointer(
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: _pos!,
                                  initialZoom: 15.5,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.odin.club.erp_club_player',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _pos!,
                                        width: 44,
                                        height: 44,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF22D3EE).withValues(alpha: 0.25),
                                            border: Border.all(color: const Color(0xFF22D3EE), width: 3),
                                          ),
                                          child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              left: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC0B0B14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.gps_fixed, size: 14, color: Color(0xFF22C55E)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'GPS · ${widget.gpsLabel}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC0B0B14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.fullscreen_rounded, size: 18, color: Color(0xFF22D3EE)),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xCC0B0B14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_pos!.latitude.toStringAsFixed(5)}, ${_pos!.longitude.toStringAsFixed(5)}'
                                  '${_accuracy != null ? ' · ±${_accuracy!.round()} m' : ''}',
                                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViivMapFullscreen extends StatefulWidget {
  const _ViivMapFullscreen({required this.initial, required this.gpsLabel});

  final LatLng initial;
  final String gpsLabel;

  @override
  State<_ViivMapFullscreen> createState() => _ViivMapFullscreenState();
}

class _ViivMapFullscreenState extends State<_ViivMapFullscreen> {
  late LatLng _pos;
  double? _accuracy;
  late final MapController _map;
  StreamSubscription<Position>? _sub;

  @override
  void initState() {
    super.initState();
    _pos = widget.initial;
    _map = MapController();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((p) {
      if (!mounted) return;
      setState(() {
        _pos = LatLng(p.latitude, p.longitude);
        _accuracy = p.accuracy;
      });
      _map.move(_pos, _map.camera.zoom);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B14),
        title: Text(widget.gpsLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Centrer',
            onPressed: () => _map.move(_pos, 16),
            icon: const Icon(Icons.my_location_rounded, color: Color(0xFF22D3EE)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _pos,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.odin.club.erp_club_player',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pos,
                    width: 52,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.25),
                        border: Border.all(color: const Color(0xFF22D3EE), width: 3),
                      ),
                      child: const Icon(Icons.directions_run_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xCC0B0B14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${_pos.latitude.toStringAsFixed(5)}, ${_pos.longitude.toStringAsFixed(5)}'
                '${_accuracy != null ? ' · ±${_accuracy!.round()} m' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
