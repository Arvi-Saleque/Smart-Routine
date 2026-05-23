import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/notifications/notification_settings.dart';

class SettingsRepository {
  SettingsRepository();

  final _themeModeController = StreamController<ThemeMode>.broadcast();
  final _reminderController = StreamController<ReminderSettings>.broadcast();
  final _startOfWeekController = StreamController<StartOfWeek>.broadcast();

  static const _themeModeKey = 'settings.theme_mode';
  static const _startOfWeekKey = 'settings.start_of_week';

  Future<ThemeMode> themeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return _themeModeFromName(preferences.getString(_themeModeKey));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, mode.name);
    _themeModeController.add(mode);
  }

  Stream<ThemeMode> watchThemeMode() async* {
    yield await themeMode();
    yield* _themeModeController.stream;
  }

  Future<ReminderSettings> reminderSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return ReminderSettings(
      remindersEnabled:
          preferences.getBool(NotificationSettingsKeys.remindersEnabled) ??
          true,
      defaultPreparationReminderMinutes: _sanitizeReminderMinutes(
        preferences.getInt(
              NotificationSettingsKeys.defaultPreparationReminderMinutes,
            ) ??
            10,
      ),
      defaultLateReminderMinutes: _sanitizeReminderMinutes(
        preferences.getInt(
              NotificationSettingsKeys.defaultLateReminderMinutes,
            ) ??
            10,
      ),
    );
  }

  Future<void> setReminderSettings(ReminderSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    final sanitized = ReminderSettings(
      remindersEnabled: settings.remindersEnabled,
      defaultPreparationReminderMinutes: _sanitizeReminderMinutes(
        settings.defaultPreparationReminderMinutes,
      ),
      defaultLateReminderMinutes: _sanitizeReminderMinutes(
        settings.defaultLateReminderMinutes,
      ),
    );

    await preferences.setBool(
      NotificationSettingsKeys.remindersEnabled,
      sanitized.remindersEnabled,
    );
    await preferences.setInt(
      NotificationSettingsKeys.defaultPreparationReminderMinutes,
      sanitized.defaultPreparationReminderMinutes,
    );
    await preferences.setInt(
      NotificationSettingsKeys.defaultLateReminderMinutes,
      sanitized.defaultLateReminderMinutes,
    );
    _reminderController.add(sanitized);
  }

  Stream<ReminderSettings> watchReminderSettings() async* {
    yield await reminderSettings();
    yield* _reminderController.stream;
  }

  Future<StartOfWeek> startOfWeek() async {
    final preferences = await SharedPreferences.getInstance();
    return _startOfWeekFromName(preferences.getString(_startOfWeekKey));
  }

  Future<void> setStartOfWeek(StartOfWeek startOfWeek) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_startOfWeekKey, startOfWeek.name);
    _startOfWeekController.add(startOfWeek);
  }

  Stream<StartOfWeek> watchStartOfWeek() async* {
    yield await startOfWeek();
    yield* _startOfWeekController.stream;
  }

  Future<void> clearAllData({
    required AppDatabase database,
    required RoutineNotificationScheduler scheduler,
  }) async {
    await scheduler.cancelAllRoutineReminders();
    await database.clearUserData();
  }

  void dispose() {
    _themeModeController.close();
    _reminderController.close();
    _startOfWeekController.close();
  }

  ThemeMode _themeModeFromName(String? name) {
    return switch (name) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  StartOfWeek _startOfWeekFromName(String? name) {
    return switch (name) {
      'sunday' => StartOfWeek.sunday,
      _ => StartOfWeek.monday,
    };
  }

  int _sanitizeReminderMinutes(int minutes) => minutes.clamp(0, 240).toInt();
}

enum StartOfWeek {
  monday('Monday'),
  sunday('Sunday');

  const StartOfWeek(this.label);

  final String label;
}
