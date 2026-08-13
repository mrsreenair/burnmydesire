/// Build-time configuration.
///
/// The RevenueCat key is injected at build time so no secret lives in git:
///   flutter build ios --dart-define=RC_IOS_KEY=appl_xxx
/// With no key the app runs in free-only mode and the paywall shows a
/// "purchases not live yet" state — safe for development and simulators.
const String kRevenueCatIosApiKey = String.fromEnvironment(
  'RC_IOS_KEY',
  defaultValue: '',
);

/// RevenueCat entitlement identifier that unlocks Pro.
const String kProEntitlementId = 'pro';

/// Terms of Use and Privacy Policy, linked from the paywall.
///
/// Not optional. App Review guideline 3.1.2 requires a functional link to
/// both from any screen selling a subscription, and "we'll add it later"
/// is one of the most common rejection reasons there is. Injected so the
/// URLs can change without a code edit:
///   flutter build ios --dart-define=TERMS_URL=https://…
///
/// Apple's standard EULA is a valid Terms link if you don't have your own:
/// https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
const String kTermsUrl = String.fromEnvironment(
  'TERMS_URL',
  defaultValue:
      'https://www.apple.com/legal/internet-services/itunes/dev/'
      'stdeula/',
);

const String kPrivacyUrl = String.fromEnvironment(
  'PRIVACY_URL',
  defaultValue: '',
);

/// Free tier: up to this many active temptation items (PROJECT.md §4.5).
/// Destroyed items don't count — finishing a desire frees a slot.
const int kFreeItemLimit = 3;

/// New desires (photos + thoughts combined) a free user may capture per
/// calendar month. Deliberately caps CAPTURE, never burns: re-burning
/// what's already here stays free forever, so the ritual is never held
/// hostage mid-craving (PROJECT.md §4.5).
const int kFreeMonthlyNewItems = 5;

/// Burns before a temptation is destroyed forever (the Final Burn): the
/// photo is deleted so it can't re-trigger the craving, while the savings
/// stay counted. A dead desire that returns is a new fight.
const int kFinalBurnCount = 3;

/// Base URL of the anonymous world-counter service (self-hosted). Empty
/// disables the feature entirely — the app then sends nothing, anywhere.
///   flutter build ios --dart-define=COUNTER_URL=https://counter.example.com
const String kWorldCounterBaseUrl = String.fromEnvironment(
  'COUNTER_URL',
  defaultValue: '',
);

/// Where "move the money" sends people. Placeholder until affiliate
/// accounts exist; the amount is appended so the partner can pre-fill.
const String kMoveMoneyUrl = String.fromEnvironment(
  'MOVE_MONEY_URL',
  defaultValue: '',
);
