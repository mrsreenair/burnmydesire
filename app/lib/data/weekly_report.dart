import 'package:shared_preferences/shared_preferences.dart';

import 'database.dart';
import 'financial_goal.dart';

/// The weekly Ash Report (GROWTH.md M4): the one ritual that opens the
/// app when the user isn't tempted. Pure functions here — window
/// arithmetic and the summing — so the Sunday push, the home chip and
/// the screen all agree on what "this week" means.

/// Which seven days a report covers, and what to call them.
class ReportWindow {
  const ReportWindow({required this.start, required this.end, required this.label});

  /// Monday 00:00, local.
  final DateTime start;

  /// Exclusive. The following Monday 00:00 for a finished week; [now]
  /// for the week in progress.
  final DateTime end;

  /// "This week" or "Last week".
  final String label;

  /// Stable per-week key, for "already opened this one".
  String get key => '${start.year}-${start.month}-${start.day}';
}

/// Monday 00:00 of the week containing [d], local time.
DateTime weekStartOf(DateTime d) {
  final midnight = DateTime(d.year, d.month, d.day);
  return midnight.subtract(Duration(days: midnight.weekday - DateTime.monday));
}

/// The week a report should show *now*.
///
/// The push lands Sunday evening and talks about the week just lived, so
/// Thursday–Sunday show the week in progress. But someone opening the
/// report on Monday or Tuesday from a chip they didn't tap on Sunday
/// would find an empty page — so early in the week the report still
/// shows the finished one. Wednesday is the switch: by then the new week
/// has enough in it to be worth looking at.
ReportWindow reportWindowFor(DateTime now) {
  final thisMonday = weekStartOf(now);
  if (now.weekday <= DateTime.tuesday) {
    final lastMonday = thisMonday.subtract(const Duration(days: 7));
    return ReportWindow(start: lastMonday, end: thisMonday, label: 'Last week');
  }
  return ReportWindow(start: thisMonday, end: now, label: 'This week');
}

/// The Sunday-evening moment for the week containing [now]: 18:00 local.
/// Inside quiet hours, and after most people's Sunday has settled.
DateTime weeklyReportMoment(DateTime now) =>
    weekStartOf(now).add(const Duration(days: 6, hours: 18));

class WeeklyReport {
  const WeeklyReport({
    required this.window,
    required this.burns,
    required this.reBurns,
    required this.thoughts,
    required this.protectedCents,
    required this.goalPercentBefore,
    required this.goalPercentAfter,
  });

  final ReportWindow window;

  /// Every burn in the window, thoughts included.
  final int burns;

  /// Burns of desires already in the fight — the ones that came back.
  final int reBurns;

  /// Thought burns in the window.
  final int thoughts;

  /// Money first protected this week: new purchase items created in the
  /// window and not since confessed as bought. Re-burns add nothing —
  /// the same rule as the ledger.
  final int protectedCents;

  /// Goal progress at the start and end of the window (0 when no goal).
  final int goalPercentBefore;
  final int goalPercentAfter;

  bool get isEmpty => burns == 0;
  int get goalGain => goalPercentAfter - goalPercentBefore;
}

/// Sums a week from the raw rows. [items] is the whole ledger, [burns]
/// every burn row in the window, [protectedTotalCents] the current
/// headline total (so "before" can be derived without a second query).
WeeklyReport summariseWeek({
  required ReportWindow window,
  required List<Item> items,
  required List<Burn> burns,
  required int protectedTotalCents,
  FinancialGoal? goal,
}) {
  final inWindow = [
    for (final b in burns)
      if (!b.at.isBefore(window.start) && b.at.isBefore(window.end)) b,
  ];
  final thoughts = inWindow.where((b) => b.category == 'emotion').length;

  // A burn is a re-burn when its item already existed before it.
  final createdAt = {for (final i in items) i.id: i.createdAt};
  var reBurns = 0;
  for (final b in inWindow) {
    final c = createdAt[b.itemId];
    if (c != null && c.isBefore(b.at) && b.at.difference(c).inSeconds > 1) {
      reBurns++;
    }
  }

  var protectedThisWeek = 0;
  for (final i in items) {
    if (i.category == 'emotion' || i.boughtAt != null) continue;
    if (!i.createdAt.isBefore(window.start) && i.createdAt.isBefore(window.end)) {
      protectedThisWeek += i.priceCents;
    }
  }

  final before = goal?.percentOf(protectedTotalCents - protectedThisWeek) ?? 0;
  final after = goal?.percentOf(protectedTotalCents) ?? 0;

  return WeeklyReport(
    window: window,
    burns: inWindow.length,
    reBurns: reBurns,
    thoughts: thoughts,
    protectedCents: protectedThisWeek,
    goalPercentBefore: before,
    goalPercentAfter: after,
  );
}

/// One line for the top of the report, chosen by what the week held.
/// Rotated by week so the same kind of week doesn't read the same twice.
String weeklyReportLine(WeeklyReport r) {
  final n = r.window.start.day;
  if (r.burns == 0) return 'A quiet week. Quiet is allowed.';
  if (r.thoughts > 0 && r.protectedCents == 0) {
    return const [
      'You put things down this week. That\'s the whole practice.',
      'Nothing bought, something let go. A good week.',
    ][n % 2];
  }
  if (r.reBurns > 0 && r.protectedCents == 0) {
    return const [
      'It came back. You burned it again. That\'s what winning looks like.',
      'No new desires — just old ones losing. Keep going.',
    ][n % 2];
  }
  return const [
    'Money that would have left, didn\'t. That\'s the week.',
    'Every one of these was a tap away. None of them happened.',
    'Not spent. Not forgotten either — it\'s all still yours.',
  ][n % 3];
}

const _kSeenKey = 'ash_report_seen_window';

/// The window key of the last report the user opened, so the home chip
/// can go quiet once it's been read.
Future<String?> ashReportSeenWindow() async =>
    (await SharedPreferences.getInstance()).getString(_kSeenKey);

Future<void> markAshReportSeen(ReportWindow window) async =>
    (await SharedPreferences.getInstance()).setString(_kSeenKey, window.key);

/// Whether the home chip should show: from Saturday through Tuesday
/// (the report's own weekend-plus-grace), only for a non-empty week, and
/// only until it's been opened. Pure so the rule is testable.
bool ashReportChipDue({
  required DateTime now,
  required WeeklyReport? report,
  required String? seenWindowKey,
}) {
  if (report == null || report.isEmpty) return false;
  final weekend = now.weekday >= DateTime.saturday;
  final grace = now.weekday <= DateTime.tuesday;
  if (!weekend && !grace) return false;
  return seenWindowKey != report.window.key;
}
