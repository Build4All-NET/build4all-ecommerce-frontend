// lib/debug/debug_config_banner.dart
import 'package:flutter/material.dart';

/// Values coming from --dart-define-from-file=lib/env/ci_env.json
const String kApiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'MISSING');

const String kAppName =
    String.fromEnvironment('APP_NAME', defaultValue: 'MISSING');

const String kAppType =
    String.fromEnvironment('APP_TYPE', defaultValue: 'MISSING');

const String kOwnerProjectLinkId =
    String.fromEnvironment('OWNER_PROJECT_LINK_ID', defaultValue: 'MISSING');

const String kProjectId =
    String.fromEnvironment('PROJECT_ID', defaultValue: 'MISSING');

const String kCurrencyId =
    String.fromEnvironment('CURRENCY_ID', defaultValue: 'NONE');

const String kPackageName =
    String.fromEnvironment('PACKAGE_NAME', defaultValue: 'MISSING');

const String kThemeJsonB64 =
    String.fromEnvironment('THEME_JSON_B64', defaultValue: '');
const String kNavJsonB64 =
    String.fromEnvironment('NAV_JSON_B64', defaultValue: '');
const String kHomeJsonB64 =
    String.fromEnvironment('HOME_JSON_B64', defaultValue: '');
const String kEnabledFeaturesJsonB64 =
    String.fromEnvironment('ENABLED_FEATURES_JSON_B64', defaultValue: '');
const String kBrandingJsonB64 =
    String.fromEnvironment('BRANDING_JSON_B64', defaultValue: '');

class DebugConfigBanner extends StatelessWidget {
  final Widget child;

  const DebugConfigBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // On in debug, never in a release build: this panel prints the API base
    // URL and the raw config blobs on top of the UI, and the storefront runs
    // the same code in a browser where any visitor would read them.
    const bool showDebug = kDebugMode;

    if (!showDebug) return child;

    return Stack(
      children: [
        child,
        Positioned(
          left: 8,
          right: 8,
          bottom: 8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEBUG CONFIG',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('API_BASE_URL: $kApiBaseUrl'),
                    Text('OWNER_PROJECT_LINK_ID: $kOwnerProjectLinkId'),
                    Text('PROJECT_ID: $kProjectId'),
                    Text('PACKAGE_NAME: $kPackageName'),
                    Text('CURRENCY_ID: $kCurrencyId'),
                    const SizedBox(height: 4),
                    Text('has THEME_JSON_B64: ${kThemeJsonB64.isNotEmpty}'),
                    Text('has NAV_JSON_B64: ${kNavJsonB64.isNotEmpty}'),
                    Text('has HOME_JSON_B64: ${kHomeJsonB64.isNotEmpty}'),
                    Text(
                        'has ENABLED_FEATURES: ${kEnabledFeaturesJsonB64.isNotEmpty}'),
                    Text('has BRANDING_JSON: ${kBrandingJsonB64.isNotEmpty}'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
