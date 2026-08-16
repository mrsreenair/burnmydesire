import 'package:burn_my_desire/data/database.dart';
import 'package:burn_my_desire/data/follow_up.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two questions per burn — three days, then fourteen (GROWTH.md M5).
void main() {
  final burned = DateTime(2026, 8, 3, 12); // Monday noon

  Item item({
    DateTime? lastBurnedAt,
    DateTime? followUpAt,
    DateTime? boughtAt,
    String category = 'purchase',
  }) => Item(
    id: 1,
    imageFile: '',
    priceCents: 5000,
    category: category,
    resistanceCount: 1,
    createdAt: burned,
    lastBurnedAt: lastBurnedAt ?? burned,
    followUpAt: followUpAt,
    boughtAt: boughtAt,
  );

  int stage(Item i, int daysLater, {int hours = 0}) =>
      followUpStageFor(i, burned.add(Duration(days: daysLater, hours: hours)));

  test('a purchase burned on Monday is asked on Thursday', () {
    expect(stage(item(), 2, hours: 23), 0);
    expect(stage(item(), 3), 1);
    expect(stage(item(), 10), 1); // still the first question until answered
  });

  test('"still resisted" on Thursday brings the second on the second Monday', () {
    final answered = item(followUpAt: burned.add(const Duration(days: 3)));
    expect(stage(answered, 4), 0);
    expect(stage(answered, 13), 0);
    expect(stage(answered, 14), 2);
    expect(stage(answered, 40), 2); // until answered
  });

  test('a second "still resisted" ends the questions', () {
    final done = item(followUpAt: burned.add(const Duration(days: 14)));
    expect(stage(done, 15), 0);
    expect(stage(done, 100), 0);
  });

  test('answering the first late (after day 14) is also the end', () {
    final late = item(followUpAt: burned.add(const Duration(days: 20)));
    expect(stage(late, 21), 0);
  });

  test('a re-burn starts the pair again', () {
    final reburned = item(
      followUpAt: burned.add(const Duration(days: 3)),
      lastBurnedAt: burned.add(const Duration(days: 5)),
    );
    // Day 8 = 3 days after the re-burn: first question, fresh.
    expect(stage(reburned, 8), 1);
  });

  test('never for a confession, never for a thought', () {
    expect(stage(item(boughtAt: burned.add(const Duration(days: 4))), 30), 0);
    expect(stage(item(category: 'emotion'), 30), 0);
  });
}
