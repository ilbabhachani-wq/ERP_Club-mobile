import 'package:flutter/material.dart';
import '../../models/player_models.dart';

class FifaAttributes {
  const FifaAttributes({
    required this.pac,
    required this.sho,
    required this.pas,
    required this.dri,
    required this.def,
    required this.phy,
  });

  final int pac;
  final int sho;
  final int pas;
  final int dri;
  final int def;
  final int phy;
}

FifaAttributes getFifaAttributes(PlayerRadar radar) {
  return FifaAttributes(
    pac: radar.speed,
    sho: radar.shooting,
    pas: radar.passing,
    dri: ((radar.vision + radar.speed) / 2).round(),
    def: radar.defending,
    phy: radar.physical,
  );
}

String formatFifaName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final last = parts.isNotEmpty ? parts.last : name;
  if (last.isEmpty) return name;
  return '${last[0].toUpperCase()}${last.substring(1).toLowerCase()}';
}

String getInitials(String name) {
  return name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .map((p) => p[0].toUpperCase())
      .take(2)
      .join();
}

({List<int> gradient, Color glow}) fifaCardTier(int ovr) {
  if (ovr >= 75) {
    return (
      gradient: [0xFFFCE38A, 0xFFF5B942, 0xFFD89216],
      glow: const Color(0xFFFFB400),
    );
  }
  if (ovr >= 65) {
    return (
      gradient: [0xFFE8EEF5, 0xFFB8C5D6, 0xFF8A9BB0],
      glow: const Color(0xFF94A3B8),
    );
  }
  return (
    gradient: [0xFFD4A574, 0xFFB8864E, 0xFF8B5E3C],
    glow: const Color(0xFFCD7F32),
  );
}

const fifaStatColor = Color(0xFF1A1008);

String nationalityFlag(String? nationality) {
  if (nationality == null || nationality.isEmpty) return '';
  const flags = {
    'Tunisie': '🇹🇳',
    'Algérie': '🇩🇿',
    'Maroc': '🇲🇦',
    'France': '🇫🇷',
    'Sénégal': '🇸🇳',
    'Nigeria': '🇳🇬',
    'Nigéria': '🇳🇬',
    "Côte d'Ivoire": '🇨🇮',
    'Portugal': '🇵🇹',
    'Espagne': '🇪🇸',
    'Brésil': '🇧🇷',
    'Allemagne': '🇩🇪',
    'Italie': '🇮🇹',
    'Égypte': '🇪🇬',
    'Egypte': '🇪🇬',
  };
  return flags[nationality] ?? '🏳️';
}
