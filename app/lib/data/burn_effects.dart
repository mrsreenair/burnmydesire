import 'dart:ui' show Color;

import 'package:shared_preferences/shared_preferences.dart';

/// One way for a desire to be destroyed.
///
/// Every effect is a fragment shader behind the same contract: it takes
/// progress 0→1 plus the paper texture and draws the whole thing, so the
/// ritual (hold, haptics, sound, completion) is identical no matter which
/// one is chosen (PROJECT.md F3).
class BurnEffect {
  const BurnEffect({
    required this.id,
    required this.name,
    required this.blurb,
    required this.asset,
    required this.glow,
    this.pro = true,
  });

  final String id;

  /// Shown in the picker.
  final String name;

  /// One line on what it feels like — the choice is emotional, not
  /// technical, so describe the mood rather than the technique.
  final String blurb;

  /// Shader asset path, as registered in pubspec.yaml.
  final String asset;

  /// The light this burn throws into the dark room around the paper. The
  /// glow is half the effect — an orange room under a grey crumble would
  /// undo the whole point of offering a flameless option.
  final Color glow;

  /// Free users get fire. The rest are part of Pro.
  final bool pro;
}

const kDefaultBurnEffect = 'fire';

/// Fire first: it is the free one and the app's whole identity. The others
/// exist because the same ritual has to serve very different feelings —
/// burning a €400 impulse is not the same act as letting go of a person.
const burnEffects = <BurnEffect>[
  BurnEffect(
    id: 'fire',
    name: 'Fire',
    blurb: 'The original. A ragged orange front eats the page.',
    asset: 'assets/shaders/burn.frag',
    glow: Color(0xFFA8102A), // AppColors.coal
    pro: false,
  ),
  BurnEffect(
    id: 'ash',
    name: 'Ash',
    blurb: 'No flame. The page cools, greys and crumbles away.',
    asset: 'assets/shaders/ash.frag',
    glow: Color(0xFF3A3630),
  ),
  BurnEffect(
    id: 'cold',
    name: 'Cold flame',
    blurb: 'A gas-blue burn that bleaches the page instead of charring it.',
    asset: 'assets/shaders/cold.frag',
    glow: Color(0xFF0E2C86),
  ),
];

/// The effect for [id], falling back to fire for anything unknown — an
/// effect removed in a later version must never leave a user unable to
/// burn.
BurnEffect burnEffectById(String? id) => burnEffects.firstWhere(
      (e) => e.id == id,
      orElse: () => burnEffects.first,
    );

/// The effect this user may actually use right now. Losing Pro silently
/// drops them back to fire rather than breaking the ritual.
BurnEffect effectiveBurnEffect(String? id, {required bool isPro}) {
  final chosen = burnEffectById(id);
  return chosen.pro && !isPro ? burnEffects.first : chosen;
}

const _kBurnEffectKey = 'burn_effect';

Future<String> savedBurnEffect() async =>
    (await SharedPreferences.getInstance()).getString(_kBurnEffectKey) ??
    kDefaultBurnEffect;

Future<void> saveBurnEffect(String id) async =>
    (await SharedPreferences.getInstance()).setString(_kBurnEffectKey, id);
