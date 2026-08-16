import 'dart:math';

import '../config.dart';
import '../utils/format_utils.dart';
import 'database.dart';
import 'notification_prefs.dart';
import 'weekly_report.dart';

/// The scheduling brain (NOTIFICATIONS.md §4).
///
/// Pure: state in, schedule out. No plugin imports, no clocks of its
/// own, so every rule in it is unit-testable. The service layer cancels
/// everything pending and schedules exactly what this returns.
///
/// The one design rule, enforced structurally: this file never receives
/// goal labels, thought text, or anything describing WHAT the user is
/// resisting — so no future edit can leak a temptation onto a lock
/// screen. Amounts and streaks only.
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime when;
  final String title;
  final String body;
}

/// Priority when two candidates land on the same day (lower wins).
///
/// Renewal comes first, above everything: it's the one notification the
/// paywall *promises*. An app that says "we'll remind you before you're
/// charged" and then lets a streak nudge crowd that reminder out has
/// lied about the only thing that mattered.
enum _Kind { renewal, finalBurn, streak, weekly, milestone, backup, checkin }

class _Candidate {
  const _Candidate(this.kind, this.when, this.title, this.body);
  final _Kind kind;
  final DateTime when;
  final String title;
  final String body;
}

const _quietStartHour = 9; // nothing before 09:00
const _quietEndHour = 22; // nothing at or after 22:30
const _quietEndMinute = 30;
const _morningHour = 9;
const _morningMinute = 30;
const _horizonDays = 30;
const _maxScheduled = 20; // iOS caps pending at 64; stay far under

/// Streak-guard offsets: spaced repetition of the win.
const _streakDays = [3, 7];

/// Copy banks: fixed strings only, plus formatted amounts. Rotated by
/// day so repeats don't read as a broken record.
const _checkinLines = [
  'Anything pulling at you tonight? One minute here is cheaper than one '
      'tap of Buy Now.',
  'A quiet minute for yourself. What wants to be let go of today?',
  'The urge always feels urgent. It never actually is. Come check in.',
];

/// +3 days: the invitation to burn it again. Desires come back, the app
/// needs three burns to end one, and re-burning is free forever — so the
/// three-day nudge says so instead of only admiring the streak (M5).
const _streakLinesEarly = [
  'Three days on. Still want it? Burn it again — it\'s free, and it counts.',
  'The urge usually comes back around now. If it has, the fire\'s ready.',
];

/// +7 days: the streak itself.
const _streakLines = [
  'One of your desires hits a longer streak tomorrow. Come claim it.',
  'Still resisted. Still yours. Come see the streak grow.',
];

const _finalBurnLines = [
  'One desire is ready to be ended forever. You\'ve already beaten it '
      'every time it came back.',
];

/// Assembled per-plan because they carry the protected amount.
String _milestoneLine(int protectedCents, int months) {
  final amount = formatMoney(protectedCents);
  return months <= 1
      ? '$amount is still yours. A month of winning.'
      : '$amount is still yours. $months months of winning.';
}

const _backupLine =
    'Your wins deserve a backup. Thirty seconds, encrypted, yours.';

/// Sunday's line. Counts only — never what was burned.
String weeklyLine(int burnsThisWeek) => burnsThisWeek == 1
    ? 'One burn this week. Your Ash Report is ready.'
    : '$burnsThisWeek burns this week. Your Ash Report is ready.';

/// How far ahead of a renewal the reminder lands. Three days is long
/// enough to act on and short enough to still be about *this* charge.
const renewalReminderLeadDays = 3;

/// The renewal reminder. [price] is the store's own localized string.
/// Deliberately neutral about which way to go: the reminder is a
/// courtesy, not a retention tactic, and it reads that way.
String renewalLine(String? price) => price == null
    ? 'Pro renews in $renewalReminderLeadDays days. Keep it, or cancel in '
          'one tap — either is fine.'
    : 'Pro renews in $renewalReminderLeadDays days for $price. Keep it, or '
          'cancel in one tap — either is fine.';

const _title = 'Burn My Desire';

List<PlannedNotification> planNotifications({
  required List<Item> items,
  required int protectedCents,
  required NotificationPrefs prefs,
  required bool isPro,
  DateTime? lastBackupAt,

  /// When the current Pro subscription next bills, if it will. Null for
  /// lifetime, for a cancelled plan running out, and for free users.
  DateTime? renewsAt,
  String? renewalPrice,

  /// Burns so far in the week that contains [now]. Gates the Sunday
  /// report: an empty week gets no push, ever — "you did nothing" is
  /// not a notification this app sends.
  int burnsThisWeek = 0,
  required DateTime now,
}) {
  if (!prefs.enabled) return const [];

  final candidates = <_Candidate>[];
  final live = [
    for (final i in items)
      if (i.destroyedAt == null) i,
  ];
  final burnedToday = items.any((i) {
    final t = i.lastBurnedAt;
    return t != null && _sameDay(t, now);
  });

  // --- Check-ins: on the chosen days, at the chosen (clamped) hour.
  if (prefs.checkinEnabled) {
    final hour = prefs.checkinHour.clamp(_quietStartHour, _quietEndHour - 1);
    for (var d = 0; d <= _horizonDays; d++) {
      final day = DateTime(now.year, now.month, now.day + d);
      if (!checkinFallsOn(day, prefs)) continue;
      // A burn today already was the check-in.
      if (d == 0 && burnedToday) continue;
      final when = DateTime(day.year, day.month, day.day, hour);
      if (when.isBefore(now)) continue;
      candidates.add(
        _Candidate(
          _Kind.checkin,
          when,
          _title,
          _checkinLines[day.day % _checkinLines.length],
        ),
      );
    }
  }

  // --- Streak guards: +3 and +7 days after each live item's last burn.
  if (prefs.streakEnabled) {
    for (final item in live) {
      final base = item.lastBurnedAt ?? item.createdAt;
      for (final days in _streakDays) {
        final target = base.add(Duration(days: days));
        final when = _morning(target);
        if (when.isBefore(now)) continue;
        final lines = days == _streakDays.first ? _streakLinesEarly : _streakLines;
        candidates.add(
          _Candidate(_Kind.streak, when, _title, lines[when.day % lines.length]),
        );
      }
    }
  }

  // --- Monthly proof: anniversary of the first burn, with the total.
  if (prefs.milestoneEnabled && protectedCents > 0 && items.isNotEmpty) {
    final first = items
        .map((i) => i.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    for (var m = 1; m <= 12; m++) {
      final anniversary = DateTime(first.year, first.month + m, first.day);
      final when = _morning(anniversary);
      if (when.isBefore(now)) continue;
      candidates.add(
        _Candidate(
          _Kind.milestone,
          when,
          _title,
          _milestoneLine(protectedCents, m),
        ),
      );
      break; // only the next one — totals in later months will differ
    }
  }

  // --- Final-burn invitation: one burn away from ending it forever.
  if (prefs.streakEnabled &&
      live.any((i) => i.resistanceCount >= kFinalBurnCount - 1)) {
    final tomorrow = _morning(now.add(const Duration(days: 1)));
    candidates.add(
      _Candidate(_Kind.finalBurn, tomorrow, _title, _finalBurnLines.first),
    );
  }

  // --- Backup nudge (Pro): last backup older than 30 days.
  if (prefs.backupEnabled && isPro) {
    final due = lastBackupAt == null
        ? now.add(const Duration(days: 30))
        : lastBackupAt.add(const Duration(days: 30));
    final when = _morning(
      due.isBefore(now) ? now.add(const Duration(days: 1)) : due,
    );
    if (!when.isBefore(now)) {
      candidates.add(_Candidate(_Kind.backup, when, _title, _backupLine));
    }
  }

  // --- Weekly Ash Report: Sunday 18:00, only for a week with burns in it.
  // Only the coming Sunday — next week's count isn't knowable yet, and
  // the plan is rebuilt after every burn anyway.
  if (prefs.weeklyEnabled && burnsThisWeek > 0) {
    final when = weeklyReportMoment(now);
    if (!when.isBefore(now)) {
      candidates.add(
        _Candidate(_Kind.weekly, when, _title, weeklyLine(burnsThisWeek)),
      );
    }
  }

  // --- Renewal reminder: the promise on the paywall. Not behind any of
  // the per-category toggles — only the master switch — because it isn't
  // engagement, it's the courtesy that makes the subscription honest.
  if (renewsAt != null) {
    final target = renewsAt.subtract(
      const Duration(days: renewalReminderLeadDays),
    );
    // Missed the lead (installed late, phone off): say it tomorrow
    // morning as long as that's still before the charge.
    final when = target.isBefore(now)
        ? _morning(now.add(const Duration(days: 1)))
        : _morning(target);
    if (!when.isBefore(now) && when.isBefore(renewsAt)) {
      candidates.add(
        _Candidate(_Kind.renewal, when, _title, renewalLine(renewalPrice)),
      );
    }
  }

  // --- One per day, best kind wins; then the horizon and count caps.
  final byDay = <String, _Candidate>{};
  for (final c in candidates) {
    if (c.when.isAfter(now.add(const Duration(days: _horizonDays)))) continue;
    final key = '${c.when.year}-${c.when.month}-${c.when.day}';
    final existing = byDay[key];
    if (existing == null || c.kind.index < existing.kind.index) {
      byDay[key] = c;
    }
  }

  final chosen = byDay.values.toList()
    ..sort((a, b) => a.when.compareTo(b.when));
  return [
    for (final (i, c) in chosen.take(min(_maxScheduled, chosen.length)).indexed)
      PlannedNotification(
        id: i + 1,
        when: c.when,
        title: c.title,
        body: c.body,
      ),
  ];
}

/// Whether a check-in belongs on [day] under [prefs] (M5). Pure, so the
/// weekday and payday rules are testable on their own.
bool checkinFallsOn(DateTime day, NotificationPrefs prefs) {
  switch (prefs.checkinFrequency) {
    case CheckinFrequency.daily:
      return true;
    case CheckinFrequency.fewTimesAWeek:
      return const [
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      ].contains(day.weekday);
    case CheckinFrequency.weekends:
      return day.weekday >= DateTime.friday;
    case CheckinFrequency.payday:
      // Payday and the two days after: the money is new and the urge is
      // loudest. Days are counted forward from the pay date, so the 30th
      // still gets its follow-on days in a short month.
      for (var back = 0; back <= 2; back++) {
        final candidate = DateTime(day.year, day.month, day.day - back);
        if (candidate.day == prefs.paydayDay) return true;
      }
      return false;
  }
}

DateTime _morning(DateTime day) =>
    DateTime(day.year, day.month, day.day, _morningHour, _morningMinute);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// True when [when] respects quiet hours — exposed for tests, and used
/// as a final guard by the service so no code path can fire at 3 a.m.
bool withinAllowedHours(DateTime when) {
  if (when.hour < _quietStartHour) return false;
  if (when.hour > _quietEndHour) return false;
  if (when.hour == _quietEndHour && when.minute >= _quietEndMinute) {
    return false;
  }
  return true;
}
