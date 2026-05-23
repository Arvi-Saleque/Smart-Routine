import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationGateway {
  Future<bool> initialize();

  Future<void> scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  });

  Future<void> cancel(int id);
}

class LocalNotificationService implements NotificationGateway {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _permissionGranted = true;

  static const _channelId = 'routine_reminders';
  static const _channelName = 'Routine reminders';
  static const _channelDescription = 'Time-wise routine reminders';

  @override
  Future<bool> initialize() async {
    if (_initialized) return _permissionGranted;

    tzdata.initializeTimeZones();
    _setFallbackLocalLocation();

    const androidSettings = AndroidInitializationSettings('ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      _permissionGranted =
          await android?.requestNotificationsPermission() ?? true;
      return _permissionGranted;
    } catch (_) {
      _permissionGranted = false;
      return false;
    }
  }

  @override
  Future<void> scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) {
    return _plugin.cancel(id: id);
  }

  void _setFallbackLocalLocation() {
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
