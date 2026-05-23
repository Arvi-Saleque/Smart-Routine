import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../enums/routine_type.dart';
import '../utils/date_time_utils.dart';
import 'notification_service.dart';
import 'notification_settings.dart';

abstract class RoutineNotificationScheduler {
  Future<void> initializeAndReschedule();

  Future<void> scheduleRoutineReminders(RoutineReminderSchedule routine);

  Future<void> cancelRoutineReminders(String routineId);

  Future<void> cancelAllRoutineReminders();
}

class LocalRoutineNotificationScheduler
    implements RoutineNotificationScheduler {
  LocalRoutineNotificationScheduler({
    required AppDatabase database,
    required NotificationGateway notifications,
    NotificationSettingsStore? settings,
  }) : _database = database,
       _notifications = notifications,
       _settings = settings;

  final AppDatabase _database;
  final NotificationGateway _notifications;
  final NotificationSettingsStore? _settings;

  static const reminderRules = [
    RoutineReminderRule(
      type: RoutineReminderType.preparation,
      minutesOffset: -10,
    ),
    RoutineReminderRule(type: RoutineReminderType.start, minutesOffset: 0),
    RoutineReminderRule(type: RoutineReminderType.late, minutesOffset: 10),
    RoutineReminderRule(type: RoutineReminderType.recovery, minutesOffset: -15),
  ];

  @override
  Future<void> initializeAndReschedule() async {
    if (!await _remindersEnabled()) {
      await cancelAllRoutineReminders();
      return;
    }

    final enabled = await _notifications.initialize();
    if (!enabled) return;

    final rows = await (_database.select(_database.routines).join([
      innerJoin(
        _database.routineSchedules,
        _database.routineSchedules.routineId.equalsExp(_database.routines.id),
      ),
    ])..where(_database.routines.isActive.equals(true))).get();

    for (final row in rows) {
      await scheduleRoutineReminders(
        RoutineReminderSchedule.fromDatabase(
          routine: row.readTable(_database.routines),
          schedule: row.readTable(_database.routineSchedules),
        ),
      );
    }
  }

  @override
  Future<void> scheduleRoutineReminders(RoutineReminderSchedule routine) async {
    await cancelRoutineReminders(routine.routineId);

    if (!routine.isSchedulable || !await _remindersEnabled()) {
      await _deleteReminderRows(routine.routineId);
      return;
    }

    final enabled = await _notifications.initialize();
    if (!enabled) return;

    final now = DateTime.now();
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _database.reminders,
        reminderRules
            .map(
              (rule) => RemindersCompanion.insert(
                id: _reminderRowId(routine.routineId, rule.type),
                routineId: routine.routineId,
                reminderType: rule.type.name,
                minutesOffset: rule.minutesOffset,
                enabled: const Value(true),
                createdAt: now,
                updatedAt: now,
              ),
            )
            .toList(),
      );
    });

    for (final weekday in routine.repeatDays) {
      for (final rule in reminderRules) {
        await _notifications.scheduleWeekly(
          id: notificationIdFor(
            routineId: routine.routineId,
            type: rule.type,
            weekday: weekday,
          ),
          title: _titleFor(rule.type, routine.title),
          body: _bodyFor(rule.type, routine),
          scheduledDate: _nextWeeklyDateTime(
            weekday: weekday,
            minutesFromMidnight:
                _baseMinutesFor(rule.type, routine) + rule.minutesOffset,
          ),
          payload: 'routine:${routine.routineId}:${rule.type.name}',
        );
      }
    }
  }

  @override
  Future<void> cancelRoutineReminders(String routineId) async {
    for (final weekday in DateTimeUtils.weekdayShortLabels.keys) {
      for (final rule in reminderRules) {
        await _notifications.cancel(
          notificationIdFor(
            routineId: routineId,
            type: rule.type,
            weekday: weekday,
          ),
        );
      }
    }
    await _deleteReminderRows(routineId);
  }

  @override
  Future<void> cancelAllRoutineReminders() async {
    final routineIds = await _database
        .select(_database.routines)
        .map((routine) => routine.id)
        .get();

    for (final routineId in routineIds) {
      await cancelRoutineReminders(routineId);
    }
  }

  Future<bool> _remindersEnabled() {
    return _settings?.remindersEnabled() ?? Future.value(true);
  }

  Future<void> _deleteReminderRows(String routineId) {
    return (_database.delete(
      _database.reminders,
    )..where((table) => table.routineId.equals(routineId))).go();
  }

  int _baseMinutesFor(
    RoutineReminderType type,
    RoutineReminderSchedule routine,
  ) {
    if (type == RoutineReminderType.recovery) return routine.endTimeMinutes;
    return routine.startTimeMinutes;
  }

  String _titleFor(RoutineReminderType type, String routineTitle) {
    return switch (type) {
      RoutineReminderType.preparation => '$routineTitle starts soon',
      RoutineReminderType.start => 'Start $routineTitle now',
      RoutineReminderType.late => 'Still doing $routineTitle?',
      RoutineReminderType.recovery => 'Recover $routineTitle',
    };
  }

  String _bodyFor(RoutineReminderType type, RoutineReminderSchedule routine) {
    return switch (type) {
      RoutineReminderType.preparation =>
        'Prepare for your ${routine.fullDurationMinutes}-minute routine.',
      RoutineReminderType.start =>
        'Goal: ${routine.targetSummary}. Tap to open RoutineOS.',
      RoutineReminderType.late =>
        'You missed the start. Try beginning now or shorten the session.',
      RoutineReminderType.recovery =>
        'You can still do the ${routine.miniDurationMinutes}-minute mini version.',
    };
  }
}

class RoutineReminderSchedule {
  const RoutineReminderSchedule({
    required this.routineId,
    required this.title,
    required this.routineType,
    required this.targetSummary,
    required this.startTimeMinutes,
    required this.endTimeMinutes,
    required this.repeatDays,
    required this.fullDurationMinutes,
    required this.miniDurationMinutes,
    required this.isActive,
    required this.reminderEnabled,
  });

  factory RoutineReminderSchedule.fromDatabase({
    required Routine routine,
    required RoutineSchedule schedule,
  }) {
    final targetValue = routine.targetValue;
    final targetUnit = routine.targetUnit;
    final targetSummary = targetValue == null || targetUnit == null
        ? routine.goalType
        : '${targetValue.toStringAsFixed(targetValue.roundToDouble() == targetValue ? 0 : 1)} $targetUnit';

    return RoutineReminderSchedule(
      routineId: routine.id,
      title: routine.title,
      routineType: routine.routineType,
      targetSummary: targetSummary,
      startTimeMinutes: schedule.startTimeMinutes,
      endTimeMinutes: schedule.endTimeMinutes,
      repeatDays: DateTimeUtils.decodeRepeatDays(schedule.repeatDays),
      fullDurationMinutes: routine.fullDurationMinutes,
      miniDurationMinutes: routine.miniDurationMinutes,
      isActive: routine.isActive,
      reminderEnabled: routine.reminderEnabled,
    );
  }

  final String routineId;
  final String title;
  final String routineType;
  final String targetSummary;
  final int startTimeMinutes;
  final int endTimeMinutes;
  final Set<int> repeatDays;
  final int fullDurationMinutes;
  final int miniDurationMinutes;
  final bool isActive;
  final bool reminderEnabled;

  bool get isSchedulable {
    return isActive &&
        reminderEnabled &&
        routineType == RoutineType.fixedTime.name &&
        repeatDays.isNotEmpty;
  }
}

class RoutineReminderRule {
  const RoutineReminderRule({required this.type, required this.minutesOffset});

  final RoutineReminderType type;
  final int minutesOffset;
}

enum RoutineReminderType { preparation, start, late, recovery }

String _reminderRowId(String routineId, RoutineReminderType type) {
  return '$routineId-${type.name}';
}

int notificationIdFor({
  required String routineId,
  required RoutineReminderType type,
  required int weekday,
}) {
  return _stablePositiveHash('$routineId|${type.name}|$weekday');
}

int _stablePositiveHash(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

tz.TZDateTime _nextWeeklyDateTime({
  required int weekday,
  required int minutesFromMidnight,
}) {
  final adjusted = _adjustWeekdayAndMinutes(
    weekday: weekday,
    minutesFromMidnight: minutesFromMidnight,
  );
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    adjusted.minutesFromMidnight ~/ 60,
    adjusted.minutesFromMidnight % 60,
  );

  while (scheduledDate.weekday != adjusted.weekday ||
      scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  return scheduledDate;
}

({int weekday, int minutesFromMidnight}) _adjustWeekdayAndMinutes({
  required int weekday,
  required int minutesFromMidnight,
}) {
  var adjustedWeekday = weekday;
  var adjustedMinutes = minutesFromMidnight;

  while (adjustedMinutes < 0) {
    adjustedMinutes += _minutesPerDay;
    adjustedWeekday = adjustedWeekday == 1 ? 7 : adjustedWeekday - 1;
  }
  while (adjustedMinutes >= _minutesPerDay) {
    adjustedMinutes -= _minutesPerDay;
    adjustedWeekday = adjustedWeekday == 7 ? 1 : adjustedWeekday + 1;
  }

  return (weekday: adjustedWeekday, minutesFromMidnight: adjustedMinutes);
}

const _minutesPerDay = 24 * 60;
