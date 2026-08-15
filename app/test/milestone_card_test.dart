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
}
