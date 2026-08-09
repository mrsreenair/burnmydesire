import 'dart:io';

import 'package:burn_my_desire/data/burn_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fire is the free default and comes first', () {
    expect(burnEffects.first.id, kDefaultBurnEffect);
    expect(burnEffects.first.pro, isFalse);
    expect(burnEffects.where((e) => !e.pro).length, 1);
  });

  test('every effect has a distinct id and shader', () {
    expect(burnEffects.map((e) => e.id).toSet().length, burnEffects.length);
    expect(
      burnEffects.map((e) => e.asset).toSet().length,
      burnEffects.length,
    );
    for (final e in burnEffects) {
      expect(e.asset, startsWith('assets/shaders/'));
      expect(e.asset, endsWith('.frag'));
    }
  });

  // Sound failures are swallowed by design — the ritual must never break
  // because audio is unavailable — so a mistyped or unregistered path
  // would just be silence with no error anywhere. Catch it here instead.
  test('every shader and sound is on disk and declared in pubspec', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final e in burnEffects) {
      expect(File(e.asset).existsSync(), isTrue, reason: '${e.id}: ${e.asset}');
      expect(pubspec, contains(e.asset), reason: '${e.id} shader in pubspec');

      final sound = 'assets/${e.sound}';
      expect(File(sound).existsSync(), isTrue, reason: '${e.id}: $sound');
      expect(pubspec, contains(sound), reason: '${e.id} sound in pubspec');
    }
  });

  test('an unknown or missing id falls back to fire', () {
    // A Pro effect dropped in a later version must not leave someone
    // unable to burn at all.
    expect(burnEffectById('retired_effect').id, 'fire');
    expect(burnEffectById(null).id, 'fire');
  });

  test('Pro effects need Pro; losing it drops back to fire', () {
    expect(effectiveBurnEffect('ash', isPro: true).id, 'ash');
    expect(effectiveBurnEffect('ash', isPro: false).id, 'fire');
    // The free effect keeps working either way.
    expect(effectiveBurnEffect('fire', isPro: false).id, 'fire');
  });
}
