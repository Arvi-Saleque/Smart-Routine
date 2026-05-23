import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/routine_status.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../application/smart_coach_engine.dart';

class SmartCoachRepository {
  SmartCoachRepository(
    this._database, {
    SmartCoachEngine engine = const SmartCoachEngine(),
  }) : _engine = engine;

  final AppDatabase _database;
  final SmartCoachEngine _engine;

  Future<List<SmartCoachInsight>> getInsights({DateTime? now}) async {
    final context = await buildContext(now: now);
    if (!context.hasEnoughData) return const [];
    return _engine.generate(context);
  }

  Future<SmartCoachContext> buildContext({DateTime? now}) async {
    final generatedAt = now ?? DateTime.now();
    final today = DateTime(
      generatedAt.year,
      generatedAt.month,
      generatedAt.day,
    );
    final todayKey = DateTimeUtils.dateKey(today);
    final weekStart = today.subtract(const Duration(days: 6));
    final weekStartKey = DateTimeUtils.dateKey(weekStart);
    final yesterdayKey = DateTimeUtils.dateKey(
      today.subtract(const Duration(days: 1)),
    );

    final routineRows = await (_database.select(_database.routines).join([
      innerJoin(
        _database.routineSchedules,
        _database.routineSchedules.routineId.equalsExp(_database.routines.id),
      ),
    ])..where(_database.routines.isActive.equals(true))).get();

    final logs =
        await (_database.select(_database.routineLogs)
              ..where((table) => table.date.isBiggerOrEqualValue(weekStartKey))
              ..where((table) => table.date.isSmallerOrEqualValue(todayKey)))
            .get();
    final logsByRoutineDate = {
      for (final log in logs) _routineDateKey(log.routineId, log.date): log,
    };
    final categories = await _database.select(_database.categories).get();
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    final plannedMinutesToday = _plannedMinutesForDate(
      routineRows: routineRows,
      date: today,
      dateKey: todayKey,
    );
    final averageCompletedMinutes = _averageCompletedMinutes(logs);
    final lateNight = _lateNightSignal(
      routineRows: routineRows,
      logsByRoutineDate: logsByRoutineDate,
      start: weekStart,
      end: today,
    );
    final weakCategories = _weakCategories(
      routineRows: routineRows,
      logsByRoutineDate: logsByRoutineDate,
      categoriesById: categoriesById,
      start: weekStart,
      end: today,
    );
    final recoverable = _missedRecoverableRoutines(
      routineRows: routineRows,
      logsByRoutineDate: logsByRoutineDate,
      today: today,
      todayKey: todayKey,
      currentMinutes: generatedAt.hour * 60 + generatedAt.minute,
    );
    final streaks = _streaks(
      routineRows: routineRows,
      logsByRoutineDate: logsByRoutineDate,
      yesterdayKey: yesterdayKey,
    );

    return SmartCoachContext(
      generatedAt: generatedAt,
      plannedMinutesToday: plannedMinutesToday,
      averageCompletedMinutes: averageCompletedMinutes,
      lateNightPlannedCount: lateNight.plannedCount,
      lateNightCompletionRate: lateNight.completionRate,
      weakCategories: weakCategories,
      missedRecoverableRoutines: recoverable,
      streaks: streaks,
    );
  }

  int _plannedMinutesForDate({
    required List<TypedResult> routineRows,
    required DateTime date,
    required String dateKey,
  }) {
    var minutes = 0;
    for (final row in routineRows) {
      final routine = row.readTable(_database.routines);
      final schedule = row.readTable(_database.routineSchedules);
      if (_isScheduledFor(schedule, date, dateKey)) {
        minutes += routine.fullDurationMinutes;
      }
    }
    return minutes;
  }

  int _averageCompletedMinutes(List<RoutineLog> logs) {
    final totalsByDate = <String, int>{};
    for (final log in logs) {
      if (!_isCompletion(log.status)) continue;
      totalsByDate.update(
        log.date,
        (total) => total + (log.actualDurationMinutes ?? 0),
        ifAbsent: () => log.actualDurationMinutes ?? 0,
      );
    }
    if (totalsByDate.isEmpty) return 0;
    final total = totalsByDate.values.fold<int>(0, (sum, value) => sum + value);
    return (total / totalsByDate.length).round();
  }

  _LateNightSignal _lateNightSignal({
    required List<TypedResult> routineRows,
    required Map<String, RoutineLog> logsByRoutineDate,
    required DateTime start,
    required DateTime end,
  }) {
    var planned = 0;
    var completed = 0;
    for (final day in _daysBetween(start, end)) {
      final dateKey = DateTimeUtils.dateKey(day);
      for (final row in routineRows) {
        final routine = row.readTable(_database.routines);
        final schedule = row.readTable(_database.routineSchedules);
        if (schedule.startTimeMinutes < 22 * 60) continue;
        if (!_isScheduledFor(schedule, day, dateKey)) continue;
        planned++;
        final log = logsByRoutineDate[_routineDateKey(routine.id, dateKey)];
        if (log != null && _isCompletion(log.status)) completed++;
      }
    }
    return _LateNightSignal(
      plannedCount: planned,
      completionRate: planned == 0 ? null : completed / planned,
    );
  }

  List<WeakCategorySignal> _weakCategories({
    required List<TypedResult> routineRows,
    required Map<String, RoutineLog> logsByRoutineDate,
    required Map<String, Category> categoriesById,
    required DateTime start,
    required DateTime end,
  }) {
    final stats = <String, _CategoryStats>{};
    for (final day in _daysBetween(start, end)) {
      final dateKey = DateTimeUtils.dateKey(day);
      for (final row in routineRows) {
        final routine = row.readTable(_database.routines);
        final schedule = row.readTable(_database.routineSchedules);
        if (!_isScheduledFor(schedule, day, dateKey)) continue;
        final category = categoriesById[routine.categoryId];
        if (category == null) continue;
        final stat = stats.putIfAbsent(
          category.id,
          () => _CategoryStats(categoryId: category.id, name: category.name),
        );
        stat.planned++;
        final log = logsByRoutineDate[_routineDateKey(routine.id, dateKey)];
        if (log != null && _isCompletion(log.status)) stat.completed++;
      }
    }

    final weak =
        stats.values
            .where((stat) => stat.planned >= 2 && stat.completionRate < 0.5)
            .map(
              (stat) => WeakCategorySignal(
                categoryId: stat.categoryId,
                categoryName: stat.name,
                completionRate: stat.completionRate,
              ),
            )
            .toList()
          ..sort(
            (left, right) =>
                left.completionRate.compareTo(right.completionRate),
          );
    return weak;
  }

  List<RecoverableRoutineSignal> _missedRecoverableRoutines({
    required List<TypedResult> routineRows,
    required Map<String, RoutineLog> logsByRoutineDate,
    required DateTime today,
    required String todayKey,
    required int currentMinutes,
  }) {
    final signals = <RecoverableRoutineSignal>[];
    for (final row in routineRows) {
      final routine = row.readTable(_database.routines);
      final schedule = row.readTable(_database.routineSchedules);
      if (routine.miniDurationMinutes <= 0) continue;
      if (!_isScheduledFor(schedule, today, todayKey)) continue;
      final log = logsByRoutineDate[_routineDateKey(routine.id, todayKey)];
      final missedByLog = log?.status == RoutineStatus.missed.name;
      final missedByTime =
          log == null && currentMinutes > schedule.endTimeMinutes;
      if (!missedByLog && !missedByTime) continue;
      signals.add(
        RecoverableRoutineSignal(
          routineId: routine.id,
          title: routine.title,
          miniDurationMinutes: routine.miniDurationMinutes,
        ),
      );
    }
    return signals;
  }

  List<RoutineStreakSignal> _streaks({
    required List<TypedResult> routineRows,
    required Map<String, RoutineLog> logsByRoutineDate,
    required String yesterdayKey,
  }) {
    final signals = <RoutineStreakSignal>[];
    for (final row in routineRows) {
      final routine = row.readTable(_database.routines);
      var cursor = DateTime.parse(yesterdayKey);
      var count = 0;
      while (true) {
        final dateKey = DateTimeUtils.dateKey(cursor);
        final log = logsByRoutineDate[_routineDateKey(routine.id, dateKey)];
        if (log == null || !_isCompletion(log.status)) break;
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      if (count >= 3) {
        signals.add(
          RoutineStreakSignal(
            routineId: routine.id,
            title: routine.title,
            dayCount: count,
          ),
        );
      }
    }
    signals.sort((left, right) => right.dayCount.compareTo(left.dayCount));
    return signals;
  }

  bool _isScheduledFor(RoutineSchedule schedule, DateTime day, String dateKey) {
    if (schedule.specificDate != null) {
      return schedule.specificDate == dateKey;
    }
    return RecurrenceUtils.repeatsOnWeekday(schedule.repeatDays, day.weekday);
  }

  Iterable<DateTime> _daysBetween(DateTime start, DateTime end) sync* {
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      yield day;
    }
  }

  bool _isCompletion(String status) {
    return status == RoutineStatus.completed.name ||
        status == RoutineStatus.recovered.name;
  }

  String _routineDateKey(String routineId, String dateKey) {
    return '$routineId|$dateKey';
  }
}

class _LateNightSignal {
  const _LateNightSignal({
    required this.plannedCount,
    required this.completionRate,
  });

  final int plannedCount;
  final double? completionRate;
}

class _CategoryStats {
  _CategoryStats({required this.categoryId, required this.name});

  final String categoryId;
  final String name;
  var planned = 0;
  var completed = 0;

  double get completionRate => planned == 0 ? 0 : completed / planned;
}
