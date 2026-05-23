import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

abstract class NotificationSettingsStore {
  Future<bool> remindersEnabled();

  Future<void> setRemindersEnabled(bool enabled);

  Stream<bool> watchRemindersEnabled();
}

class SharedPreferencesNotificationSettings
    implements NotificationSettingsStore {
  final _controller = StreamController<bool>.broadcast();

  static const _remindersEnabledKey = 'notifications.reminders_enabled';

  @override
  Future<bool> remindersEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_remindersEnabledKey) ?? true;
  }

  @override
  Future<void> setRemindersEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_remindersEnabledKey, enabled);
    _controller.add(enabled);
  }

  @override
  Stream<bool> watchRemindersEnabled() async* {
    yield await remindersEnabled();
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
