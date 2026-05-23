import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

abstract class NotificationSettingsStore {
  Future<bool> remindersEnabled();

  Future<void> setRemindersEnabled(bool enabled);

  Stream<bool> watchRemindersEnabled();

  Future<ReminderSettings> reminderSettings();

  Future<void> setReminderSettings(ReminderSettings settings);

  Stream<ReminderSettings> watchReminderSettings();
}

class ReminderSettings {
  const ReminderSettings({
    this.remindersEnabled = true,
    this.defaultPreparationReminderMinutes = 10,
    this.defaultLateReminderMinutes = 10,
  });

  final bool remindersEnabled;
  final int defaultPreparationReminderMinutes;
  final int defaultLateReminderMinutes;

  ReminderSettings copyWith({
    bool? remindersEnabled,
    int? defaultPreparationReminderMinutes,
    int? defaultLateReminderMinutes,
  }) {
    return ReminderSettings(
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      defaultPreparationReminderMinutes:
          defaultPreparationReminderMinutes ??
          this.defaultPreparationReminderMinutes,
      defaultLateReminderMinutes:
          defaultLateReminderMinutes ?? this.defaultLateReminderMinutes,
    );
  }
}

class NotificationSettingsKeys {
  const NotificationSettingsKeys._();

  static const remindersEnabled = 'notifications.reminders_enabled';
  static const defaultPreparationReminderMinutes =
      'notifications.default_preparation_reminder_minutes';
  static const defaultLateReminderMinutes =
      'notifications.default_late_reminder_minutes';
}

class SharedPreferencesNotificationSettings
    implements NotificationSettingsStore {
  final _controller = StreamController<ReminderSettings>.broadcast();

  @override
  Future<bool> remindersEnabled() async {
    return (await reminderSettings()).remindersEnabled;
  }

  @override
  Future<void> setRemindersEnabled(bool enabled) async {
    final settings = await reminderSettings();
    await setReminderSettings(settings.copyWith(remindersEnabled: enabled));
  }

  @override
  Stream<bool> watchRemindersEnabled() async* {
    yield await remindersEnabled();
    yield* _controller.stream.map((settings) => settings.remindersEnabled);
  }

  @override
  Future<ReminderSettings> reminderSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return ReminderSettings(
      remindersEnabled:
          preferences.getBool(NotificationSettingsKeys.remindersEnabled) ??
          true,
      defaultPreparationReminderMinutes:
          preferences.getInt(
            NotificationSettingsKeys.defaultPreparationReminderMinutes,
          ) ??
          10,
      defaultLateReminderMinutes:
          preferences.getInt(
            NotificationSettingsKeys.defaultLateReminderMinutes,
          ) ??
          10,
    );
  }

  @override
  Future<void> setReminderSettings(ReminderSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      NotificationSettingsKeys.remindersEnabled,
      settings.remindersEnabled,
    );
    await preferences.setInt(
      NotificationSettingsKeys.defaultPreparationReminderMinutes,
      settings.defaultPreparationReminderMinutes,
    );
    await preferences.setInt(
      NotificationSettingsKeys.defaultLateReminderMinutes,
      settings.defaultLateReminderMinutes,
    );
    _controller.add(settings);
  }

  @override
  Stream<ReminderSettings> watchReminderSettings() async* {
    yield await reminderSettings();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
