import 'package:flutter/material.dart';
import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/features/ai_feature/ai_feature_bootstrap.dart';

/// Reacts to [net.aiEnabledNotifier] and refreshes AI status on mount.
///
/// Always forces a fresh API call on mount (Duration.zero) so a stale
/// SharedPreferences cache of `false` never permanently hides the button.
class AiEnabledGate extends StatefulWidget {
  const AiEnabledGate({
    super.key,
    required this.whenEnabled,
    this.whenDisabled,
    this.refreshOnMount = true,
    this.minRefreshInterval = const Duration(seconds: 15),
  });

  final WidgetBuilder whenEnabled;
  final Widget? whenDisabled;
  final bool refreshOnMount;

  /// Kept for API compatibility but not used for the initial mount refresh,
  /// which always uses Duration.zero to guarantee a fresh status check.
  final Duration minRefreshInterval;

  @override
  State<AiEnabledGate> createState() => _AiEnabledGateState();
}

class _AiEnabledGateState extends State<AiEnabledGate> {
  bool _refreshed = false;

  @override
  void initState() {
    super.initState();

    if (widget.refreshOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _refreshed) return;
        _refreshed = true;
        // Force Duration.zero so a stale-false cache never blocks the refresh.
        await AiFeatureBootstrap().refresh(minInterval: Duration.zero);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: net.aiEnabledNotifier,
      builder: (_, enabled, __) {
        if (!enabled) return widget.whenDisabled ?? const SizedBox.shrink();
        return widget.whenEnabled(context);
      },
    );
  }
}
