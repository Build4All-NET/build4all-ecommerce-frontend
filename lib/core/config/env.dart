class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Whether this build ships with real Firebase config.
  /// "true"  -> app initializes Firebase + push messaging.
  /// "false"/absent -> Firebase is fully disabled (no init, no push).
  /// Defaults to false so a missing flag can never crash a stub build.
  static const _requireFirebaseRaw = String.fromEnvironment(
    'REQUIRE_FIREBASE',
    defaultValue: 'false',
  );
  static bool get requireFirebase =>
      _requireFirebaseRaw.trim().toLowerCase() == 'true';

  static const wsPath = String.fromEnvironment(
    'WS_PATH',
    defaultValue: '/api/ws',
  );

  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  /// Optional (if your backend wants currency code like "usd")
  static const currencyCode = String.fromEnvironment(
    'CURRENCY_CODE',
    defaultValue: '',
  );

  /// "user" / "business" / "both"
  static const appRole = String.fromEnvironment(
    'APP_ROLE',
    defaultValue: 'both',
  );

  /// "header" | "query" | "body" | "off"
  static const ownerAttachMode = String.fromEnvironment(
    'OWNER_ATTACH_MODE',
    defaultValue: 'header',
  );

  static const ownerProjectLinkId = String.fromEnvironment(
    'OWNER_PROJECT_LINK_ID',
    defaultValue: '1',
  );

  static const projectId = String.fromEnvironment(
    'PROJECT_ID',
    defaultValue: '0',
  );

  static const appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Build4All App',
  );

  static const appLogoUrl = String.fromEnvironment(
    'APP_LOGO_URL',
    defaultValue: '',
  );

  static const themeJson = String.fromEnvironment(
    'THEME_JSON',
    defaultValue: '{}',
  );

  static const navJson = String.fromEnvironment('NAV_JSON', defaultValue: '[]');

  static const enabledFeaturesJson = String.fromEnvironment(
    'ENABLED_FEATURES_JSON',
    defaultValue: '[]',
  );

  static const appType = String.fromEnvironment(
    'APP_TYPE',
    defaultValue: 'ACTIVITIES',
  );

  static const themeId = String.fromEnvironment('THEME_ID', defaultValue: '0');

  static const themeJsonB64 = String.fromEnvironment(
    'THEME_JSON_B64',
    defaultValue: '',
  );

  static const navJsonB64 = String.fromEnvironment(
    'NAV_JSON_B64',
    defaultValue: '',
  );

  static const enabledFeaturesJsonB64 = String.fromEnvironment(
    'ENABLED_FEATURES_JSON_B64',
    defaultValue: '',
  );

  static const homeJsonB64 = String.fromEnvironment(
    'HOME_JSON_B64',
    defaultValue: '',
  );

  static const currencyId = String.fromEnvironment(
    'CURRENCY_ID',
    defaultValue: '',
  );

  // ✅ NEW: lets CI/backend tell the app which nav to use
  // Values: "bottom" | "drawer" | "hamburger" (hamburger will be treated as drawer)
  static const menuType = String.fromEnvironment(
    'MENU_TYPE',
    defaultValue: '',
  );

  // ✅ NEW: optional: manager already stores menuType in branding json
  // You can pass it as base64 to avoid adding MENU_TYPE directly.
  static const brandingJsonB64 = String.fromEnvironment(
    'BRANDING_JSON_B64',
    defaultValue: '',
  );
}
