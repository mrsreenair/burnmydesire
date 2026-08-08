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

/// Free users may add a new temptation only below the item limit.
final canAddItemProvider = Provider<bool>((ref) {
  if (ref.watch(proProvider)) return true;
  final count = ref.watch(itemsProvider).value?.length ?? 0;
  return count < kFreeItemLimit;
});
