import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup.dart';
import '../data/cloud_backup.dart';
import '../data/notification_planner.dart';
import '../data/notification_prefs.dart';
import '../data/notification_service.dart';
import '../data/weekly_report.dart';
import 'db_providers.dart';
import 'pro_provider.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Rebuilds the entire pending schedule from current state
/// (NOTIFICATIONS.md §4). Cheap and idempotent — called after every
/// burn, after settings changes, and on launch/resume (root shell).
/// Every call site is a widget, hence WidgetRef.
Future<void> replanNotifications(WidgetRef ref) async {
  final service = ref.read(notificationServiceProvider);
  final prefs = await loadNotificationPrefs();
  if (!prefs.enabled) {
    await service.cancelAll();
    return;
  }
  final items = await ref.read(databaseProvider).watchItems().first;
  final protected = items.fold(0, (sum, i) => sum + i.priceCents);
  final isPro = ref.read(proProvider);
  DateTime? lastBackup;
  ProRenewal? renewal;
  if (isPro) {
    lastBackup = await CloudBackup(
      BackupService(ref.read(databaseProvider), ref.read(imageStoreProvider)),
    ).lastBackup();
    renewal = await ref.read(proRenewalProvider.future);
  }
  await service.sync(
    planNotifications(
      items: items,
      protectedCents: protected,
      prefs: prefs,
      isPro: isPro,
      lastBackupAt: lastBackup,
      renewsAt: renewal?.renewsAt,
      renewalPrice: renewal?.priceString,
      burnsThisWeek: await _burnsThisWeek(ref),
      now: DateTime.now(),
    ),
  );
}

/// Counted straight from the database rather than the provider, which
/// may not have finished its first load when the plan is rebuilt on
/// launch — and the very burn that triggered this replan must count.
Future<int> _burnsThisWeek(WidgetRef ref) async {
  final start = weekStartOf(DateTime.now());
  final burns = await ref.read(databaseProvider).watchBurnsSince(start).first;
  return burns.length;
}
