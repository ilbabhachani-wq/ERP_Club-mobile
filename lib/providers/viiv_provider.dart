import 'package:flutter/foundation.dart';
import '../models/viiv_metrics.dart';
import '../providers/app_providers.dart';
import '../services/api_client.dart';
import '../services/viiv_service.dart';

class ViivProvider extends ChangeNotifier {
  ViivProvider(this._api);

  final ApiClient _api;
  late final ViivService _service = ViivService(_api);

  ViivMetrics? metrics;
  bool syncing = false;
  bool loading = false;
  String? error;

  Future<void> load(JoueurDataProvider joueur) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      metrics = await _service.fetchAndMerge(
        player: joueur.myPlayer,
        stats: joueur.playerStats,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> sync(JoueurDataProvider joueur) async {
    syncing = true;
    error = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 2200));

    try {
      final fresh = await _service.fetchAndMerge(
        player: joueur.myPlayer,
        stats: joueur.playerStats,
      );
      metrics = fresh.copyWith(
        connected: true,
        lastSync: 'À l\'instant',
        lastSyncAt: DateTime.now().toString().substring(11, 19),
      );
    } catch (e) {
      error = e.toString();
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}
