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

  test('specificDate schedule can schedule reminders for tomorrow', () async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowKey = _dateKey(tomorrow);
    await _insertRoutine(database, routineId: 'routine-specific');
    await _insertSchedule(
      database,
      routineId: 'routine-specific',
      specificDate: tomorrowKey,
      repeatDays: '',
    );
    final row = await (database.select(database.routines).join([
      innerJoin(
        database.routineSchedules,
        database.routineSchedules.routineId.equalsExp(database.routines.id),
      ),
    ])..where(database.routines.id.equals('routine-specific'))).getSingle();

    await scheduler.scheduleRoutineReminders(
      RoutineReminderSchedule.fromDatabase(
        routine: row.readTable(database.routines),
        schedule: row.readTable(database.routineSchedules),
      ),
    );

    expect(notifications.scheduled, hasLength(4));
    expect(
      notifications.scheduled,
      contains(
        notificationIdForDate(
          routineId: 'routine-specific',
          type: RoutineReminderType.start,
          date: tomorrow,
        ),
      ),
    );
    expect(
      notifications.scheduledDates.values.every(
        (date) => _dateKey(date) == tomorrowKey,
      ),
      isTrue,
    );
  });

  test(
    'base weekly refresh preserves existing specificDate reminders',
    () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dayAfterTomorrow = DateTime.now().add(const Duration(days: 2));
      final tomorrowKey = _dateKey(tomorrow);
      await _insertRoutine(database, routineId: 'routine-preserve-specific');
      await _insertSchedule(
        database,
        routineId: 'routine-preserve-specific',
        specificDate: tomorrowKey,
        repeatDays: '',
      );

      await scheduler.scheduleRoutineReminders(
        RoutineReminderSchedule(
          routineId: 'routine-preserve-specific',
          title: 'Moved routine',
          routineType: 'fixedTime',
          targetSummary: '20 pages',
          startTimeMinutes: 720,
          endTimeMinutes: 780,
          repeatDays: const {},
          specificDate: tomorrowKey,
          fullDurationMinutes: 60,
          miniDurationMinutes: 10,
          isActive: true,
          reminderEnabled: true,
        ),
      );

      final specificStartId = notificationIdForDate(
        routineId: 'routine-preserve-specific',
        type: RoutineReminderType.start,
        date: tomorrow,
      );
      expect(notifications.active, contains(specificStartId));

      final cancelledBefore = notifications.cancelled.length;
      await scheduler.scheduleRoutineReminders(
        RoutineReminderSchedule(
          routineId: 'routine-preserve-specific',
          title: 'Base routine',
          routineType: 'fixedTime',
          targetSummary: '20 pages',
          startTimeMinutes: 1320,
          endTimeMinutes: 1380,
          repeatDays: {tomorrow.weekday, dayAfterTomorrow.weekday},
          fullDurationMinutes: 60,
          miniDurationMinutes: 10,
          isActive: true,
          reminderEnabled: true,
        ),
      );

      final refreshCancelledIds = notifications.cancelled.skip(cancelledBefore);
      expect(refreshCancelledIds, isNot(contains(specificStartId)));
      expect(notifications.active, contains(specificStartId));
      expect(
        notifications.scheduled.where((id) => id == specificStartId),
        hasLength(1),
      );
      expect(
        notifications.scheduledDates.values.any(
          (date) => _dateKey(date) == _dateKey(dayAfterTomorrow),
        ),
        isTrue,
      );
    },
  );

  test('past specificDate schedule does not schedule reminders', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await _insertRoutine(database, routineId: 'routine-past-specific');

    await scheduler.scheduleRoutineReminders(
      RoutineReminderSchedule(
        routineId: 'routine-past-specific',
        title: 'Past routine',
        routineType: 'fixedTime',
        targetSummary: '20 pages',
        startTimeMinutes: 720,
        endTimeMinutes: 780,
        repeatDays: const {},
        specificDate: _dateKey(yesterday),
        fullDurationMinutes: 60,
        miniDurationMinutes: 10,
        isActive: true,
        reminderEnabled: true,
      ),
    );

    final reminders = await database.select(database.reminders).get();

    expect(notifications.scheduled, isEmpty);
    expect(reminders, isEmpty);
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
          type: RoutineReminderType.preparation,
          date: today,
        ),
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

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
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

Future<void> _insertSchedule(
  AppDatabase database, {
  required String routineId,
  required String repeatDays,
  String? specificDate,
}) async {
  final now = DateTime.now();
  await database
      .into(database.routineSchedules)
      .insert(
        RoutineSchedulesCompanion.insert(
          id: 'schedule-$routineId',
          routineId: routineId,
          startTimeMinutes: 720,
          endTimeMinutes: 780,
          repeatDays: repeatDays,
          specificDate: Value(specificDate),
          timezone: 'Asia/Dhaka',
          createdAt: now,
          updatedAt: now,
        ),
      );
}

class _FakeNotificationGateway implements NotificationGateway {
  int initializeCalls = 0;
  final scheduled = <int>[];
  final scheduledDates = <int, DateTime>{};
  final cancelled = <int>[];
  final active = <int>{};
  final calls = <_NotificationCall>[];

  void clearCalls() {
    calls.clear();
    scheduled.clear();
    scheduledDates.clear();
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
    scheduledDates[id] = scheduledDate;
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
