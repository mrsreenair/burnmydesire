import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The crackle under the burn ritual.
///
/// Deliberately polite: the loop is set to the *ambient* audio category, so
/// it honours the phone's mute switch and ducks nothing — someone burning a
/// craving on the bus should not have the room hear it. Every failure is
/// swallowed; the ritual must never break because audio is unavailable.
class FireSound {
  FireSound();

  static const _asset = 'audio/fire.wav';

  /// Rises over this long when the hold starts, falls over it on release,
  /// so starting and stopping never clicks.
  static const _fade = Duration(milliseconds: 420);
  static const _maxVolume = 0.85;

  final AudioPlayer _player = AudioPlayer();
  Timer? _ramp;
  bool _ready = false;
  double _volume = 0;

  Future<void> _ensure() async {
    if (_ready) return;
    await _player.setAudioContext(
      AudioContext(
        // `ambient` already mixes with other audio and honours the mute
        // switch; passing mixWithOthers explicitly here is an assertion
        // error in audioplayers.
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        android: AudioContextAndroid(
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setSource(AssetSource(_asset));
    await _player.setVolume(0);
    _ready = true;
  }

  /// Start (or resume) the fire under a press-and-hold.
  Future<void> start() async {
    try {
      await _ensure();
      await _player.resume();
      _rampTo(_maxVolume);
    } on Object catch (e) {
      // Silence is an acceptable outcome; a crash is not.
      debugPrint('FireSound.start: $e');
    }
  }

  /// The user let go — fade out but keep the position, so resuming feels
  /// like the same fire rather than a restart.
  Future<void> pause() async {
    if (!_ready) return;
    _rampTo(0, then: () => _player.pause());
  }

  /// The paper is gone: let the last crackles die away, then stop.
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
