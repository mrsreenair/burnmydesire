import 'dart:async';

import 'package:flutter/services.dart';

/// System instructions for the on-device model. Guardrails live here:
/// short, warm, no clinical claims, no AI self-reference, no shaming.
const kCoachInstructions =
    'You are the quiet, warm voice inside Burn My Desire, an app where '
    'people write down or photograph a desire — a craving, a thought, an '
    'impulse purchase — and burn it in a ritual to let it go. '
    'After a burn, you say ONE short encouragement: at most two sentences '
    'and 160 characters. Be warm, human, and specific to what they burned. '
    'Speak directly to them. Never give medical, financial, or clinical '
    'advice. Never mention being an AI or a language model. Never shame '
    'them. No emojis, no hashtags, no quotation marks around the message.';

/// Builds the per-burn prompt. Pure so it's unit-testable. The written
/// [thought] is included when available — it never leaves the device,
/// which is why this can be personal.
String buildEncouragementPrompt({
  required bool isEmotion,
  required int burnNumber,
  List<String> goalLabels = const [],
  String? thought,
}) {
  final what = StringBuffer();
  if (isEmotion) {
    what.write('They wrote a thought on paper and burned it.');
    final t = thought?.trim();
    if (t != null && t.isNotEmpty) {
      final clipped = t.length > 200 ? '${t.substring(0, 200)}…' : t;
      what.write(' The thought was: "$clipped"');
    }
  } else {
    what.write(
        'They photographed something they were about to impulse-buy and '
        'burned the photo instead of buying it.');
  }
  if (goalLabels.isNotEmpty) {
    what.write(
        ' The desires they are working on: ${goalLabels.join(', ')}.');
  }
  if (burnNumber > 1) {
    what.write(
        ' This same desire has now been resisted $burnNumber times.');
  } else {
    what.write(' This is their first burn of this desire.');
  }
  what.write(' Write the encouragement now.');
  return what.toString();
}

/// On-device AI encouragement via Apple Foundation Models. Returns null on
/// any failure or oddity — callers always keep the curated fallback.
class AiCoach {
  AiCoach([MethodChannel? channel])
      : _channel = channel ?? const MethodChannel('burnmydesire/ai');

  final MethodChannel _channel;

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Why the model is or isn't usable. 'channel_missing' means the native
  /// bridge never registered — a build problem, not a device setting.
  Future<String> status() async {
    try {
      return await _channel.invokeMethod<String>('status') ?? 'unknown';
    } on MissingPluginException {
      return 'channel_missing';
    } on PlatformException catch (e) {
      return 'error:${e.code}';
    }
  }

  /// Set by [encouragement] when generation fails, so Settings can show
  /// what actually went wrong instead of silently falling back.
  static String? lastError;

  Future<String?> encouragement({
    required bool isEmotion,
    required int burnNumber,
    List<String> goalLabels = const [],
    String? thought,
  }) async {
    try {
      final raw = await _channel.invokeMethod<String>('generate', {
        'instructions': kCoachInstructions,
        'prompt': buildEncouragementPrompt(
          isEmotion: isEmotion,
          burnNumber: burnNumber,
          goalLabels: goalLabels,
          thought: thought,
        ),
      }).timeout(const Duration(seconds: 8));
      final text = raw?.trim();
      // Sanity bounds: a one-liner, not an essay, not empty.
      if (text == null || text.isEmpty) {
        lastError = 'empty_response';
        return null;
      }
      if (text.length > 240) {
        lastError = 'too_long:${text.length}';
        return null;
      }
      lastError = null;
      return text;
    } on MissingPluginException {
      lastError = 'channel_missing';
      return null;
    } on PlatformException catch (e) {
      lastError = '${e.code}: ${e.message}';
      return null;
    } on TimeoutException {
      lastError = 'timeout';
      return null;
    } on Exception catch (e) {
      lastError = e.runtimeType.toString();
      return null;
    }
  }
}
