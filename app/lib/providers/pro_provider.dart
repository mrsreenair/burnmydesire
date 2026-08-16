import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';
import 'db_providers.dart';

/// Whether RevenueCat was configured at startup (a key was provided).
final purchasesConfiguredProvider = Provider<bool>(
  (ref) => kRevenueCatIosApiKey.isNotEmpty,
);

/// The latest word from RevenueCat about this Apple ID. Null until the
/// first answer arrives, and forever when there's no store key.
class CustomerInfoNotifier extends Notifier<CustomerInfo?> {
  @override
  CustomerInfo? build() {
    if (!ref.read(purchasesConfiguredProvider)) return null;
    Purchases.addCustomerInfoUpdateListener(_onInfo);
    ref.onDispose(() => Purchases.removeCustomerInfoUpdateListener(_onInfo));
    Purchases.getCustomerInfo().then(_onInfo).ignore();
    return null;
  }

  void _onInfo(CustomerInfo info) => state = info;
}

final customerInfoProvider = NotifierProvider<CustomerInfoNotifier, CustomerInfo?>(
  CustomerInfoNotifier.new,
);

/// True when the user owns the Pro entitlement. Without a configured
/// RevenueCat key this is always false (free tier).
final proProvider = Provider<bool>(
  (ref) =>
      ref
          .watch(customerInfoProvider)
          ?.entitlements
          .active
          .containsKey(kProEntitlementId) ??
      false,
);

/// The next Pro charge, when there is one: a subscription that will
/// renew. Null for lifetime, for a cancelled plan running out its term,
/// and for free users. Feeds the renewal reminder — the notification the
/// paywall promises — so it has to be right rather than approximate.
class ProRenewal {
  const ProRenewal({required this.renewsAt, this.priceString});
  final DateTime renewsAt;
  final String? priceString;
}

final proRenewalProvider = FutureProvider<ProRenewal?>((ref) async {
  final info = ref.watch(customerInfoProvider);
  final pro = info?.entitlements.active[kProEntitlementId];
  if (pro == null || !pro.willRenew || pro.expirationDate == null) {
    return null;
  }
  final renewsAt = DateTime.tryParse(pro.expirationDate!)?.toLocal();
  if (renewsAt == null) return null;
  String? price;
  try {
    final products = await Purchases.getProducts([pro.productIdentifier]);
    if (products.isNotEmpty) price = products.first.priceString;
  } on Exception {
    // A reminder without the amount still keeps the promise.
  }
  return ProRenewal(renewsAt: renewsAt, priceString: price);
});

/// Whether Pro features are available. Dev builds without a RevenueCat
/// key keep them open so the founder can demo.
final proUnlockedProvider = Provider<bool>(
  (ref) => ref.watch(proProvider) || !ref.watch(purchasesConfiguredProvider),
);

/// The dashboard is a Pro feature.
final dashboardUnlockedProvider = Provider<bool>(
  (ref) => ref.watch(proUnlockedProvider),
);

/// Why a free user can't capture right now — or [none] when they can.
/// Capture only: re-burning what's already here is never gated, so the
/// ritual can't be held hostage mid-craving (PROJECT.md §4.5).
enum AddBlock { none, liveLimit, monthlyLimit }

final addBlockProvider = Provider<AddBlock>((ref) {
  if (ref.watch(proProvider)) return AddBlock.none;
  if (ref.watch(liveItemsProvider).length >= kFreeItemLimit) {
    return AddBlock.liveLimit;
  }
  if (ref.watch(newItemsThisMonthProvider) >= kFreeMonthlyNewItems) {
    return AddBlock.monthlyLimit;
  }
  return AddBlock.none;
});

final canAddItemProvider = Provider<bool>(
  (ref) => ref.watch(addBlockProvider) == AddBlock.none,
);
