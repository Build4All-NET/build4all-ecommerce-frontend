import 'package:flutter/foundation.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/features/ai_feature/data/services/ai_feature_store.dart';
import 'package:build4front/features/ai_feature/data/services/public_ai_status_api_service.dart';

class AiFeatureBootstrap {
  AiFeatureBootstrap({
    AiFeatureStore? store,
    PublicAiStatusApiService? api,
  })  : _store = store ?? AiFeatureStore(),
        _api = api ?? PublicAiStatusApiService();

  final AiFeatureStore _store;
  final PublicAiStatusApiService _api;

  static DateTime? _lastRefreshAt;

  /// Refresh AI status from server.
  Future<void> refresh({Duration minInterval = const Duration(seconds: 15)}) async {
    final now = DateTime.now();
    final last = _lastRefreshAt;
    if (last != null && now.difference(last) < minInterval) {
      debugPrint('[AI-DEBUG] refresh skipped (throttled: last=${last.toIso8601String()}, minInterval=$minInterval)');
      return;
    }
    _lastRefreshAt = now;

    final linkIdStr = Env.ownerProjectLinkId.trim();
    final linkId = int.tryParse(linkIdStr);
    if (linkId == null) {
      debugPrint('[AI-DEBUG] refresh: invalid OWNER_PROJECT_LINK_ID=$linkIdStr — AI disabled');
      g.aiEnabled = false;
      return;
    }

    debugPrint('[AI-DEBUG] refresh: OWNER_PROJECT_LINK_ID=$linkIdStr (linkId=$linkId), current g.aiEnabled=${g.aiEnabled}');

    // Which AI features are installed (for show/hide). Load before the enabled
    // flag so screens that gate on both already have the install set in place.
    final installed = await _api.fetchInstalledFeatures(linkId: linkId);
    if (installed != null) g.aiInstalledFeatures = installed;

    final fresh = await _api.fetchAiEnabled(linkId: linkId);
    if (fresh == null) {
      debugPrint('[AI-DEBUG] refresh: API returned null — keeping current g.aiEnabled=${g.aiEnabled}');
      return;
    }

    debugPrint('[AI-DEBUG] refresh: API returned aiEnabled=$fresh → updating g.aiEnabled');
    g.aiEnabled = fresh;
    await _store.saveAiEnabled(linkId: linkIdStr, enabled: fresh);
    debugPrint('[AI-DEBUG] refresh: done, g.aiEnabled=${g.aiEnabled}');
  }

  Future<void> init() async {
    final linkIdStr = Env.ownerProjectLinkId.trim();
    final linkId = int.tryParse(linkIdStr);

    debugPrint('[AI-DEBUG] init: OWNER_PROJECT_LINK_ID=$linkIdStr (parsed linkId=$linkId)');

    if (linkId == null) {
      debugPrint('[AI-DEBUG] init: invalid OWNER_PROJECT_LINK_ID — AI disabled');
      g.aiEnabled = false;
      return;
    }

    // 1) Apply cached value immediately
    final cached = await _store.readAiEnabled(linkId: linkIdStr);
    debugPrint('[AI-DEBUG] init: cached aiEnabled=$cached → g.aiEnabled set to ${cached ?? false}');
    g.aiEnabled = cached ?? false;

    // 2) Fresh server check (force, bypass throttle)
    await refresh(minInterval: Duration.zero);
    debugPrint('[AI-DEBUG] init: completed, final g.aiEnabled=${g.aiEnabled}');
  }
}
