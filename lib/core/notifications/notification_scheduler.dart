import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../enums/routine_type.dart';
import '../utils/date_time_utils.dart';
import 'notification_service.dart';
import 'notification_settings.dart';

const _rollingScheduleDays = 8;
const _rollingCancellationDays = 14;

abstract class RoutineNotificationScheduler {
  Future<void> initializeAndReschedule();

  Future<void> scheduleRoutineReminders(RoutineReminderSchedule routine);

  Future<void> cancelRoutineReminders(String routineId);

  Future<void> cancelRoutineReminderType(
    String routineId,
    RoutineReminderType type, {
    DateTime? now,
  });

  Future<void> cancelRemainingTodayReminders(String routineId, {DateTime? now});

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

  static const _fallbackReminderRules = [
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

    final rows =
        await (_database.select(_database.routines).join([
                innerJoin(
                  _database.routineSchedules,
                  _database.routineSchedules.routineId.equalsExp(
                    _database.routines.id,
                  ),
                ),
              ])
              ..where(_database.routines.isActive.equals(true))
              ..orderBy([
                OrderingTerm.asc(_database.routines.id),
                OrderingTerm.asc(_database.routineSchedules.specificDate),
              ]))
            .get();

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
    final preservedSpecificDates = routine.specificDate == null
        ? await _specificDateKeysForRoutine(routine.routineId)
        : const <String>{};
    if (routine.specificDate == null) {
      await _cancelBaseScheduleReminders(
        routine.routineId,
        preservedDateKeys: preservedSpecificDates,
      );
    } else {
      await _cancelSpecificDateReminders(
        routine.routineId,
        routine.specificDate!,
      );
    }

    if (!routine.isSchedulable || !await _remindersEnabled()) {
      if (routine.specificDate == null) {
        await _deleteReminderRows(routine.routineId);
      }
      return;
    }

    final enabled = await _notifications.initialize();
    if (!enabled) return;

    final now = DateTime.now();
    final reminderRules = await _reminderRules();

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

    for (final scheduledDay in _scheduledDatesFor(
      routine,
      excludedDateKeys: preservedSpecificDates,
    )) {
      for (final rule in reminderRules) {
        final scheduledDate = _dateTimeFor(
          date: scheduledDay,
          minutesFromMidnight:
              _baseMinutesFor(rule.type, routine) + rule.minutesOffset,
        );
        if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) continue;

        await _notifications.scheduleOneTime(
          id: notificationIdForDate(
            routineId: routine.routineId,
            type: rule.type,
            date: scheduledDay,
          ),
          title: _titleFor(rule.type, routine.title),
          body: _bodyFor(rule.type, routine),
          scheduledDate: scheduledDate,
          payload: 'routine:${routine.routineId}:${rule.type.name}',
        );
      }
    }
  }

  @override
  Future<void> cancelRoutineReminders(String routineId) async {
    for (final weekday in DateTimeUtils.weekdayShortLabels.keys) {
      for (final rule in _fallbackReminderRules) {
        // Cancels legacy repeating weekly IDs from older app versions.
        await _notifications.cancel(
          notificationIdFor(
            routineId: routineId,
            type: rule.type,
            weekday: weekday,
          ),
        );
      }
    }
    for (final date in _rollingCancellationDates()) {
      for (final rule in _fallbackReminderRules) {
        await _notifications.cancel(
          notificationIdForDate(
            routineId: routineId,
            type: rule.type,
            date: date,
          ),
        );
      }
    }
    final specificDates =
        await (_database.select(_database.routineSchedules)
              ..where((table) => table.routineId.equals(routineId))
              ..where((table) => table.specificDate.isNotNull()))
            .map((schedule) => schedule.specificDate)
            .get();
    for (final dateKey in specificDates.whereType<String>()) {
      final date = DateTime.tryParse(dateKey);
      if (date == null) continue;
      for (final rule in _fallbackReminderRules) {
        await _notifications.cancel(
          notificationIdForDate(
            routineId: routineId,
            type: rule.type,
            date: date,
          ),
        );
      }
    }
    await _deleteReminderRows(routineId);
  }

  Future<void> _cancelBaseScheduleReminders(
    String routineId, {
    required Set<String> preservedDateKeys,
  }) async {
    for (final weekday in DateTimeUtils.weekdayShortLabels.keys) {
      for (final rule in _fallbackReminderRules) {
        // Cancels legacy repeating weekly IDs from older app versions.
        await _notifications.cancel(
          notificationIdFor(
            routineId: routineId,
            type: rule.type,
            weekday: weekday,
          ),
        );
      }
    }
    for (final date in _rollingCancellationDates()) {
      if (preservedDateKeys.contains(DateTimeUtils.dateKey(date))) continue;
      for (final rule in _fallbackReminderRules) {
        await _notifications.cancel(
          notificationIdForDate(
            routineId: routineId,
            type: rule.type,
            date: date,
          ),
        );
      }
    }
    await _deleteReminderRows(routineId);
  }

  @override
  Future<void> cancelRoutineReminderType(
    String routineId,
    RoutineReminderType type, {
    DateTime? now,
  }) async {
    final date = now ?? DateTime.now();
    await _notifications.cancel(
      notificationIdForDate(routineId: routineId, type: type, date: date),
    );
    await _notifications.cancel(
      notificationIdFor(
        routineId: routineId,
        type: type,
        weekday: date.weekday,
      ),
    );
  }

  @override
  Future<void> cancelRemainingTodayReminders(
    String routineId, {
    DateTime? now,
  }) async {
    for (final type in const [
      RoutineReminderType.start,
      RoutineReminderType.late,
      RoutineReminderType.recovery,
    ]) {
      await cancelRoutineReminderType(routineId, type, now: now);
    }
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

  Future<List<RoutineReminderRule>> _reminderRules() async {
    final settings = await _settings?.reminderSettings();
    if (settings == null) return _fallbackReminderRules;

    return [
      RoutineReminderRule(
        type: RoutineReminderType.preparation,
        minutesOffset: -settings.defaultPreparationReminderMinutes,
      ),
      const RoutineReminderRule(
        type: RoutineReminderType.start,
        minutesOffset: 0,
      ),
      RoutineReminderRule(
        type: RoutineReminderType.late,
        minutesOffset: settings.defaultLateReminderMinutes,
      ),
      const RoutineReminderRule(
        type: RoutineReminderType.recovery,
        minutesOffset: -15,
      ),
    ];
  }

  Future<void> _deleteReminderRows(String routineId) {
    return (_database.delete(
      _database.reminders,
    )..where((table) => table.routineId.equals(routineId))).go();
  }

  Future<void> _cancelSpecificDateReminders(
    String routineId,
    String dateKey,
  ) async {
    final date = DateTime.tryParse(dateKey);
    if (date == null) return;
    for (final rule in _fallbackReminderRules) {
      await _notifications.cancel(
        notificationIdForDate(
          routineId: routineId,
          type: rule.type,
          date: date,
        ),
      );
    }
  }

  Future<Set<String>> _specificDateKeysForRoutine(String routineId) {
    return (_database.select(_database.routineSchedules)
          ..where((table) => table.routineId.equals(routineId))
          ..where((table) => table.specificDate.isNotNull()))
        .map((schedule) => schedule.specificDate)
        .get()
        .then((dates) => dates.whereType<String>().toSet());
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
    this.specificDate,
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
      specificDate: schedule.specificDate,
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
  final String? specificDate;
  final int fullDurationMinutes;
  final int miniDurationMinutes;
  final bool isActive;
  final bool reminderEnabled;

  bool get isSchedulable {
    final specificDate = this.specificDate;
    final hasSchedulableDate = specificDate == null
        ? repeatDays.isNotEmpty
        : !_isPastDateKey(specificDate);
    return isActive &&
        reminderEnabled &&
        routineType == RoutineType.fixedTime.name &&
        hasSchedulableDate;
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

int notificationIdForDate({
  required String routineId,
  required RoutineReminderType type,
  required DateTime date,
}) {
  return _stablePositiveHash(
    '$routineId|${type.name}|${DateTimeUtils.dateKey(date)}',
  );
}

int _stablePositiveHash(String value) {
  var hash = 0x811C9DC5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7FFFFFFF;
  }
  return hash;
}

List<DateTime> _scheduledDatesFor(
  RoutineReminderSchedule routine, {
  Set<String> excludedDateKeys = const {},
}) {
  final specificDate = routine.specificDate;
  if (specificDate != null) {
    final date = DateTime.tryParse(specificDate);
    if (date == null) return const [];
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (day.isBefore(todayOnly)) return const [];
    return [day];
  }
  return _nextScheduledDays(routine.repeatDays)
      .where((date) => !excludedDateKeys.contains(DateTimeUtils.dateKey(date)))
      .toList();
}

bool _isPastDateKey(String dateKey) {
  final date = DateTime.tryParse(dateKey);
  if (date == null) return true;
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  return day.isBefore(todayOnly);
}

List<DateTime> _nextScheduledDays(Set<int> repeatDays) {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  return [
    for (var offset = 0; offset < _rollingScheduleDays; offset++)
      if (repeatDays.contains(start.add(Duration(days: offset)).weekday))
        start.add(Duration(days: offset)),
  ];
}

List<DateTime> _rollingCancellationDates() {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  return [
    for (var offset = 0; offset < _rollingCancellationDays; offset++)
      start.add(Duration(days: offset)),
  ];
}

tz.TZDateTime _dateTimeFor({
  required DateTime date,
  required int minutesFromMidnight,
}) {
  final adjusted = DateTime(
    date.year,
    date.month,
    date.day,
  ).add(Duration(minutes: minutesFromMidnight));
  return tz.TZDateTime(
    tz.local,
    adjusted.year,
    adjusted.month,
    adjusted.day,
    adjusted.hour,
    adjusted.minute,
  );
}
