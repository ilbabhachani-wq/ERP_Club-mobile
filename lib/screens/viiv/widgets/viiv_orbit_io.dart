import 'package:flutter/material.dart';

/// Stub — web-only iframe is not used on IO platforms.
class ViivOrbitWebView extends StatelessWidget {
  const ViivOrbitWebView({
    super.key,
    required this.src,
    this.height = 380,
  });

  final String src;
  final double height;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
