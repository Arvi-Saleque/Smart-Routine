import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/routine_status.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../routines/data/routine_repository.dart';
import 'daily_score_repository.dart';

class TodayRepository {
  TodayRepository(
    this._database, {
    Uuid? uuid,
    DailyScoreRepository? scoreRepository,
    RoutineNotificationScheduler? notificationScheduler,
  }) : _uuid = uuid ?? const Uuid(),
       _scoreRepository = scoreRepository ?? DailyScoreRepository(_database),
       _notificationScheduler = notificationScheduler;

  final AppDatabase _database;
  final Uuid _uuid;
  final DailyScoreRepository _scoreRepository;
  final RoutineNotificationScheduler? _notificationScheduler;

  Future<TodayTimeline> getTimelineForDate(
    DateTime date, {
    DateTime? now,
    bool saveScore = true,
  }) async {
    final dateKey = DateTimeUtils.dateKey(date);
    final currentTime = now ?? DateTime.now();
    final currentDateKey = DateTimeUtils.dateKey(currentTime);
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final isToday = currentDateKey == dateKey;
    final isPast = dateKey.compareTo(currentDateKey) < 0;

    final routineRows = await (_database.select(_database.routines).join([
      innerJoin(
        _database.categories,
        _database.categories.id.equalsExp(_database.routines.categoryId),
      ),
      innerJoin(
        _database.routineSchedules,
        _database.routineSchedules.routineId.equalsExp(_database.routines.id),
      ),
    ])..where(_database.routines.isActive.equals(true))).get();

    final scheduledByRoutineId = <String, RoutineDetail>{};
    for (final row in routineRows) {
      final detail = RoutineDetail(
        routine: row.readTable(_database.routines),
        category: row.readTable(_database.categories),
        schedule: row.readTable(_database.routineSchedules),
      );
      final schedule = detail.schedule!;
      final isScheduled = schedule.specificDate == null
          ? RecurrenceUtils.repeatsOnWeekday(schedule.repeatDays, date.weekday)
          : schedule.specificDate == dateKey;
      if (!isScheduled) continue;

      final existing = scheduledByRoutineId[detail.routine.id];
      if (existing == null || schedule.specificDate != null) {
        scheduledByRoutineId[detail.routine.id] = detail;
      }
    }

    final scheduled = scheduledByRoutineId.values.toList()
      ..sort(
        (left, right) => left.schedule!.startTimeMinutes.compareTo(
          right.schedule!.startTimeMinutes,
        ),
      );

    final logs = await (_database.select(
      _database.routineLogs,
    )..where((table) => table.date.equals(dateKey))).get();
    final logsByRoutineId = {for (final log in logs) log.routineId: log};

    final entries = scheduled.map((detail) {
      final schedule = detail.schedule!;
      final log = logsByRoutineId[detail.routine.id];
      final status = _resolveStatus(
        log: log,
        isToday: isToday,
        isPast: isPast,
        currentMinutes: currentMinutes,
        startMinutes: log?.plannedStartTimeMinutes ?? schedule.startTimeMinutes,
        endMinutes: log?.plannedEndTimeMinutes ?? schedule.endTimeMinutes,
      );

      return TodayTimelineEntry(
        detail: detail,
        log: log,
        status: status,
        dateKey: dateKey,
      );
    }).toList();

    final isFuture = dateKey.compareTo(currentDateKey) > 0;
    final dailyScore = isFuture
        ? null
        : saveScore
        ? await _scoreRepository.calculateAndSaveForDate(date, now: currentTime)
        : await _scoreRepository.getScoreForDateKey(dateKey);

    return TodayTimeline(date: date, entries: entries, dailyScore: dailyScore);
  }

  Future<void> markCompleted(TodayTimelineEntry entry) async {
    final now = DateTime.now();
    final schedule = entry.detail.schedule!;
    final plannedDuration = schedule.endTimeMinutes - schedule.startTimeMinutes;

    await _upsertLog(
      entry: entry,
      status: RoutineStatus.completed,
      // Manual completion has no observed start event. Keep actualStartAt
      // null and store the planned duration instead of inventing an
      // impossible start/end pair at the same instant.
      actualEndAt: now,
      actualDurationMinutes: plannedDuration,
      updatedAt: now,
    );
    await _cancelActionReminders(entry);
  }

  Future<void> markSkipped(TodayTimelineEntry entry, String skipReason) async {
    await _upsertLog(
      entry: entry,
      status: RoutineStatus.skipped,
      skipReason: skipReason,
      updatedAt: DateTime.now(),
    );
    await _cancelActionReminders(entry);
  }

  Future<void> rescheduleLaterToday(TodayTimelineEntry entry) async {
    final now = DateTime.now();
    final schedule = entry.detail.schedule!;
    final plannedDuration = schedule.endTimeMinutes - schedule.startTimeMinutes;
    final currentMinutes = now.hour * 60 + now.minute;
    final earliestRecoveryStart = schedule.endTimeMinutes + 1;
    final candidateStart = currentMinutes + 30;
    final nextStart = _clampToToday(
      candidateStart < earliestRecoveryStart
          ? earliestRecoveryStart
          : candidateStart,
      plannedDuration: plannedDuration,
    );

    await _upsertLog(
      entry: entry,
      status: RoutineStatus.rescheduled,
      plannedStartTimeMinutes: nextStart,
      plannedEndTimeMinutes: nextStart + plannedDuration,
      note:
          'Rescheduled for ${DateTimeUtils.formatTimeRange(nextStart, nextStart + plannedDuration)}.',
      updatedAt: now,
    );

    await _database
        .into(_database.routineSchedules)
        .insertOnConflictUpdate(
          RoutineSchedulesCompanion.insert(
            id: _specificDateScheduleId(entry.detail.routine.id, entry.dateKey),
            routineId: entry.detail.routine.id,
            startTimeMinutes: nextStart,
            endTimeMinutes: nextStart + plannedDuration,
            repeatDays: '',
            specificDate: Value(entry.dateKey),
            timezone: schedule.timezone,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await _notificationScheduler?.scheduleRoutineReminders(
      RoutineReminderSchedule(
        routineId: entry.detail.routine.id,
        title: entry.detail.routine.title,
        routineType: entry.detail.routine.routineType,
        targetSummary: entry.detail.goalLabel,
        startTimeMinutes: nextStart,
        endTimeMinutes: nextStart + plannedDuration,
        repeatDays: const {},
        specificDate: entry.dateKey,
        fullDurationMinutes: entry.detail.routine.fullDurationMinutes,
        miniDurationMinutes: entry.detail.routine.miniDurationMinutes,
        isActive: entry.detail.routine.isActive,
        reminderEnabled: entry.detail.routine.reminderEnabled,
      ),
    );
  }

  Future<void> moveToTomorrow(TodayTimelineEntry entry) async {
    final now = DateTime.now();
    final schedule = entry.detail.schedule!;
    final entryDate = DateTime.parse(entry.dateKey);
    final tomorrow = DateTimeUtils.dateKey(
      entryDate.add(const Duration(days: 1)),
    );

    await _database.transaction(() async {
      await _database
          .into(_database.routineSchedules)
          .insertOnConflictUpdate(
            RoutineSchedulesCompanion.insert(
              id: _specificDateScheduleId(entry.detail.routine.id, tomorrow),
              routineId: entry.detail.routine.id,
              startTimeMinutes: schedule.startTimeMinutes,
              endTimeMinutes: schedule.endTimeMinutes,
              repeatDays: '',
              specificDate: Value(tomorrow),
              timezone: schedule.timezone,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _upsertLog(
        entry: entry,
        status: RoutineStatus.moved,
        note: 'Moved to $tomorrow',
        updatedAt: now,
      );
    });

    await _notificationScheduler?.scheduleRoutineReminders(
      RoutineReminderSchedule(
        routineId: entry.detail.routine.id,
        title: entry.detail.routine.title,
        routineType: entry.detail.routine.routineType,
        targetSummary: entry.detail.goalLabel,
        startTimeMinutes: schedule.startTimeMinutes,
        endTimeMinutes: schedule.endTimeMinutes,
        repeatDays: const {},
        specificDate: tomorrow,
        fullDurationMinutes: entry.detail.routine.fullDurationMinutes,
        miniDurationMinutes: entry.detail.routine.miniDurationMinutes,
        isActive: entry.detail.routine.isActive,
        reminderEnabled: entry.detail.routine.reminderEnabled,
      ),
    );
  }

  Future<void> _cancelActionReminders(TodayTimelineEntry entry) async {
    await _notificationScheduler?.cancelRemainingTodayReminders(
      entry.detail.routine.id,
      now: DateTime.parse(entry.dateKey),
    );
  }

  Future<void> _upsertLog({
    required TodayTimelineEntry entry,
    required RoutineStatus status,
    required DateTime updatedAt,
    int? plannedStartTimeMinutes,
    int? plannedEndTimeMinutes,
    DateTime? actualStartAt,
    DateTime? actualEndAt,
    int? actualDurationMinutes,
    String? skipReason,
    String? note,
  }) async {
    final schedule = entry.detail.schedule!;
    final existingLog =
        entry.log ??
        await (_database.select(_database.routineLogs)
              ..where(
                (table) =>
                    table.routineId.equals(entry.detail.routine.id) &
                    table.date.equals(entry.dateKey),
              )
              ..limit(1))
            .getSingleOrNull();
    final plannedStart =
        plannedStartTimeMinutes ??
        existingLog?.plannedStartTimeMinutes ??
        schedule.startTimeMinutes;
    final plannedEnd =
        plannedEndTimeMinutes ??
        existingLog?.plannedEndTimeMinutes ??
        schedule.endTimeMinutes;

    if (existingLog == null) {
      await _database
          .into(_database.routineLogs)
          .insert(
            RoutineLogsCompanion.insert(
              id: _uuid.v4(),
              routineId: entry.detail.routine.id,
              date: entry.dateKey,
              status: status.name,
              plannedStartTimeMinutes: plannedStart,
              plannedEndTimeMinutes: plannedEnd,
              actualStartAt: Value(actualStartAt),
              actualEndAt: Value(actualEndAt),
              actualDurationMinutes: Value(actualDurationMinutes),
              skipReason: Value(skipReason),
              note: Value(note),
              createdAt: updatedAt,
              updatedAt: updatedAt,
            ),
          );
      return;
    }

    await (_database.update(
      _database.routineLogs,
    )..where((table) => table.id.equals(existingLog.id))).write(
      RoutineLogsCompanion(
        status: Value(status.name),
        plannedStartTimeMinutes: Value(plannedStart),
        plannedEndTimeMinutes: Value(plannedEnd),
        actualStartAt: Value(actualStartAt),
        actualEndAt: Value(actualEndAt),
        actualDurationMinutes: Value(actualDurationMinutes),
        skipReason: Value(skipReason),
        note: Value(note),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  int _clampToToday(int startMinutes, {required int plannedDuration}) {
    const lastMinute = (24 * 60) - 1;
    final latestStart = lastMinute - plannedDuration;
    if (latestStart <= 0) return 0;
    return startMinutes.clamp(0, latestStart);
  }

  RoutineStatus _resolveStatus({
    required RoutineLog? log,
    required bool isToday,
    required bool isPast,
    required int currentMinutes,
    required int startMinutes,
    required int endMinutes,
  }) {
    if (log != null) {
      final status = RoutineStatus.values.byName(log.status);
      if (status == RoutineStatus.rescheduled) {
        if (isToday &&
            currentMinutes >= startMinutes &&
            currentMinutes <= endMinutes) {
          return RoutineStatus.active;
        }
        if (isPast || (isToday && currentMinutes > endMinutes)) {
          return RoutineStatus.missed;
        }
      }
      return status;
    }
    if (isPast) return RoutineStatus.missed;
    if (!isToday) return RoutineStatus.upcoming;
    if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
      return RoutineStatus.active;
    }
    if (currentMinutes > endMinutes) return RoutineStatus.missed;
    return RoutineStatus.upcoming;
  }

  String _specificDateScheduleId(String routineId, String dateKey) {
    return 'reschedule-$routineId-$dateKey';
  }
}

class TodayTimeline {
  const TodayTimeline({
    required this.date,
    required this.entries,
    required this.dailyScore,
  });

  final DateTime date;
  final List<TodayTimelineEntry> entries;
  final DailyScore? dailyScore;

  TodayTimelineEntry? get activeEntry {
    for (final entry in entries) {
      if (entry.status == RoutineStatus.active ||
          entry.status == RoutineStatus.started) {
        return entry;
      }
    }
    return null;
  }

  TodayTimelineEntry? get nextEntry {
    for (final entry in entries) {
      if (entry.status == RoutineStatus.upcoming) return entry;
    }
    return null;
  }

  int get completedCount {
    return entries.where((entry) {
      return entry.status == RoutineStatus.completed ||
          entry.status == RoutineStatus.recovered;
    }).length;
  }

  int get skippedCount {
    return entries
        .where((entry) => entry.status == RoutineStatus.skipped)
        .length;
  }

  int get missedCount {
    return entries
        .where((entry) => entry.status == RoutineStatus.missed)
        .length;
  }

  int? get progressScore {
    if (entries.isEmpty) return null;
    return ((completedCount / entries.length) * 100).round();
  }

  String get scoreMessage {
    final score = dailyScore;
    if (entries.isEmpty) {
      return 'Create routines to start tracking today.';
    }
    if (score == null) return 'No saved score for this date yet.';
    return 'Completion ${score.completionScore}/40, on-time ${score.onTimeScore}/20, '
        'focus ${score.focusScore}/20, recovery ${score.recoveryScore}/10, '
        'balance ${score.balanceScore}/10.';
  }

  String get progressMessage {
    if (entries.isEmpty) {
      return 'The timeline is ready for your first routine block.';
    }
    return '$completedCount/${entries.length} completed, '
        '$skippedCount skipped, $missedCount missed.';
  }
}

class TodayTimelineEntry {
  const TodayTimelineEntry({
    required this.detail,
    required this.log,
    required this.status,
    required this.dateKey,
  });

  final RoutineDetail detail;
  final RoutineLog? log;
  final RoutineStatus status;
  final String dateKey;

  String get timeRangeLabel {
    final log = this.log;
    if (log != null &&
        (status == RoutineStatus.rescheduled ||
            log.status == RoutineStatus.rescheduled.name ||
            status == RoutineStatus.moved ||
            log.status == RoutineStatus.moved.name ||
            status == RoutineStatus.recovered)) {
      return DateTimeUtils.formatTimeRange(
        log.plannedStartTimeMinutes,
        log.plannedEndTimeMinutes,
      );
    }
    return detail.scheduleLabel;
  }

  String? get recoveryNote {
    final note = log?.note?.trim();
    if (note == null || note.isEmpty) return null;
    return note;
  }
}
