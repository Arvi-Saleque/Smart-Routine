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
    final repeatDays = _futureWeekdays(2);
    await _insertRoutine(database, routineId: 'routine-1');

    await scheduler.scheduleRoutineReminders(
      RoutineReminderSchedule(
        routineId: 'routine-1',
        title: 'Read Bangla',
        routineType: 'fixedTime',
        targetSummary: '20 pages',
        startTimeMinutes: 1320,
        endTimeMinutes: 1380,
        repeatDays: repeatDays,
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

  test('uses stored preparation and late reminder defaults', () async {
    final repeatDays = _futureWeekdays(1);
    settings.preparationMinutes = 20;
    settings.lateMinutes = 7;
    await _insertRoutine(database, routineId: 'routine-custom');

    await scheduler.scheduleRoutineReminders(
      RoutineReminderSchedule(
        routineId: 'routine-custom',
        title: 'Read Bangla',
        routineType: 'fixedTime',
        targetSummary: '20 pages',
        startTimeMinutes: 1320,
        endTimeMinutes: 1380,
        repeatDays: repeatDays,
        fullDurationMinutes: 60,
        miniDurationMinutes: 10,
        isActive: true,
        reminderEnabled: true,
      ),
    );

    final reminders = await database.select(database.reminders).get();
    final offsetsByType = {
      for (final reminder in reminders)
        reminder.reminderType: reminder.minutesOffset,
    };

    expect(offsetsByType['preparation'], -20);
    expect(offsetsByType['late'], 7);
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
      final repeatDays = _futureWeekdays(1);
      await _insertRoutine(database, routineId: 'routine-4');
      await scheduler.scheduleRoutineReminders(
        RoutineReminderSchedule(
          routineId: 'routine-4',
          title: 'Read Bangla',
          routineType: 'fixedTime',
          targetSummary: '20 pages',
          startTimeMinutes: 1320,
          endTimeMinutes: 1380,
          repeatDays: repeatDays,
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
      expect(notifications.calls, hasLength(84));
      expect(
        notifications.calls.every((call) => call.type == 'cancel'),
        isTrue,
      );
    },
  );

  test(
    'rescheduling cancels old ids before scheduling new reminders',
    () async {
      final firstRepeatDays = _futureWeekdays(1);
      final secondRepeatDays = _futureWeekdays(1, startOffset: 2);
      await _insertRoutine(database, routineId: 'routine-5');
      final firstSchedule = RoutineReminderSchedule(
        routineId: 'routine-5',
        title: 'Read Bangla',
        routineType: 'fixedTime',
        targetSummary: '20 pages',
        startTimeMinutes: 1320,
        endTimeMinutes: 1380,
        repeatDays: firstRepeatDays,
        fullDurationMinutes: 60,
        miniDurationMinutes: 10,
        isActive: true,
        reminderEnabled: true,
      );

      await scheduler.scheduleRoutineReminders(firstSchedule);
      notifications.clearCalls();

      await scheduler.scheduleRoutineReminders(
        RoutineReminderSchedule(
          routineId: 'routine-5',
          title: 'Read Bangla',
          routineType: 'fixedTime',
          targetSummary: '20 pages',
          startTimeMinutes: 1380,
          endTimeMinutes: 1440,
          repeatDays: secondRepeatDays,
          fullDurationMinutes: 60,
          miniDurationMinutes: 10,
          isActive: true,
          reminderEnabled: true,
        ),
      );

      expect(notifications.calls, hasLength(88));
      expect(
        notifications.calls.take(84).every((call) => call.type == 'cancel'),
        isTrue,
      );
      expect(
        notifications.calls.skip(84).every((call) => call.type == 'schedule'),
        isTrue,
      );
    },
  );

  test('today cancellation keeps future day reminders active', () async {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    await _insertRoutine(database, routineId: 'routine-future-safe');

    await scheduler.scheduleRoutineReminders(
      RoutineReminderSchedule(
        routineId: 'routine-future-safe',
        title: 'Read Bangla',
        routineType: 'fixedTime',
        targetSummary: '20 pages',
        startTimeMinutes: 720,
        endTimeMinutes: 780,
        repeatDays: {today.weekday, tomorrow.weekday},
        fullDurationMinutes: 60,
        miniDurationMinutes: 10,
        isActive: true,
        reminderEnabled: true,
      ),
    );

    await scheduler.cancelRemainingTodayReminders(
      'routine-future-safe',
      now: today,
    );

    expect(
      notifications.cancelled,
      containsAll([
        notificationIdForDate(
          routineId: 'routine-future-safe',
          type: RoutineReminderType.start,
          date: today,
        ),
        notificationIdForDate(
          routineId: 'routine-future-safe',
          type: RoutineReminderType.late,
          date: today,
        ),
        notificationIdForDate(
          routineId: 'routine-future-safe',
          type: RoutineReminderType.recovery,
          date: today,
        ),
      ]),
    );
    expect(
      notifications.active,
      contains(
        notificationIdForDate(
          routineId: 'routine-future-safe',
          type: RoutineReminderType.start,
          date: tomorrow,
        ),
      ),
    );
  });
}

Set<int> _futureWeekdays(int count, {int startOffset = 1}) {
  final today = DateTime.now();
  return {
    for (var offset = startOffset; offset < startOffset + count; offset++)
      today.add(Duration(days: offset)).weekday,
  };
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
  final active = <int>{};
  final calls = <_NotificationCall>[];

  void clearCalls() {
    calls.clear();
    scheduled.clear();
    cancelled.clear();
    active.clear();
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    active.remove(id);
    calls.add(_NotificationCall('cancel', id));
  }

  @override
  Future<bool> initialize() async {
    initializeCalls++;
    return true;
  }

  @override
  Future<void> scheduleOneTime({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    scheduled.add(id);
    active.add(id);
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
  int preparationMinutes = 10;
  int lateMinutes = 10;

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

  @override
  Future<ReminderSettings> reminderSettings() async {
    return ReminderSettings(
      remindersEnabled: enabled,
      defaultPreparationReminderMinutes: preparationMinutes,
      defaultLateReminderMinutes: lateMinutes,
    );
  }

  @override
  Future<void> setReminderSettings(ReminderSettings settings) async {
    enabled = settings.remindersEnabled;
    preparationMinutes = settings.defaultPreparationReminderMinutes;
    lateMinutes = settings.defaultLateReminderMinutes;
  }

  @override
  Stream<ReminderSettings> watchReminderSettings() async* {
    yield await reminderSettings();
  }
}
