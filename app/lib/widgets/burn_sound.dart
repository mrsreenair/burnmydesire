import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../data/user_prefs.dart';

/// The sound under the burn ritual — crackle for fire, motor and tearing
/// paper for the shredder. Each effect brings its own loop.
///
/// This used to run in the *ambient* category so it would honour the ring
/// switch. That was too polite to be heard: iOS silences ambient audio
/// whenever the phone is on silent, which is where most phones live, so
/// the sound effectively never played. It now uses `playback`, which plays
/// through the switch, with `mixWithOthers` so it never stops someone's
/// music — and a Settings toggle for anyone who wants the old silence.
///
/// The loops are ~12s for a 3s ritual, and that length is load-bearing.
/// audioplayers on iOS doesn't loop gaplessly: it waits for the
/// end-of-item notification, awaits a seek back to zero, then calls play
/// again (audioplayers_darwin, WrappedMediaPlayer.onSoundComplete), and
/// that round trip is an audible break. A 2s loop broke in the middle of
/// every burn. Nothing inside the file can fix it — the clip simply has
/// to outlast any plausible hold. Don't shorten them.
///
/// Every failure is swallowed; the ritual must never break because audio
/// is unavailable.
class BurnSound {
  BurnSound(this.asset);

  /// Asset path under `assets/`, e.g. `audio/fire.wav`.
  final String asset;

  /// Rises over this long when the hold starts, falls over it on release,
  /// so starting and stopping never clicks.
  static const _fade = Duration(milliseconds: 420);

  /// Loud enough to be part of the ritual, quiet enough not to startle
  /// someone holding the phone close.
  static const _maxVolume = 0.85;

  final AudioPlayer _player = AudioPlayer();
  Timer? _ramp;
  bool _ready = false;
  bool _muted = false;
  double _volume = 0;

  Future<void> _ensure() async {
    if (_ready) return;
    _muted = !await burnSoundEnabled();
    if (_muted) return;
    await _player.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          // Plays even when the ring switch is on silent. mixWithOthers
          // keeps a podcast or playlist running underneath.
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setSource(AssetSource(asset));
    await _player.setVolume(0);
    _ready = true;
  }

  /// Start (or resume) the sound under a press-and-hold.
  Future<void> start() async {
    try {
      await _ensure();
      if (_muted) return;
      await _player.resume();
      _rampTo(_maxVolume);
    } on Object catch (e) {
      // Silence is an acceptable outcome; a crash is not.
      debugPrint('BurnSound.start: $e');
    }
  }

  /// The user let go — fade out but keep the position, so resuming feels
  /// like the same fire rather than a restart.
  Future<void> pause() async {
    if (!_ready) return;
    _rampTo(0, then: () => _player.pause());
  }

  /// The paper is gone: let the last of it die away, then stop.
  Future<void> finish() async {
    if (!_ready) return;
    _rampTo(0, then: () => _player.stop());
  }

  void _rampTo(double target, {VoidCallback? then}) {
    _ramp?.cancel();
    const step = Duration(milliseconds: 30);
    final steps = _fade.inMilliseconds ~/ step.inMilliseconds;
    final from = _volume;
    var i = 0;
    _ramp = Timer.periodic(step, (timer) {
      i++;
      _volume = from + (target - from) * (i / steps);
      _player.setVolume(_volume.clamp(0.0, 1.0)).ignore();
      if (i >= steps) {
        timer.cancel();
        _volume = target;
        then?.call();
      }
    });
  }

  Future<void> dispose() async {
    _ramp?.cancel();
    await _player.dispose();
  }
}
