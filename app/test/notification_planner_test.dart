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
  DateTime? renewsAt,
  String? renewalPrice,
  int burnsThisWeek = 0,
}) =>
    planNotifications(
      items: items,
      protectedCents: protectedCents,
      prefs: prefs,
      isPro: isPro,
      lastBackupAt: lastBackupAt,
      renewsAt: renewsAt,
      renewalPrice: renewalPrice,
      burnsThisWeek: burnsThisWeek,
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

  group('renewal reminder — the promise on the paywall (GROWTH.md M1)', () {
    test('lands three mornings before the charge, with the price', () {
      final renewsAt = now.add(const Duration(days: 20));
      final out = plan(isPro: true, renewsAt: renewsAt, renewalPrice: '€14.99');
      final reminder = out.firstWhere((n) => n.body.contains('renews'));
      expect(reminder.when.difference(renewsAt).inDays, -3);
      expect(reminder.when.hour, 9);
      expect(reminder.body, contains('€14.99'));
      expect(reminder.body, contains('cancel'));
    });

    test('beats every other kind on its day', () {
      // A final-burn invitation would land tomorrow morning too.
      final renewsAt = now.add(const Duration(days: 4));
      final out = plan(
        isPro: true,
        items: [item(resistanceCount: 2)],
        renewsAt: renewsAt,
      );
      final tomorrow = out.where((n) => n.when.day == now.day + 1);
      expect(tomorrow, hasLength(1));
      expect(tomorrow.single.body, contains('renews'));
    });

    test('a missed lead still says it tomorrow, if that is before the charge', () {
      final out = plan(isPro: true, renewsAt: now.add(const Duration(days: 2)));
      final reminder = out.firstWhere((n) => n.body.contains('renews'));
      expect(reminder.when.day, now.day + 1);
    });

    test('never fires after the charge, and never for lifetime or free', () {
      // Renewing tomorrow at 03:00: tomorrow 09:30 is after it — silence
      // beats a reminder that arrives late and reads as a joke.
      expect(
        plan(
          isPro: true,
          renewsAt: DateTime(now.year, now.month, now.day + 1, 3),
        ).where((n) => n.body.contains('renews')),
        isEmpty,
      );
      expect(plan(isPro: true).where((n) => n.body.contains('renews')), isEmpty);
    });

    test('is not silenced by the per-category toggles, only the master', () {
      final quiet = const NotificationPrefs(
        enabled: true,
        checkinEnabled: false,
        streakEnabled: false,
        milestoneEnabled: false,
        backupEnabled: false,
      );
      final out = plan(
        isPro: true,
        prefs: quiet,
        renewsAt: now.add(const Duration(days: 10)),
      );
      expect(out, hasLength(1));
      expect(out.single.body, contains('renews'));
    });
  });

  group('weekly Ash Report push (GROWTH.md M4)', () {
    test('lands Sunday 18:00 of the current week, with the count', () {
      final out = plan(burnsThisWeek: 3);
      final weekly = out.firstWhere((n) => n.body.contains('Ash Report'));
      expect(weekly.when.weekday, DateTime.sunday);
      expect(weekly.when.hour, 18);
      expect(weekly.when.difference(now).inDays, lessThan(7));
      expect(weekly.body, contains('3 burns'));
    });

    test('an empty week gets no push, ever', () {
      expect(
        plan(burnsThisWeek: 0).where((n) => n.body.contains('Ash Report')),
        isEmpty,
      );
    });

    test('has its own toggle', () {
      final out = plan(
        burnsThisWeek: 2,
        prefs: const NotificationPrefs(enabled: true, weeklyEnabled: false),
      );
      expect(out.where((n) => n.body.contains('Ash Report')), isEmpty);
    });

    test('a streak guard on Sunday outranks it; a check-in does not', () {
      // Streak +7 from a Sunday burn lands next Sunday 09:30 — same day.
      final lastSunday = now.subtract(const Duration(days: 1));
      final withStreak = plan(
        burnsThisWeek: 1,
        items: [item(lastBurnedAt: lastSunday)],
        prefs: const NotificationPrefs(enabled: true, checkinEnabled: false),
      );
      final sunday = withStreak.where((n) => n.when.weekday == DateTime.sunday);
      expect(sunday.first.body, isNot(contains('Ash Report')));

      final withCheckin = plan(
        burnsThisWeek: 1,
        prefs: const NotificationPrefs(
          enabled: true,
          checkinFrequency: CheckinFrequency.daily,
        ),
      );
      final sun = withCheckin
          .where((n) => n.when.weekday == DateTime.sunday)
          .first;
      expect(sun.body, contains('Ash Report'));
    });
  });
}
