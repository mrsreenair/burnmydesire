import 'package:purchases_flutter/purchases_flutter.dart';

/// Sample plans, so the paywall can be looked at and clicked through
/// before App Store Connect and RevenueCat are wired up.
///
/// This exists because the real thing can't be faked usefully: RevenueCat
/// validates purchases on its own servers, so Xcode's StoreKit test file
/// will show you Apple's purchase sheet but will never flip the
/// entitlement. Testing the *transaction* needs a sandbox Apple ID and a
/// real device (see PAYMENTS.md). Testing the *screen* shouldn't need any
/// of that, and this is that.
///
/// Debug builds only. `kDebugMode` is a compile-time constant, so in a
/// release build the call site is dead and this whole file is tree-shaken
/// away — sample prices can't reach a shipping app.
List<Package> previewPackages() {
  const context = PresentedOfferingContext('preview', null, null);

  Package plan({
    required String id,
    required PackageType type,
    required String title,
    required double price,
    required String priceString,
    String? period,
    String? trialPeriod,
  }) => Package(
    id,
    type,
    StoreProduct(
      id,
      'Burn My Desire Pro',
      title,
      price,
      priceString,
      'EUR',
      subscriptionPeriod: period,
      // (price, priceString, period, cycles, periodUnit, unitCount) — a
      // free trial is simply a zero price for one cycle.
      introductoryPrice: trialPeriod == null
          ? null
          : IntroductoryPrice(0, '€0.00', trialPeriod, 1, PeriodUnit.week, 1),
    ),
    context,
  );

  return [
    plan(
      id: 'pro_yearly',
      type: PackageType.annual,
      title: 'Pro Yearly',
      price: 19.99,
      priceString: '€19.99',
      period: 'P1Y',
      trialPeriod: 'P1W',
    ),
    plan(
      id: 'pro_monthly',
      type: PackageType.monthly,
      title: 'Pro Monthly',
      price: 2.99,
      priceString: '€2.99',
      period: 'P1M',
    ),
    plan(
      id: 'pro_lifetime',
      type: PackageType.lifetime,
      title: 'Pro Lifetime',
      price: 29.99,
      priceString: '€29.99',
    ),
  ];
}
