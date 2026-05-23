import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/routine_status.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../../core/utils/score_calculator.dart';

class DailyScoreRepository {
  DailyScoreRepository(
    this._database, {
    ScoreCalculator calculator = const ScoreCalculator(),
  }) : _calculator = calculator;

  final AppDatabase _database;
  final ScoreCalculator _calculator;

  Future<DailyScore> calculateAndSaveForDate(
    DateTime date, {
    DateTime? now,
  }) async {
    final dateKey = DateTimeUtils.dateKey(date);
    final plannedRows = await _plannedRoutineRows(date, dateKey);
    final logs = await (_database.select(
      _database.routineLogs,
    )..where((table) => table.date.equals(dateKey))).get();
    final logsByRoutineId = {for (final log in logs) log.routineId: log};
    final focusSessions = await _focusSessionsForDate(dateKey);

    final plannedRoutineCount = plannedRows.length;
    final plannedCategoryIds = <String>{};
    final completedCategoryIds = <String>{};
    var completedRoutineCount = 0;
    var startedOnTimeCount = 0;
    var plannedFocusMinutes = 0;
    var recoveredRoutineCount = 0;
    var recoveryOpportunityCount = 0;

    for (final row in plannedRows) {
      final routine = row.readTable(_database.routines);
      final schedule = row.readTable(_database.routineSchedules);
      final log = logsByRoutineId[routine.id];
      final status = log == null
          ? null
          : RoutineStatus.values.byName(log.status);

      plannedCategoryIds.add(routine.categoryId);
      plannedFocusMinutes += routine.fullDurationMinutes;

      if (status == RoutineStatus.completed ||
          status == RoutineStatus.recovered) {
        completedRoutineCount++;
        completedCategoryIds.add(routine.categoryId);
        if (_startedOnTime(log!, date, schedule.startTimeMinutes)) {
          startedOnTimeCount++;
        }
      }

      if (status == RoutineStatus.recovered) {
        recoveredRoutineCount++;
      }
      if (status == RoutineStatus.missed ||
          status == RoutineStatus.rescheduled ||
          status == RoutineStatus.recovered) {
        recoveryOpportunityCount++;
      }
    }

    final actualFocusMinutes = focusSessions.fold<int>(
      0,
      (total, session) => total + session.actualDurationMinutes,
    );
    final breakdown = _calculator.calculate(
      DailyScoreInput(
        plannedRoutineCount: plannedRoutineCount,
        completedRoutineCount: completedRoutineCount,
        startedOnTimeCount: startedOnTimeCount,
        plannedFocusMinutes: plannedFocusMinutes,
        actualFocusMinutes: actualFocusMinutes,
        recoveredRoutineCount: recoveredRoutineCount,
        recoveryOpportunityCount: recoveryOpportunityCount,
        plannedCategoryCount: plannedCategoryIds.length,
        completedCategoryCount: completedCategoryIds.length,
      ),
    );

    final existing = await getScoreForDateKey(dateKey);
    final timestamp = now ?? DateTime.now();
    final scoreId = existing?.id ?? 'score-$dateKey';

    await _database
        .into(_database.dailyScores)
        .insertOnConflictUpdate(
          DailyScoresCompanion.insert(
            id: scoreId,
            date: dateKey,
            score: breakdown.score,
            completionScore: breakdown.completionScore,
            onTimeScore: breakdown.onTimeScore,
            focusScore: breakdown.focusScore,
            recoveryScore: breakdown.recoveryScore,
            balanceScore: breakdown.balanceScore,
            createdAt: existing?.createdAt ?? timestamp,
            updatedAt: timestamp,
          ),
        );

    return (await getScoreForDateKey(dateKey))!;
  }

  Future<DailyScore?> getScoreForDateKey(String dateKey) {
    return (_database.select(_database.dailyScores)
          ..where((table) => table.date.equals(dateKey))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<TypedResult>> _plannedRoutineRows(
    DateTime date,
    String dateKey,
  ) async {
    final rows = await (_database.select(_database.routines).join([
      innerJoin(
        _database.routineSchedules,
        _database.routineSchedules.routineId.equalsExp(_database.routines.id),
      ),
    ])..where(_database.routines.isActive.equals(true))).get();

    return rows.where((row) {
      final schedule = row.readTable(_database.routineSchedules);
      if (schedule.specificDate != null) {
        return schedule.specificDate == dateKey;
      }
      return RecurrenceUtils.repeatsOnWeekday(
        schedule.repeatDays,
        date.weekday,
      );
    }).toList();
  }

  Future<List<FocusSession>> _focusSessionsForDate(String dateKey) async {
    final sessions = await _database.select(_database.focusSessions).get();
    return sessions.where((session) {
      return DateTimeUtils.dateKey(session.startedAt) == dateKey;
    }).toList();
  }

  bool _startedOnTime(
    RoutineLog log,
    DateTime date,
    int plannedStartTimeMinutes,
  ) {
    final actualStart = log.actualStartAt;
    if (actualStart == null) return false;
    final plannedStart = DateTime(
      date.year,
      date.month,
      date.day,
      plannedStartTimeMinutes ~/ 60,
      plannedStartTimeMinutes % 60,
    );
    return !actualStart.isAfter(plannedStart);
  }
}
