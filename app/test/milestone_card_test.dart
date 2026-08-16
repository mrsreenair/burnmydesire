import 'dart:typed_data';

import 'package:burn_my_desire/utils/milestone_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a PNG', () async {
    final bytes = await renderMilestoneCard(protectedCents: 120000, burns: 3);
    expect(bytes.length, greaterThan(2000));
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  test('singular and plural both render', () async {
    final one = await renderMilestoneCard(protectedCents: 500, burns: 1);
    final many = await renderMilestoneCard(protectedCents: 500, burns: 9);
    expect(one, isNotEmpty);
    expect(many, isNotEmpty);
    // Different copy means different pixels.
    expect(one, isNot(equals(many)));
  });

  test('story format renders at 1080x1920', () async {
    final bytes = await renderMilestoneCard(
      protectedCents: 120000,
      burns: 3,
      format: CardFormat.story,
    );
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    // PNG IHDR carries the dimensions as big-endian uint32s at byte 16.
    final view = ByteData.sublistView(bytes);
    expect(view.getUint32(16), 1080);
    expect(view.getUint32(20), 1920);
  });

  test('square format stays square', () async {
    final bytes = await renderMilestoneCard(protectedCents: 120000, burns: 3);
    final view = ByteData.sublistView(bytes);
    expect(view.getUint32(16), 1080);
    expect(view.getUint32(20), 1080);
  });

  test('a story is not just the square stretched', () async {
    final square = await renderMilestoneCard(protectedCents: 4200, burns: 2);
    final story = await renderMilestoneCard(
      protectedCents: 4200,
      burns: 2,
      format: CardFormat.story,
    );
    expect(square, isNot(equals(story)));
  });

  group('goal line (GROWTH.md M3)', () {
    const trip = MilestoneGoal(name: 'A trip', emoji: '✈️', percent: 5);

    test('a goal changes the card, in both formats', () async {
      for (final f in CardFormat.values) {
        final plain = await renderMilestoneCard(
          protectedCents: 20000,
          burns: 2,
          format: f,
        );
        final withGoal = await renderMilestoneCard(
          protectedCents: 20000,
          burns: 2,
          goal: trip,
          format: f,
        );
        expect(withGoal.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
        expect(withGoal, isNot(equals(plain)));
      }
    });

    test('a thought-only card ignores the goal', () async {
      // No money: the goal line would say a breakup burn brought a trip
      // closer. It must render exactly as if no goal were given.
      final a = await renderMilestoneCard(
        protectedCents: 0,
        burns: 0,
        thoughts: 3,
      );
      final b = await renderMilestoneCard(
        protectedCents: 0,
        burns: 0,
        thoughts: 3,
        goal: trip,
      );
      expect(a, equals(b));
    });

    test('thoughts get their own card', () async {
      final money = await renderMilestoneCard(protectedCents: 500, burns: 1);
      final thoughts = await renderMilestoneCard(
        protectedCents: 0,
        burns: 0,
        thoughts: 1,
      );
      expect(thoughts.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(thoughts, isNot(equals(money)));
    });
  });
}
