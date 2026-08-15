import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup.dart';
import '../data/cloud_backup.dart';
import '../data/notification_planner.dart';
import '../data/notification_prefs.dart';
import '../data/notification_service.dart';
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
  if (isPro) {
    lastBackup = await CloudBackup(
      BackupService(ref.read(databaseProvider), ref.read(imageStoreProvider)),
    ).lastBackup();
  }
  await service.sync(
    planNotifications(
      items: items,
      protectedCents: protected,
      prefs: prefs,
      isPro: isPro,
      lastBackupAt: lastBackup,
      now: DateTime.now(),
    ),
  );
}
