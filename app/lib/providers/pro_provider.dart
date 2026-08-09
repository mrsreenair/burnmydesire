import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';
import 'db_providers.dart';

/// Whether RevenueCat was configured at startup (a key was provided).
final purchasesConfiguredProvider = Provider<bool>(
  (ref) => kRevenueCatIosApiKey.isNotEmpty,
);

/// True when the user owns the Pro entitlement. Without a configured
/// RevenueCat key this is always false (free tier).
class ProNotifier extends Notifier<bool> {
  @override
  bool build() {
    if (!ref.read(purchasesConfiguredProvider)) return false;
    Purchases.addCustomerInfoUpdateListener(_onInfo);
    ref.onDispose(() => Purchases.removeCustomerInfoUpdateListener(_onInfo));
    Purchases.getCustomerInfo().then(_onInfo).ignore();
    return false;
  }

  void _onInfo(CustomerInfo info) {
    state = info.entitlements.active.containsKey(kProEntitlementId);
  }
}

final proProvider = NotifierProvider<ProNotifier, bool>(ProNotifier.new);

/// Whether Pro features are available. Dev builds without a RevenueCat
/// key keep them open so the founder can demo.
final proUnlockedProvider = Provider<bool>((ref) =>
    ref.watch(proProvider) || !ref.watch(purchasesConfiguredProvider));

/// The dashboard is a Pro feature.
final dashboardUnlockedProvider =
    Provider<bool>((ref) => ref.watch(proUnlockedProvider));

/// Free users may add a new temptation only below the item limit. Only
/// live items count — destroying a desire forever frees the slot.
final canAddItemProvider = Provider<bool>((ref) {
  if (ref.watch(proProvider)) return true;
  return ref.watch(liveItemsProvider).length < kFreeItemLimit;
});
