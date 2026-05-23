import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/routine_status.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../routines/data/routine_repository.dart';

class TodayRepository {
  TodayRepository(this._database, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  Future<TodayTimeline> getTimelineForDate(
    DateTime date, {
    DateTime? now,
  }) async {
    final dateKey = DateTimeUtils.dateKey(date);
    final currentTime = now ?? DateTime.now();
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final isToday = DateTimeUtils.dateKey(currentTime) == dateKey;

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

    final scheduled =
        routineRows
            .map(
              (row) => RoutineDetail(
                routine: row.readTable(_database.routines),
                category: row.readTable(_database.categories),
                schedule: row.readTable(_database.routineSchedules),
              ),
            )
            .where((detail) {
              final schedule = detail.schedule;
              if (schedule == null) {
                return false;
              }
              if (schedule.specificDate != null) {
                return schedule.specificDate == dateKey;
              }
              return RecurrenceUtils.repeatsOnWeekday(
                schedule.repeatDays,
                date.weekday,
              );
            })
            .toList()
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
        currentMinutes: currentMinutes,
        startMinutes: schedule.startTimeMinutes,
        endMinutes: schedule.endTimeMinutes,
      );

      return TodayTimelineEntry(
        detail: detail,
        log: log,
        status: status,
        dateKey: dateKey,
      );
    }).toList();

    return TodayTimeline(date: date, entries: entries);
  }

  Future<void> markCompleted(TodayTimelineEntry entry) async {
    final now = DateTime.now();
    final schedule = entry.detail.schedule!;
    final plannedDuration = schedule.endTimeMinutes - schedule.startTimeMinutes;

    await _upsertLog(
      entry: entry,
      status: RoutineStatus.completed,
      actualStartAt: now,
      actualEndAt: now,
      actualDurationMinutes: plannedDuration,
      updatedAt: now,
    );
  }

  Future<void> markSkipped(TodayTimelineEntry entry, String skipReason) async {
    await _upsertLog(
      entry: entry,
      status: RoutineStatus.skipped,
      skipReason: skipReason,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _upsertLog({
    required TodayTimelineEntry entry,
    required RoutineStatus status,
    required DateTime updatedAt,
    DateTime? actualStartAt,
    DateTime? actualEndAt,
    int? actualDurationMinutes,
    String? skipReason,
  }) async {
    final schedule = entry.detail.schedule!;
    final existingLog = entry.log;

    if (existingLog == null) {
      await _database
          .into(_database.routineLogs)
          .insert(
            RoutineLogsCompanion.insert(
              id: _uuid.v4(),
              routineId: entry.detail.routine.id,
              date: entry.dateKey,
              status: status.name,
              plannedStartTimeMinutes: schedule.startTimeMinutes,
              plannedEndTimeMinutes: schedule.endTimeMinutes,
              actualStartAt: Value(actualStartAt),
              actualEndAt: Value(actualEndAt),
              actualDurationMinutes: Value(actualDurationMinutes),
              skipReason: Value(skipReason),
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
        actualStartAt: Value(actualStartAt),
        actualEndAt: Value(actualEndAt),
        actualDurationMinutes: Value(actualDurationMinutes),
        skipReason: Value(skipReason),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  RoutineStatus _resolveStatus({
    required RoutineLog? log,
    required bool isToday,
    required int currentMinutes,
    required int startMinutes,
    required int endMinutes,
  }) {
    if (log != null) {
      return RoutineStatus.values.byName(log.status);
    }
    if (!isToday) return RoutineStatus.upcoming;
    if (currentMinutes >= startMinutes && currentMinutes <= endMinutes) {
      return RoutineStatus.active;
    }
    if (currentMinutes > endMinutes) return RoutineStatus.missed;
    return RoutineStatus.upcoming;
  }
}

class TodayTimeline {
  const TodayTimeline({required this.date, required this.entries});

  final DateTime date;
  final List<TodayTimelineEntry> entries;

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
}
