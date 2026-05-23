import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../data/settings_repository.dart';

class SettingsController {
  const SettingsController({
    required SettingsRepository settingsRepository,
    required RoutineNotificationScheduler notificationScheduler,
    required AppDatabase database,
  }) : _settingsRepository = settingsRepository,
       _notificationScheduler = notificationScheduler,
       _database = database;

  final SettingsRepository _settingsRepository;
  final RoutineNotificationScheduler _notificationScheduler;
  final AppDatabase _database;

  Future<void> setThemeMode(ThemeMode mode) {
    return _settingsRepository.setThemeMode(mode);
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    final settings = await _settingsRepository.reminderSettings();
    await _settingsRepository.setReminderSettings(
      settings.copyWith(remindersEnabled: enabled),
    );

    if (enabled) {
      await _notificationScheduler.initializeAndReschedule();
    } else {
      await _notificationScheduler.cancelAllRoutineReminders();
    }
  }

  Future<void> setPreparationReminderMinutes(int minutes) async {
    final settings = await _settingsRepository.reminderSettings();
    await _settingsRepository.setReminderSettings(
      settings.copyWith(defaultPreparationReminderMinutes: minutes),
    );
    if (settings.remindersEnabled) {
      await _notificationScheduler.initializeAndReschedule();
    }
  }

  Future<void> setLateReminderMinutes(int minutes) async {
    final settings = await _settingsRepository.reminderSettings();
    await _settingsRepository.setReminderSettings(
      settings.copyWith(defaultLateReminderMinutes: minutes),
    );
    if (settings.remindersEnabled) {
      await _notificationScheduler.initializeAndReschedule();
    }
  }

  Future<void> setStartOfWeek(StartOfWeek startOfWeek) {
    return _settingsRepository.setStartOfWeek(startOfWeek);
  }

  Future<void> clearAllData() {
    return _settingsRepository.clearAllData(
      database: _database,
      scheduler: _notificationScheduler,
    );
  }
}
