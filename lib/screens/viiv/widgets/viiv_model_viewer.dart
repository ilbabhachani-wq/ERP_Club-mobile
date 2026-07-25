import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../config/api_config.dart';
import 'viiv_orbit_web.dart' if (dart.library.io) 'viiv_orbit_io.dart' as orbit;

/// Viewer 3D professionnel Viiv GX17 — drag 360°, zoom, éclairage studio.
/// Web: Three.js + Meshopt + OrbitControls · Native: model_viewer_plus.
class ViivGx17ModelViewer extends StatelessWidget {
  const ViivGx17ModelViewer({
    super.key,
    this.height = 380,
    this.autoRotate = true,
    this.recovery = 70,
    this.energy = 70,
    this.battery = 80,
    this.syncing = false,
  });

  final double height;
  final bool autoRotate;
  final int recovery;
  final int energy;
  final int battery;
  final bool syncing;

  static const _meshoptJs = '''
(function () {
  function apply() {
    var MV = customElements.get('model-viewer');
    if (!MV) return false;
    MV.meshoptDecoderLocation =
      'https://cdn.jsdelivr.net/npm/meshoptimizer@0.22.0/meshopt_decoder.js';
    return true;
  }
  if (!apply()) {
    customElements.whenDefined('model-viewer').then(apply);
  }
})();
''';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14141F), Color(0xFF0A0A10)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22D3EE).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (kIsWeb)
            orbit.ViivOrbitWebView(src: ViivModelAssets.glbWebPath, height: height)
          else
            ModelViewer(
              key: const ValueKey('viiv-gx17-native'),
              src: ViivModelAssets.glbAsset,
              alt: 'Viiv GX17 smartwatch 3D',
              backgroundColor: const Color(0xFF0A0A10),
              cameraControls: true,
              autoRotate: autoRotate,
              disableZoom: false,
              shadowIntensity: 1,
              exposure: 1.1,
              interactionPrompt: InteractionPrompt.auto,
              relatedJs: _meshoptJs,
              loading: Loading.eager,
            ),
          Positioned(
            left: 12,
            bottom: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.threed_rotation, size: 14, color: Color(0xFF22D3EE)),
                    SizedBox(width: 6),
                    Text(
                      'Modèle 3D · GLB Tripo · 360°',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 520.ms).slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }
}
