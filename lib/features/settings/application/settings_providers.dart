import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database_provider.dart';
import '../../../core/notifications/notification_providers.dart';
import '../../../core/notifications/notification_settings.dart';
import '../data/settings_repository.dart';
import 'settings_controller.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final repository = SettingsRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final settingsControllerProvider = Provider<SettingsController>(
  (ref) => SettingsController(
    settingsRepository: ref.watch(settingsRepositoryProvider),
    notificationScheduler: ref.watch(notificationSchedulerProvider),
    database: ref.watch(appDatabaseProvider),
  ),
);

final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref.watch(settingsRepositoryProvider).watchThemeMode(),
);

final reminderSettingsProvider = StreamProvider<ReminderSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchReminderSettings(),
);

final startOfWeekProvider = StreamProvider<StartOfWeek>(
  (ref) => ref.watch(settingsRepositoryProvider).watchStartOfWeek(),
);
