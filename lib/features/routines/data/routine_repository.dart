import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/difficulty_level.dart';
import '../../../core/enums/goal_type.dart';
import '../../../core/enums/priority_level.dart';
import '../../../core/enums/routine_type.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/utils/date_time_utils.dart';

class RoutineRepository {
  RoutineRepository(
    this._database, {
    Uuid? uuid,
    RoutineNotificationScheduler? scheduler,
  }) : _uuid = uuid ?? const Uuid(),
       _scheduler = scheduler;

  final AppDatabase _database;
  final Uuid _uuid;
  final RoutineNotificationScheduler? _scheduler;

  Stream<List<Category>> watchCategories() {
    final query = _database.select(_database.categories)
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    return query.watch();
  }

  Stream<List<RoutineDetail>> watchRoutineDetails() {
    final query =
        _database.select(_database.routines).join([
          innerJoin(
            _database.categories,
            _database.categories.id.equalsExp(_database.routines.categoryId),
          ),
          leftOuterJoin(
            _database.routineSchedules,
            _database.routineSchedules.routineId.equalsExp(
              _database.routines.id,
            ),
          ),
        ])..orderBy([
          OrderingTerm.asc(_database.routines.isActive),
          OrderingTerm.asc(_database.routines.title),
        ]);

    return query.watch().map(_mapRoutineDetails);
  }

  Stream<RoutineDetail?> watchRoutineDetail(String routineId) {
    final query =
        _database.select(_database.routines).join([
            innerJoin(
              _database.categories,
              _database.categories.id.equalsExp(_database.routines.categoryId),
            ),
            leftOuterJoin(
              _database.routineSchedules,
              _database.routineSchedules.routineId.equalsExp(
                _database.routines.id,
              ),
            ),
          ])
          ..where(_database.routines.id.equals(routineId))
          ..limit(1);

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      return _mapRoutineDetail(rows.first);
    });
  }

  Future<RoutineDetail?> getRoutineDetail(String routineId) async {
    final query =
        _database.select(_database.routines).join([
            innerJoin(
              _database.categories,
              _database.categories.id.equalsExp(_database.routines.categoryId),
            ),
            leftOuterJoin(
              _database.routineSchedules,
              _database.routineSchedules.routineId.equalsExp(
                _database.routines.id,
              ),
            ),
          ])
          ..where(_database.routines.id.equals(routineId))
          ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapRoutineDetail(row);
  }

  Future<String> createRoutine(RoutineFormData data) async {
    data.validate();

    final now = DateTime.now();
    final routineId = _uuid.v4();
    final scheduleId = _scheduleIdFor(routineId);

    await _database.transaction(() async {
      await _database
          .into(_database.routines)
          .insert(
            RoutinesCompanion.insert(
              id: routineId,
              title: data.title.trim(),
              description: Value(_nullableText(data.description)),
              categoryId: data.categoryId,
              routineType: data.routineType.name,
              goalType: data.goalType.name,
              targetValue: Value(data.targetValue),
              targetUnit: Value(_nullableText(data.targetUnit)),
              priority: data.priority.name,
              difficulty: data.difficulty.name,
              fullDurationMinutes: data.fullDurationMinutes,
              mediumDurationMinutes: data.mediumDurationMinutes,
              miniDurationMinutes: data.miniDurationMinutes,
              isActive: const Value(true),
              reminderEnabled: Value(data.reminderEnabled),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _database
          .into(_database.routineSchedules)
          .insert(
            RoutineSchedulesCompanion.insert(
              id: scheduleId,
              routineId: routineId,
              startTimeMinutes: data.startTimeMinutes,
              endTimeMinutes: data.endTimeMinutes,
              repeatDays: DateTimeUtils.encodeRepeatDays(data.repeatDays),
              timezone: data.timezone,
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    await _scheduler?.scheduleRoutineReminders(
      RoutineReminderSchedule(
        routineId: routineId,
        title: data.title.trim(),
        routineType: data.routineType.name,
        targetSummary: _targetSummary(data),
        startTimeMinutes: data.startTimeMinutes,
        endTimeMinutes: data.endTimeMinutes,
        repeatDays: data.repeatDays,
        fullDurationMinutes: data.fullDurationMinutes,
        miniDurationMinutes: data.miniDurationMinutes,
        isActive: true,
        reminderEnabled: data.reminderEnabled,
      ),
    );

    return routineId;
  }

  Future<void> updateRoutine(String routineId, RoutineFormData data) async {
    data.validate();

    final now = DateTime.now();
    final existingRoutine =
        await (_database.select(_database.routines)
              ..where((table) => table.id.equals(routineId))
              ..limit(1))
            .getSingleOrNull();
    final isActive = existingRoutine?.isActive ?? true;

    await _database.transaction(() async {
      await (_database.update(
        _database.routines,
      )..where((table) => table.id.equals(routineId))).write(
        RoutinesCompanion(
          title: Value(data.title.trim()),
          description: Value(_nullableText(data.description)),
          categoryId: Value(data.categoryId),
          routineType: Value(data.routineType.name),
          goalType: Value(data.goalType.name),
          targetValue: Value(data.targetValue),
          targetUnit: Value(_nullableText(data.targetUnit)),
          priority: Value(data.priority.name),
          difficulty: Value(data.difficulty.name),
          fullDurationMinutes: Value(data.fullDurationMinutes),
          mediumDurationMinutes: Value(data.mediumDurationMinutes),
          miniDurationMinutes: Value(data.miniDurationMinutes),
          reminderEnabled: Value(data.reminderEnabled),
          updatedAt: Value(now),
        ),
      );

      await _database
          .into(_database.routineSchedules)
          .insertOnConflictUpdate(
            RoutineSchedulesCompanion.insert(
              id: _scheduleIdFor(routineId),
              routineId: routineId,
              startTimeMinutes: data.startTimeMinutes,
              endTimeMinutes: data.endTimeMinutes,
              repeatDays: DateTimeUtils.encodeRepeatDays(data.repeatDays),
              timezone: data.timezone,
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    await _scheduler?.scheduleRoutineReminders(
      RoutineReminderSchedule(
        routineId: routineId,
        title: data.title.trim(),
        routineType: data.routineType.name,
        targetSummary: _targetSummary(data),
        startTimeMinutes: data.startTimeMinutes,
        endTimeMinutes: data.endTimeMinutes,
        repeatDays: data.repeatDays,
        fullDurationMinutes: data.fullDurationMinutes,
        miniDurationMinutes: data.miniDurationMinutes,
        isActive: isActive,
        reminderEnabled: data.reminderEnabled,
      ),
    );
  }

  Future<void> setRoutineActive(String routineId, bool isActive) async {
    await (_database.update(
      _database.routines,
    )..where((table) => table.id.equals(routineId))).write(
      RoutinesCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (!isActive) {
      await _scheduler?.cancelRoutineReminders(routineId);
      return;
    }

    final detail = await getRoutineDetail(routineId);
    final schedule = detail?.schedule;
    if (detail != null && schedule != null) {
      await _scheduler?.scheduleRoutineReminders(
        RoutineReminderSchedule.fromDatabase(
          routine: detail.routine,
          schedule: schedule,
        ),
      );
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    await _scheduler?.cancelRoutineReminders(routineId);
    await _database.transaction(() async {
      await (_database.delete(
        _database.focusSessions,
      )..where((table) => table.routineId.equals(routineId))).go();
      await (_database.delete(
        _database.routineLogs,
      )..where((table) => table.routineId.equals(routineId))).go();
      await (_database.delete(
        _database.reminders,
      )..where((table) => table.routineId.equals(routineId))).go();
      await (_database.delete(
        _database.routineSchedules,
      )..where((table) => table.routineId.equals(routineId))).go();
      await (_database.delete(
        _database.routines,
      )..where((table) => table.id.equals(routineId))).go();
    });
  }

  List<RoutineDetail> _mapRoutineDetails(List<TypedResult> rows) {
    return rows.map(_mapRoutineDetail).toList();
  }

  RoutineDetail _mapRoutineDetail(TypedResult row) {
    return RoutineDetail(
      routine: row.readTable(_database.routines),
      category: row.readTable(_database.categories),
      schedule: row.readTableOrNull(_database.routineSchedules),
    );
  }

  String _scheduleIdFor(String routineId) => 'schedule-$routineId';

  String? _nullableText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _targetSummary(RoutineFormData data) {
    final targetValue = data.targetValue;
    final targetUnit = _nullableText(data.targetUnit);
    if (targetValue == null || targetUnit == null) return data.goalType.label;
    final formattedValue = targetValue == targetValue.roundToDouble()
        ? targetValue.toInt().toString()
        : targetValue.toStringAsFixed(1);
    return '$formattedValue $targetUnit';
  }
}

class RoutineDetail {
  const RoutineDetail({
    required this.routine,
    required this.category,
    required this.schedule,
  });

  final Routine routine;
  final Category category;
  final RoutineSchedule? schedule;

  String get scheduleLabel {
    final schedule = this.schedule;
    if (schedule == null) return 'No schedule';
    return DateTimeUtils.formatTimeRange(
      schedule.startTimeMinutes,
      schedule.endTimeMinutes,
    );
  }

  String get repeatLabel {
    final schedule = this.schedule;
    if (schedule == null) return 'No repeat days';
    return DateTimeUtils.formatRepeatDays(schedule.repeatDays);
  }

  String get goalLabel {
    if (routine.targetValue == null || routine.targetUnit == null) {
      return GoalType.values.byName(routine.goalType).label;
    }
    final value = routine.targetValue!;
    final formattedValue = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$formattedValue ${routine.targetUnit}';
  }
}

class RoutineFormData {
  const RoutineFormData({
    required this.title,
    required this.categoryId,
    required this.routineType,
    required this.goalType,
    required this.priority,
    required this.difficulty,
    required this.startTimeMinutes,
    required this.endTimeMinutes,
    required this.repeatDays,
    required this.fullDurationMinutes,
    required this.mediumDurationMinutes,
    required this.miniDurationMinutes,
    required this.reminderEnabled,
    required this.timezone,
    this.description,
    this.targetValue,
    this.targetUnit,
  });

  final String title;
  final String? description;
  final String categoryId;
  final RoutineType routineType;
  final GoalType goalType;
  final double? targetValue;
  final String? targetUnit;
  final PriorityLevel priority;
  final DifficultyLevel difficulty;
  final int startTimeMinutes;
  final int endTimeMinutes;
  final Set<int> repeatDays;
  final int fullDurationMinutes;
  final int mediumDurationMinutes;
  final int miniDurationMinutes;
  final bool reminderEnabled;
  final String timezone;

  void validate() {
    if (title.trim().isEmpty) {
      throw const RoutineFormValidationException('Title is required.');
    }
    if (categoryId.trim().isEmpty) {
      throw const RoutineFormValidationException('Category is required.');
    }
    if (repeatDays.isEmpty) {
      throw const RoutineFormValidationException(
        'Select at least one repeat day.',
      );
    }
    if (endTimeMinutes <= startTimeMinutes) {
      throw const RoutineFormValidationException(
        'End time must be after start time. Overnight routines are not supported in the MVP.',
      );
    }
    if (goalType != GoalType.simpleCheck &&
        (targetValue == null || targetValue! <= 0)) {
      throw const RoutineFormValidationException(
        'Target value is required for this goal type.',
      );
    }
    if (targetValue != null && targetValue! <= 0) {
      throw const RoutineFormValidationException(
        'Target value must be positive.',
      );
    }
    if (fullDurationMinutes <= 0 ||
        mediumDurationMinutes <= 0 ||
        miniDurationMinutes <= 0) {
      throw const RoutineFormValidationException(
        'Full, medium, and mini versions must be positive.',
      );
    }
    if (miniDurationMinutes > mediumDurationMinutes ||
        mediumDurationMinutes > fullDurationMinutes) {
      throw const RoutineFormValidationException(
        'Mini must be <= medium, and medium must be <= full.',
      );
    }
  }

  static RoutineFormData fromDetail(RoutineDetail detail) {
    final routine = detail.routine;
    final schedule = detail.schedule;

    return RoutineFormData(
      title: routine.title,
      description: routine.description,
      categoryId: routine.categoryId,
      routineType: RoutineType.values.byName(routine.routineType),
      goalType: GoalType.values.byName(routine.goalType),
      targetValue: routine.targetValue,
      targetUnit: routine.targetUnit,
      priority: PriorityLevel.values.byName(routine.priority),
      difficulty: DifficultyLevel.values.byName(routine.difficulty),
      startTimeMinutes: schedule?.startTimeMinutes ?? 540,
      endTimeMinutes: schedule?.endTimeMinutes ?? 600,
      repeatDays: DateTimeUtils.decodeRepeatDays(schedule?.repeatDays ?? ''),
      fullDurationMinutes: routine.fullDurationMinutes,
      mediumDurationMinutes: routine.mediumDurationMinutes,
      miniDurationMinutes: routine.miniDurationMinutes,
      reminderEnabled: routine.reminderEnabled,
      timezone: schedule?.timezone ?? DateTime.now().timeZoneName,
    );
  }
}

class RoutineFormValidationException implements Exception {
  const RoutineFormValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
