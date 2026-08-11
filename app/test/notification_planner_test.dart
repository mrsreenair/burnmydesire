import 'package:burn_my_desire/data/currencies.dart';
import 'package:burn_my_desire/data/database.dart';
import 'package:burn_my_desire/data/notification_planner.dart';
import 'package:burn_my_desire/data/notification_prefs.dart';
import 'package:burn_my_desire/utils/format_utils.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Monday morning, so weekday math is predictable.
final now = DateTime(2026, 8, 10, 10); // Mon 10 Aug 2026, 10:00

Item item({
  int id = 1,
  int priceCents = 80000,
  int resistanceCount = 1,
  DateTime? lastBurnedAt,
  DateTime? createdAt,
  DateTime? destroyedAt,
}) =>
    Item(
      id: id,
      imageFile: 'x.jpg',
      priceCents: priceCents,
      category: 'purchase',
      resistanceCount: resistanceCount,
      createdAt: createdAt ?? now.subtract(const Duration(days: 10)),
      lastBurnedAt: lastBurnedAt,
      destroyedAt: destroyedAt,
    );

List<PlannedNotification> plan({
  List<Item> items = const [],
  NotificationPrefs prefs = const NotificationPrefs(enabled: true),
  int protectedCents = 0,
  bool isPro = false,
  DateTime? lastBackupAt,
}) =>
    planNotifications(
      items: items,
      protectedCents: protectedCents,
      prefs: prefs,
      isPro: isPro,
      lastBackupAt: lastBackupAt,
      now: now,
    );

void main() {
  setUpAll(() => setActiveCurrency(currencyByCode('EUR')!));

  test('master off means silence, whatever else is true', () {
    expect(
      plan(
        items: [item(lastBurnedAt: now)],
        prefs: const NotificationPrefs(enabled: false),
        protectedCents: 100000,
      ),
      isEmpty,
    );
  });

  test('at most one notification per day, and never more than 20', () {
    final result = plan(
      items: [
        for (var i = 0; i < 6; i++)
          item(id: i, lastBurnedAt: now.subtract(Duration(days: i))),
      ],
      prefs: const NotificationPrefs(
        enabled: true,
        checkinFrequency: CheckinFrequency.daily,
      ),
      protectedCents: 500000,
    );
    final days = result.map((n) => '${n.when.month}-${n.when.day}').toList();
    expect(days.toSet().length, days.length, reason: 'one per day');
    expect(result.length, lessThanOrEqualTo(20));
  });

  test('everything respects quiet hours', () {
    final result = plan(
      items: [item(lastBurnedAt: now, resistanceCount: 2)],
      prefs: const NotificationPrefs(
        enabled: true,
        checkinHour: 23, // stored out-of-bounds on purpose
        checkinFrequency: CheckinFrequency.daily,
      ),
      protectedCents: 100000,
      isPro: true,
    );
    expect(result, isNotEmpty);
    for (final n in result) {
      expect(withinAllowedHours(n.when), isTrue,
          reason: '${n.when} must be inside 09:00–22:30');
    }
  });

  test('check-ins: 3x/week lands Mon/Wed/Fri; daily lands daily', () {
    final few = plan(prefs: const NotificationPrefs(enabled: true));
    expect(few, isNotEmpty);
    for (final n in few) {
      expect(
        [DateTime.monday, DateTime.wednesday, DateTime.friday],
        contains(n.when.weekday),
      );
    }
    final daily = plan(
      prefs: const NotificationPrefs(
        enabled: true,
        checkinFrequency: CheckinFrequency.daily,
      ),
    );
    expect(daily.length, greaterThan(few.length));
  });

  test('a burn today swallows today\'s check-in', () {
    final result = plan(
      items: [item(lastBurnedAt: now.subtract(const Duration(hours: 1)))],
      prefs: const NotificationPrefs(
        enabled: true,
        checkinFrequency: CheckinFrequency.daily,
      ),
    );
    expect(
      result.where((n) =>
          n.when.day == now.day && n.when.month == now.month),
      isEmpty,
    );
  });

  test('streak guards land 3 and 7 days after the last burn, mornings', () {
    final result = plan(
      items: [item(lastBurnedAt: now)],
      prefs: const NotificationPrefs(enabled: true, checkinEnabled: false),
    );
    expect(result, hasLength(2));
    expect(result.first.when.day, now.day + 3);
    expect(result.last.when.day, now.day + 7);
    for (final n in result) {
      expect(n.when.hour, 9);
      expect(n.when.minute, 30);
    }
  });

  test('destroyed items get no streak reminders — they are over', () {
    final result = plan(
      items: [item(lastBurnedAt: now, destroyedAt: now)],
      prefs: const NotificationPrefs(enabled: true, checkinEnabled: false),
    );
    expect(result, isEmpty);
  });

  test('monthly proof carries the amount, on the anniversary', () {
    final result = plan(
      items: [
        item(createdAt: DateTime(2026, 7, 15), lastBurnedAt: null),
      ],
      prefs: const NotificationPrefs(
        enabled: true,
        checkinEnabled: false,
        streakEnabled: false,
      ),
      protectedCents: 124000,
    );
    expect(result, hasLength(1));
    expect(result.single.when.day, 15);
    expect(result.single.body, contains('€1,240'));
  });

  test('an item one burn from the end invites the final burn', () {
    final result = plan(
      items: [
        item(resistanceCount: 2, lastBurnedAt: now), // kFinalBurnCount is 3
      ],
      prefs: const NotificationPrefs(enabled: true, checkinEnabled: false),
    );
    // Tomorrow morning outranks the +3d streak guard on its day.
    expect(result.first.when.day, now.day + 1);
    expect(result.first.body, contains('ended forever'));
  });

  test('backup nudges are Pro-only and 30 days spaced', () {
    final free = plan(
      prefs: const NotificationPrefs(enabled: true, checkinEnabled: false),
      lastBackupAt: now.subtract(const Duration(days: 40)),
    );
    expect(free, isEmpty);

    final pro = plan(
      prefs: const NotificationPrefs(enabled: true, checkinEnabled: false),
      isPro: true,
      lastBackupAt: now.subtract(const Duration(days: 40)),
    );
    expect(pro, hasLength(1));
    expect(pro.single.body.toLowerCase(), contains('backup'));
  });

  test('copy never names a temptation — amounts and streaks only', () {
    // The planner cannot even receive goal labels or thought text; this
    // pins the copy bank itself against future edits.
    final result = plan(
      items: [item(lastBurnedAt: now, resistanceCount: 2)],
      prefs: const NotificationPrefs(
        enabled: true,
        checkinFrequency: CheckinFrequency.daily,
      ),
      protectedCents: 100000,
      isPro: true,
      lastBackupAt: now.subtract(const Duration(days: 40)),
    );
    const banned = [
      'porn', 'alcohol', 'gambl', 'smok', 'sneaker', 'bag', 'breakup',
      'miss you', 'lose your streak',
    ];
    for (final n in result) {
      for (final word in banned) {
        expect(n.body.toLowerCase(), isNot(contains(word)));
        expect(n.title.toLowerCase(), isNot(contains(word)));
      }
    }
  });
}
