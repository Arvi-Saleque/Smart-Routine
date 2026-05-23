import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';
import 'package:routine_os/core/notifications/notification_scheduler.dart';
import 'package:routine_os/core/notifications/notification_service.dart';
import 'package:routine_os/core/notifications/notification_settings.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late AppDatabase database;
  late _FakeNotificationGateway notifications;
  late _FakeNotificationSettingsStore settings;
  late LocalRoutineNotificationScheduler scheduler;

  setUp(() {
    tzdata.initializeTimeZones();
    database = AppDatabase(NativeDatabase.memory());
    notifications = _FakeNotificationGateway();
    settings = _FakeNotificationSettingsStore();
    scheduler = LocalRoutineNotificationScheduler(
      database: database,
      notifications: notifications,
      settings: settings,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('schedules four reminders for each repeat day', () async {
    await _insertRoutine(database, routineId: 'routine-1');

    await scheduler.scheduleRoutineReminders(
      const RoutineReminderSchedule(
        routineId: 'routine-1',
        title: 'Read Bangla',
        routineType: 'fixedTime',
        targetSummary: '20 pages',
        startTimeMinutes: 1320,
        endTimeMinutes: 1380,
        repeatDays: {1, 3},
        fullDurationMinutes: 60,
        miniDurationMinutes: 10,
        isActive: true,
        reminderEnabled: true,
      ),
    );

    final reminders = await database.select(database.reminders).get();

    expect(notifications.initializeCalls, 1);
    expect(notifications.scheduled, hasLength(8));
    expect(reminders, hasLength(4));
    expect(
      reminders.map((reminder) => reminder.reminderType),
      containsAll(['preparation', 'start', 'late', 'recovery']),
    );
  });

  test('flexible routine schedules no reminders', () async {
    await scheduler.scheduleRoutineReminders(
      const RoutineReminderSchedule(
        routineId: 'routine-2',
        title: 'Flexible water',
        routineType: 'flexible',
        targetSummary: '8 glasses',
        startTimeMinutes: 480,
        endTimeMinutes: 1320,
        repeatDays: {1, 2, 3, 4, 5, 6, 7},
        fullDurationMinutes: 0,
        miniDurationMinutes: 0,
        isActive: true,
        reminderEnabled: true,
      ),
    );

    final reminders = await database.select(database.reminders).get();

    expect(notifications.scheduled, isEmpty);
    expect(notifications.cancelled, isNotEmpty);
    expect(reminders, isEmpty);
  });

  test('does not schedule when global reminders are disabled', () async {
    settings.enabled = false;
    await _insertRoutine(database, routineId: 'routine-3');

    await scheduler.scheduleRoutineReminders(
      const RoutineReminderSchedule(
        routineId: 'routine-3',
        title: 'Read Bangla',
        routineType: 'fixedTime',
        targetSummary: '20 pages',
        startTimeMinutes: 1320,
        endTimeMinutes: 1380,
        repeatDays: {1},
        fullDurationMinutes: 60,
        miniDurationMinutes: 10,
        isActive: true,
        reminderEnabled: true,
      ),
    );

    final reminders = await database.select(database.reminders).get();

    expect(notifications.initializeCalls, 0);
    expect(notifications.scheduled, isEmpty);
    expect(reminders, isEmpty);
  });

  test(
    'cancellation removes reminder rows and cancels notification ids',
    () async {
      await _insertRoutine(database, routineId: 'routine-4');
      await scheduler.scheduleRoutineReminders(
        const RoutineReminderSchedule(
          routineId: 'routine-4',
          title: 'Read Bangla',
          routineType: 'fixedTime',
          targetSummary: '20 pages',
          startTimeMinutes: 1320,
          endTimeMinutes: 1380,
          repeatDays: {1},
          fullDurationMinutes: 60,
          miniDurationMinutes: 10,
          isActive: true,
          reminderEnabled: true,
        ),
      );

      notifications.clearCalls();
      await scheduler.cancelRoutineReminders('routine-4');

      final reminders = await database.select(database.reminders).get();

      expect(reminders, isEmpty);
      expect(notifications.calls, hasLength(28));
      expect(
        notifications.calls.every((call) => call.type == 'cancel'),
        isTrue,
      );
    },
  );

  test(
    'rescheduling cancels old ids before scheduling new reminders',
    () async {
      await _insertRoutine(database, routineId: 'routine-5');
      const firstSchedule = RoutineReminderSchedule(
        routineId: 'routine-5',
        title: 'Read Bangla',
        routineType: 'fixedTime',
        targetSummary: '20 pages',
        startTimeMinutes: 1320,
        endTimeMinutes: 1380,
        repeatDays: {1},
        fullDurationMinutes: 60,
        miniDurationMinutes: 10,
        isActive: true,
        reminderEnabled: true,
      );

      await scheduler.scheduleRoutineReminders(firstSchedule);
      notifications.clearCalls();

      await scheduler.scheduleRoutineReminders(
        const RoutineReminderSchedule(
          routineId: 'routine-5',
          title: 'Read Bangla',
          routineType: 'fixedTime',
          targetSummary: '20 pages',
          startTimeMinutes: 1380,
          endTimeMinutes: 1440,
          repeatDays: {2},
          fullDurationMinutes: 60,
          miniDurationMinutes: 10,
          isActive: true,
          reminderEnabled: true,
        ),
      );

      expect(notifications.calls, hasLength(32));
      expect(
        notifications.calls.take(28).every((call) => call.type == 'cancel'),
        isTrue,
      );
      expect(
        notifications.calls.skip(28).every((call) => call.type == 'schedule'),
        isTrue,
      );
    },
  );
}

Future<void> _insertRoutine(
  AppDatabase database, {
  required String routineId,
}) async {
  final now = DateTime.now();
  await database
      .into(database.routines)
      .insert(
        RoutinesCompanion.insert(
          id: routineId,
          title: 'Read Bangla',
          description: const Value(null),
          categoryId: 'reading',
          routineType: 'fixedTime',
          goalType: 'count',
          targetValue: const Value(20),
          targetUnit: const Value('pages'),
          priority: 'medium',
          difficulty: 'normal',
          fullDurationMinutes: 60,
          mediumDurationMinutes: 30,
          miniDurationMinutes: 10,
          reminderEnabled: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
}

class _FakeNotificationGateway implements NotificationGateway {
  int initializeCalls = 0;
  final scheduled = <int>[];
  final cancelled = <int>[];
  final calls = <_NotificationCall>[];

  void clearCalls() {
    calls.clear();
    scheduled.clear();
    cancelled.clear();
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    calls.add(_NotificationCall('cancel', id));
  }

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return true;
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    scheduled.add(id);
    calls.add(_NotificationCall('schedule', id));
  }
}

class _NotificationCall {
  const _NotificationCall(this.type, this.id);

  final String type;
  final int id;
}

class _FakeNotificationSettingsStore implements NotificationSettingsStore {
  bool enabled = true;

  @override
  Future<bool> remindersEnabled() async => enabled;

  @override
  Future<void> setRemindersEnabled(bool enabled) async {
    this.enabled = enabled;
  }

  @override
  Stream<bool> watchRemindersEnabled() async* {
    yield enabled;
  }
}
