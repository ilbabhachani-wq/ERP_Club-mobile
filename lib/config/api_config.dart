/// Backend SaaS — même base que le proxy Vite web (sans préfixe /api).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://erp-club-backend-production.up.railway.app',
);

const String kSocketBaseUrl = String.fromEnvironment(
  'SOCKET_BASE_URL',
  defaultValue: 'https://erp-club-backend-production.up.railway.app',
);

/// Live Match ML (integrations/analyste-live-ml) — override optionnel.
/// Exemple: `flutter run --dart-define=ANALYSTE_ML_URL=http://127.0.0.1:8090`
const String kAnalysteMlUrl = String.fromEnvironment(
  'ANALYSTE_ML_URL',
  defaultValue: '',
);

/// Clé API ImgBB (https://api.imgbb.com/) pour upload photos profil.
/// Exemple: `flutter run --dart-define=IMGBB_API_KEY=votre_cle`
const String kImgbbApiKey = String.fromEnvironment(
  'IMGBB_API_KEY',
  defaultValue: '',
);

/// Endpoints Viiv GX17 / wearable (ordre de priorité côté service).
abstract final class ViivApiPaths {
  /// Payload wearable dédié joueur (si backend l’expose).
  static const meViiv = '/joueur/me/viiv';

  /// Profil étendu (sommeil, training, nutrition, AI) → fallback métriques.
  static const meExtended = '/joueur/me/extended';

  /// Hub analyste (squad Whoop/Viiv) — utile si le joueur est dans la squad.
  static const analysteWhoop = '/analyste/whoop';

  /// Sync soft (re-fetch) — pas de POST dédié aujourd’hui.
  static const syncHint = meViiv;
}

/// Asset / URL du modèle 3D Tripo Viiv GX17.
abstract final class ViivModelAssets {
  /// Asset Flutter (web + native via model_viewer).
  static const glbAsset = 'assets/models/viiv-gx17.glb';
  /// Served from `web/models/` for the Three.js orbit iframe (reliable path).
  static const glbWebPath = 'models/viiv-gx17.glb';
  static const tripoStudio =
      'https://studio.tripo3d.ai/workspace/generate/190e8b69-a543-4dd7-a642-6749dbe77ca1';
}
