import 'package:burn_my_desire/data/database.dart';
import 'package:burn_my_desire/data/financial_goal.dart';
import 'package:burn_my_desire/data/weekly_report.dart';
import 'package:flutter_test/flutter_test.dart';

/// The weekly Ash Report (GROWTH.md M4): windows, sums, and the chip.
void main() {
  // Mon 10 Aug 2026 is a Monday; Sun 16 Aug a Sunday.
  final monday = DateTime(2026, 8, 10);
  final sunday = DateTime(2026, 8, 16, 20);

  group('window', () {
    test('weeks start on Monday, local midnight', () {
      expect(weekStartOf(DateTime(2026, 8, 16, 23, 59)), monday);
      expect(weekStartOf(DateTime(2026, 8, 10, 0, 1)), monday);
      expect(weekStartOf(DateTime(2026, 8, 9, 23, 59)), DateTime(2026, 8, 3));
    });

    test('Thursday to Sunday show this week; Monday and Tuesday last week', () {
      final thu = reportWindowFor(DateTime(2026, 8, 13, 12));
      expect(thu.label, 'This week');
      expect(thu.start, monday);
      // Ends at the week boundary, not at "now": a burn made after the
      // window was computed must still count.
      expect(thu.end, DateTime(2026, 8, 17));

      final tue = reportWindowFor(DateTime(2026, 8, 18, 9));
      expect(tue.label, 'Last week');
      expect(tue.start, monday);
      expect(tue.end, DateTime(2026, 8, 17));

      final wed = reportWindowFor(DateTime(2026, 8, 19, 9));
      expect(wed.label, 'This week');
      expect(wed.start, DateTime(2026, 8, 17));
    });

    test('the Sunday moment is 18:00 of the same week', () {
      expect(weeklyReportMoment(DateTime(2026, 8, 12)), DateTime(2026, 8, 16, 18));
      expect(weeklyReportMoment(sunday), DateTime(2026, 8, 16, 18));
    });
  });

  group('summary', () {
    Item item({
      required int id,
      required DateTime createdAt,
      int priceCents = 10000,
      String category = 'purchase',
      DateTime? boughtAt,
    }) => Item(
      id: id,
      imageFile: '',
      priceCents: priceCents,
      category: category,
      resistanceCount: 1,
      createdAt: createdAt,
      boughtAt: boughtAt,
    );

    Burn burn(int id, int itemId, DateTime at, {String category = 'purchase'}) =>
        Burn(id: id, itemId: itemId, at: at, priceCents: 10000, category: category);

    final window = ReportWindow(
      start: monday,
      end: DateTime(2026, 8, 17),
      label: 'This week',
    );

    test('counts burns, re-burns, thoughts and money kept', () {
      final oldItem = item(id: 1, createdAt: DateTime(2026, 8, 1));
      final newItem = item(id: 2, createdAt: DateTime(2026, 8, 12, 10));
      final thought = item(
        id: 3,
        createdAt: DateTime(2026, 8, 13),
        category: 'emotion',
        priceCents: 0,
      );
      final r = summariseWeek(
        window: window,
        items: [oldItem, newItem, thought],
        burns: [
          burn(1, 1, DateTime(2026, 8, 11)), // re-burn of the old one
          burn(2, 2, DateTime(2026, 8, 12, 10)), // first burn of the new one
          burn(3, 3, DateTime(2026, 8, 13), category: 'emotion'),
          burn(4, 2, DateTime(2026, 8, 20)), // next week: not counted
        ],
        protectedTotalCents: 20000,
        goal: const FinancialGoal(name: 'A trip', emoji: '✈️', targetCents: 100000),
      );
      expect(r.burns, 3);
      expect(r.reBurns, 1);
      expect(r.thoughts, 1);
      expect(r.protectedCents, 10000);
      expect(r.goalPercentBefore, 10);
      expect(r.goalPercentAfter, 20);
      expect(r.goalGain, 10);
      expect(r.isEmpty, isFalse);
    });

    test('a confessed purchase keeps nothing', () {
      final bought = item(
        id: 1,
        createdAt: DateTime(2026, 8, 12),
        boughtAt: DateTime(2026, 8, 15),
      );
      final r = summariseWeek(
        window: window,
        items: [bought],
        burns: [burn(1, 1, DateTime(2026, 8, 12))],
        protectedTotalCents: 0,
      );
      expect(r.burns, 1);
      expect(r.protectedCents, 0);
    });

    test('an empty week is empty, and says so gently', () {
      final r = summariseWeek(
        window: window,
        items: const [],
        burns: const [],
        protectedTotalCents: 0,
      );
      expect(r.isEmpty, isTrue);
      expect(weeklyReportLine(r), contains('Quiet'));
    });
  });

  group('home chip', () {
    final report = WeeklyReport(
      window: ReportWindow(start: monday, end: sunday, label: 'This week'),
      burns: 2,
      reBurns: 0,
      thoughts: 0,
      protectedCents: 5000,
      goalPercentBefore: 0,
      goalPercentAfter: 1,
    );

    test('shows Saturday through Tuesday, until opened', () {
      expect(
        ashReportChipDue(now: sunday, report: report, seenWindowKey: null),
        isTrue,
      );
      expect(
        ashReportChipDue(
          now: sunday,
          report: report,
          seenWindowKey: report.window.key,
        ),
        isFalse,
      );
      // Wednesday: no chip, whatever the state.
      expect(
        ashReportChipDue(
          now: DateTime(2026, 8, 12),
          report: report,
          seenWindowKey: null,
        ),
        isFalse,
      );
    });

    test('never for an empty week', () {
      final empty = WeeklyReport(
        window: report.window,
        burns: 0,
        reBurns: 0,
        thoughts: 0,
        protectedCents: 0,
        goalPercentBefore: 0,
        goalPercentAfter: 0,
      );
      expect(
        ashReportChipDue(now: sunday, report: empty, seenWindowKey: null),
        isFalse,
      );
    });
  });
}
