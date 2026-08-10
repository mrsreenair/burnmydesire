import 'dart:io';
import 'dart:typed_data';

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
    expect(burnEffects.map((e) => e.asset).toSet().length, burnEffects.length);
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

  // iOS doesn't loop gaplessly (see widgets/burn_sound.dart), so a clip
  // shorter than the ritual breaks audibly part-way through every burn.
  // The only defence is length, and length is easy to lose by accident.
  test('every sound outlasts the hold', () {
    for (final e in burnEffects) {
      final seconds = _wavSeconds(File('assets/${e.sound}'));
      expect(
        seconds,
        greaterThanOrEqualTo(10),
        reason:
            '${e.sound} is ${seconds.toStringAsFixed(1)}s — it will '
            'reach the end of the loop during a burn and break',
      );
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

/// Length of a PCM WAV in seconds, by walking its RIFF chunks.
double _wavSeconds(File file) {
  final b = file.readAsBytesSync().buffer.asByteData();
  var offset = 12; // past "RIFF" + size + "WAVE"
  var byteRate = 0;
  while (offset + 8 <= b.lengthInBytes) {
    final id = String.fromCharCodes(
      Uint8List.view(b.buffer, b.offsetInBytes + offset, 4),
    );
    final size = b.getUint32(offset + 4, Endian.little);
    if (id == 'fmt ') byteRate = b.getUint32(offset + 16, Endian.little);
    if (id == 'data') return byteRate == 0 ? 0 : size / byteRate;
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }
  return 0;
}
