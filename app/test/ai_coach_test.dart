import 'package:burn_my_desire/data/ai_coach.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildEncouragementPrompt', () {
    test('emotion burn includes the written thought', () {
      final p = buildEncouragementPrompt(
        isEmotion: true,
        burnNumber: 1,
        thought: 'I keep texting my ex',
      );
      expect(p, contains('I keep texting my ex'));
      expect(p, contains('first time they let this desire go'));
    });

    test('long thoughts are clipped', () {
      final p = buildEncouragementPrompt(
        isEmotion: true,
        burnNumber: 1,
        thought: 'a' * 400,
      );
      expect(p, contains('…'));
      expect(p, isNot(contains('a' * 250)));
    });

    test('streaks and goals are mentioned', () {
      final p = buildEncouragementPrompt(
        isEmotion: true,
        burnNumber: 5,
        goalLabels: ['Alcohol', 'Breakup & heartbreak'],
      );
      expect(p, contains('5 times'));
      expect(p, contains('Alcohol'));
      expect(p, contains('Breakup & heartbreak'));
    });

    test('purchase burns describe the photo ritual', () {
      final p = buildEncouragementPrompt(isEmotion: false, burnNumber: 1);
      expect(p, contains('photographed'));
    });
  });

  group('AiCoach channel handling', () {
    const channel = MethodChannel('burnmydesire/ai-test');

    void mock(Object? Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => handler(call));
    }

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('returns trimmed message on success', () async {
      mock((call) {
        expect(call.method, 'generate');
        final args = call.arguments as Map;
        expect(args['instructions'], kCoachInstructions);
        return '  You let it go. That took strength.  ';
      });
      final msg = await AiCoach(channel).encouragement(
        isEmotion: true,
        burnNumber: 1,
      );
      expect(msg, 'You let it go. That took strength.');
    });

    test('returns null when the platform reports unavailable', () async {
      mock((call) =>
          throw PlatformException(code: 'unavailable', message: 'no model'));
      final msg = await AiCoach(channel).encouragement(
        isEmotion: true,
        burnNumber: 1,
      );
      expect(msg, isNull);
    });

    test('returns null for over-long output', () async {
      mock((call) => 'x' * 500);
      final msg = await AiCoach(channel).encouragement(
        isEmotion: true,
        burnNumber: 1,
      );
      expect(msg, isNull);
    });

    test('isAvailable false when channel is missing', () async {
      expect(await AiCoach(channel).isAvailable(), isFalse);
    });
  });
}
