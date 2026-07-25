import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_tokens.dart';
import 'scout_map_geo.dart';

class ScoutMapPin {
  const ScoutMapPin({
    required this.id,
    required this.name,
    required this.count,
    required this.level,
    required this.color,
    required this.point,
    this.logoUrl,
    this.icon,
  });

  final String id;
  final String name;
  final int count;
  final String level;
  final Color color;
  final LatLng point;
  final String? logoUrl;
  final String? icon;
}

/// Carte interactive type web (pins / bubbles + tuiles dark).
class ScoutBubbleMap extends StatefulWidget {
  const ScoutBubbleMap({
    super.key,
    required this.pins,
    required this.step,
    this.continentId,
    this.countryId,
    this.selectedId,
    this.hint,
    this.onSelect,
  });

  final List<ScoutMapPin> pins;
  final int step;
  final String? continentId;
  final String? countryId;
  final String? selectedId;
  final String? hint;
  final ValueChanged<ScoutMapPin>? onSelect;

  @override
  State<ScoutBubbleMap> createState() => _ScoutBubbleMapState();
}

class _ScoutBubbleMapState extends State<ScoutBubbleMap> {
  late final MapController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void didUpdateWidget(covariant ScoutBubbleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step ||
        oldWidget.continentId != widget.continentId ||
        oldWidget.countryId != widget.countryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fitCamera() {
    final cam = resolveMapCamera(
      step: widget.step,
      continentId: widget.continentId,
      countryId: widget.countryId,
    );
    _controller.move(cam.$1, cam.$2);
  }

  @override
  Widget build(BuildContext context) {
    final cam = resolveMapCamera(
      step: widget.step,
      continentId: widget.continentId,
      countryId: widget.countryId,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: cam.$1,
                initialZoom: cam.$2,
                minZoom: 1.2,
                maxZoom: 8,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
                ),
                backgroundColor: const Color(0xFF0B0B14),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'tn.odin.erpclub',
                  retinaMode: RetinaMode.isHighDensity(context),
                ),
                MarkerLayer(
                  markers: widget.pins.map((pin) {
                    final selected = pin.id == widget.selectedId;
                    final size = selected ? 54.0 : 44.0;
                    return Marker(
                      point: pin.point,
                      width: size + 8,
                      height: size + 18,
                      child: GestureDetector(
                        onTap: () => widget.onSelect?.call(pin),
                        child: _PinBubble(pin: pin, selected: selected, size: size),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    widget.hint ?? 'Touchez un point sur la carte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinBubble extends StatelessWidget {
  const _PinBubble({required this.pin, required this.selected, required this.size});

  final ScoutMapPin pin;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xF50C0E16),
            border: Border.all(
              color: selected ? pin.color : Colors.white.withValues(alpha: 0.25),
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: pin.color.withValues(alpha: selected ? 0.45 : 0.2),
                blurRadius: selected ? 14 : 8,
              ),
            ],
          ),
          child: ClipOval(
            child: pin.logoUrl != null && pin.logoUrl!.isNotEmpty
                ? ColoredBox(
                    color: Colors.white,
                    child: Image.network(
                      pin.logoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _fallback(),
                    ),
                  )
                : _fallback(),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: pin.color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${pin.count}',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    final letter = pin.name.trim().isNotEmpty ? pin.name.trim()[0].toUpperCase() : '?';
    return Center(
      child: Text(
        pin.icon?.isNotEmpty == true ? pin.icon! : letter,
        style: TextStyle(fontSize: size * 0.32),
      ),
    );
  }
}
