import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database_provider.dart';
import 'notification_scheduler.dart';
import 'notification_service.dart';
import 'notification_settings.dart';

final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => LocalNotificationService(),
);

final notificationSettingsStoreProvider = Provider<NotificationSettingsStore>((
  ref,
) {
  final store = SharedPreferencesNotificationSettings();
  ref.onDispose(store.dispose);
  return store;
});

final remindersEnabledProvider = StreamProvider<bool>((ref) {
  return ref.watch(notificationSettingsStoreProvider).watchRemindersEnabled();
});

final notificationSchedulerProvider = Provider<RoutineNotificationScheduler>(
  (ref) => LocalRoutineNotificationScheduler(
    database: ref.watch(appDatabaseProvider),
    notifications: ref.watch(notificationGatewayProvider),
    settings: ref.watch(notificationSettingsStoreProvider),
  ),
);
