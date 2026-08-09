import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/burn_effects.dart';
import 'pro_provider.dart';

/// What the user picked in Settings. Invalidate after saving.
final burnEffectIdProvider = FutureProvider<String>((ref) => savedBurnEffect());

/// The effect the burn screen should actually run: the choice, downgraded
/// to fire if Pro isn't (or is no longer) active.
final burnEffectProvider = Provider<BurnEffect>(
  (ref) => effectiveBurnEffect(
    ref.watch(burnEffectIdProvider).value,
    isPro: ref.watch(proUnlockedProvider),
  ),
);
