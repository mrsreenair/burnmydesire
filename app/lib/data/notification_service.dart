import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_planner.dart';

/// Thin wrapper over the plugin: init, permission, sync, cancel.
///
/// Scheduling uses absolute UTC instants, not repeating calendar rules
/// (NOTIFICATIONS.md §4): the wall-clock time is computed by the planner
/// in local time and converted here, and the whole schedule is rebuilt
/// on every burn/settings-change/resume — so a DST shift can drift only
/// a far-future one-shot, and only until the next app open.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static bool _tzReady = false;

  Future<void> init() async {
    if (!_tzReady) {
      tzdata.initializeTimeZones();
      _tzReady = true;
    }
    // Permission is asked contextually (victory screen / Settings),
    // never on init.
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// Asks iOS for permission. True when granted (alert only — no badge:
  /// a permanent red dot is a tiny anxiety machine).
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios == null) return false;
    final granted = await ios.requestPermissions(alert: true, sound: true);
    return granted ?? false;
  }

  /// Replaces everything pending with [plan]. Failures are logged and
  /// swallowed — notifications must never break a burn.
  Future<void> sync(List<PlannedNotification> plan) async {
    try {
      await _plugin.cancelAll();
      for (final n in plan) {
        if (!withinAllowedHours(n.when)) continue; // final safety net
        await _plugin.zonedSchedule(
          id: n.id,
          title: n.title,
          body: n.body,
          scheduledDate: tz.TZDateTime.from(n.when.toUtc(), tz.UTC),
          notificationDetails: const NotificationDetails(
            iOS: DarwinNotificationDetails(presentBadge: false),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } on Object catch (e) {
      debugPrint('NotificationService.sync: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } on Object catch (e) {
      debugPrint('NotificationService.cancelAll: $e');
    }
  }
}
