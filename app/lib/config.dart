/// Build-time configuration.
///
/// The RevenueCat key is injected at build time so no secret lives in git:
///   flutter build ios --dart-define=RC_IOS_KEY=appl_xxx
/// With no key the app runs in free-only mode and the paywall shows a
/// "purchases not live yet" state — safe for development and simulators.
const String kRevenueCatIosApiKey =
    String.fromEnvironment('RC_IOS_KEY', defaultValue: '');

/// RevenueCat entitlement identifier that unlocks Pro.
const String kProEntitlementId = 'pro';

/// Free tier: up to this many active temptation items (PROJECT.md §4.5).
const int kFreeItemLimit = 3;
