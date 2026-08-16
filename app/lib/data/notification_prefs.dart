import 'package:shared_preferences/shared_preferences.dart';

/// How often the check-in fires.
enum CheckinFrequency { daily, fewTimesAWeek }

/// Everything the notification planner needs to know about what the
/// user wants. Master off by default: notifications begin only when the
/// user says yes — on the victory-screen ask or in Settings.
class NotificationPrefs {
  const NotificationPrefs({
    this.enabled = false,
    this.checkinEnabled = true,
    this.checkinFrequency = CheckinFrequency.fewTimesAWeek,
    this.checkinHour = 21,
    this.streakEnabled = true,
    this.milestoneEnabled = true,
    this.weeklyEnabled = true,
    this.backupEnabled = true,
  });

  final bool enabled;
  final bool checkinEnabled;
  final CheckinFrequency checkinFrequency;

  /// Local hour of day for check-ins. Clamped into quiet-hour bounds by
  /// the planner, so a stored 23 can't fire at 23:00.
  final int checkinHour;

  final bool streakEnabled;
  final bool milestoneEnabled;

  /// The Sunday-evening Ash Report (GROWTH.md M4).
  final bool weeklyEnabled;
  final bool backupEnabled;

  NotificationPrefs copyWith({
    bool? enabled,
    bool? checkinEnabled,
    CheckinFrequency? checkinFrequency,
    int? checkinHour,
    bool? streakEnabled,
    bool? milestoneEnabled,
    bool? weeklyEnabled,
    bool? backupEnabled,
  }) => NotificationPrefs(
    enabled: enabled ?? this.enabled,
    checkinEnabled: checkinEnabled ?? this.checkinEnabled,
    checkinFrequency: checkinFrequency ?? this.checkinFrequency,
    checkinHour: checkinHour ?? this.checkinHour,
    streakEnabled: streakEnabled ?? this.streakEnabled,
    milestoneEnabled: milestoneEnabled ?? this.milestoneEnabled,
    weeklyEnabled: weeklyEnabled ?? this.weeklyEnabled,
    backupEnabled: backupEnabled ?? this.backupEnabled,
  );
}

const _kEnabled = 'notif_enabled';
const _kCheckin = 'notif_checkin';
const _kFrequency = 'notif_checkin_frequency';
const _kHour = 'notif_checkin_hour';
const _kStreak = 'notif_streak';
const _kMilestone = 'notif_milestone';
const _kWeekly = 'notif_weekly';
const _kBackup = 'notif_backup';
const _kAskShown = 'notif_ask_shown';

Future<NotificationPrefs> loadNotificationPrefs() async {
  final p = await SharedPreferences.getInstance();
  const d = NotificationPrefs();
  return NotificationPrefs(
    enabled: p.getBool(_kEnabled) ?? d.enabled,
    checkinEnabled: p.getBool(_kCheckin) ?? d.checkinEnabled,
    checkinFrequency: (p.getString(_kFrequency) == 'daily')
        ? CheckinFrequency.daily
        : d.checkinFrequency,
    checkinHour: p.getInt(_kHour) ?? d.checkinHour,
    streakEnabled: p.getBool(_kStreak) ?? d.streakEnabled,
    milestoneEnabled: p.getBool(_kMilestone) ?? d.milestoneEnabled,
    weeklyEnabled: p.getBool(_kWeekly) ?? d.weeklyEnabled,
    backupEnabled: p.getBool(_kBackup) ?? d.backupEnabled,
  );
}

Future<void> saveNotificationPrefs(NotificationPrefs prefs) async {
  final p = await SharedPreferences.getInstance();
  await p.setBool(_kEnabled, prefs.enabled);
  await p.setBool(_kCheckin, prefs.checkinEnabled);
  await p.setString(
    _kFrequency,
    prefs.checkinFrequency == CheckinFrequency.daily ? 'daily' : 'few',
  );
  await p.setInt(_kHour, prefs.checkinHour);
  await p.setBool(_kStreak, prefs.streakEnabled);
  await p.setBool(_kMilestone, prefs.milestoneEnabled);
  await p.setBool(_kWeekly, prefs.weeklyEnabled);
  await p.setBool(_kBackup, prefs.backupEnabled);
}

/// Whether the one-time victory-screen ask has been shown. Asked once,
/// ever — declining is an answer.
Future<bool> notificationAskShown() async =>
    (await SharedPreferences.getInstance()).getBool(_kAskShown) ?? false;

Future<void> markNotificationAskShown() async =>
    (await SharedPreferences.getInstance()).setBool(_kAskShown, true);
