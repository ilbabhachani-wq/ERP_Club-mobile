import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// IFrame Three.js (OrbitControls + Meshopt) — Flutter web only.
class ViivOrbitWebView extends StatefulWidget {
  const ViivOrbitWebView({
    super.key,
    required this.src,
    this.height = 380,
  });

  /// Path relative to the Flutter web root, e.g. `models/viiv-gx17.glb`.
  final String src;
  final double height;

  @override
  State<ViivOrbitWebView> createState() => _ViivOrbitWebViewState();
}

class _ViivOrbitWebViewState extends State<ViivOrbitWebView> {
  late final String _viewType;
  static final Set<String> _registered = <String>{};

  @override
  void initState() {
    super.initState();
    // Prefer static web/models path; otherwise Flutter asset URL.
    final String modelUrl;
    if (widget.src.startsWith('models/')) {
      modelUrl = widget.src;
    } else if (widget.src.startsWith('assets/assets/')) {
      modelUrl = widget.src;
    } else if (widget.src.startsWith('assets/')) {
      modelUrl = 'assets/${widget.src}';
    } else {
      modelUrl = 'assets/assets/${widget.src}';
    }
    final iframeSrc =
        'viiv_orbit.html?src=${Uri.encodeComponent(modelUrl)}&t=${DateTime.now().millisecondsSinceEpoch}';
    _viewType = 'viiv-orbit-v7-${modelUrl.hashCode}';

    if (!_registered.contains(_viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src = iframeSrc
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = 'transparent'
          ..allow = 'autoplay'
          ..setAttribute('allowfullscreen', 'true');
        return iframe;
      });
      _registered.add(_viewType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
