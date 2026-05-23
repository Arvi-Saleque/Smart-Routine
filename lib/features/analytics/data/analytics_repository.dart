import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/routine_status.dart';
import '../../../core/utils/date_time_utils.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._database);

  final AppDatabase _database;

  Future<AnalyticsSummary> getSummary({DateTime? endDate, int days = 7}) async {
    final end = _dateOnly(endDate ?? DateTime.now());
    final start = end.subtract(Duration(days: days - 1));
    final startKey = DateTimeUtils.dateKey(start);
    final endKey = DateTimeUtils.dateKey(end);
    final dateKeys = [
      for (var index = 0; index < days; index++)
        DateTimeUtils.dateKey(start.add(Duration(days: index))),
    ];

    final scores =
        await (_database.select(_database.dailyScores)
              ..where((table) => table.date.isBiggerOrEqualValue(startKey))
              ..where((table) => table.date.isSmallerOrEqualValue(endKey)))
            .get();
    final scoresByDate = {for (final score in scores) score.date: score};

    final logs =
        await (_database.select(_database.routineLogs)
              ..where((table) => table.date.isBiggerOrEqualValue(startKey))
              ..where((table) => table.date.isSmallerOrEqualValue(endKey)))
            .get();

    final focusSessions = await _focusSessionsBetween(startKey, endKey);
    final routines = await _database.select(_database.routines).get();
    final categories = await _database.select(_database.categories).get();
    final routinesById = {for (final routine in routines) routine.id: routine};
    final categoriesById = {
      for (final category in categories) category.id: category,
    };

    final dailyScores = [
      for (final dateKey in dateKeys)
        DailyScorePoint(
          dateKey: dateKey,
          score: scoresByDate[dateKey]?.score ?? 0,
          hasScore: scoresByDate.containsKey(dateKey),
        ),
    ];

    final completionByDay = [
      for (final dateKey in dateKeys)
        CompletionPoint.fromLogs(
          dateKey: dateKey,
          logs: logs.where((log) => log.date == dateKey),
        ),
    ];

    final focusByDay = [
      for (final dateKey in dateKeys)
        FocusMinutesPoint(
          dateKey: dateKey,
          minutes: focusSessions
              .where(
                (session) =>
                    DateTimeUtils.dateKey(session.startedAt) == dateKey,
              )
              .fold<int>(
                0,
                (total, session) => total + session.actualDurationMinutes,
              ),
        ),
    ];

    final categoryStats = _categoryStats(
      logs: logs,
      routinesById: routinesById,
      categoriesById: categoriesById,
    );

    final skippedLogs = logs.where(
      (log) => log.status == RoutineStatus.skipped.name,
    );
    final skippedByRoutine = <String, int>{};
    for (final log in skippedLogs) {
      skippedByRoutine.update(
        log.routineId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final mostSkipped = _mostSkippedRoutine(skippedByRoutine, routinesById);

    final recoveryOpportunities = logs.where((log) {
      return log.status == RoutineStatus.missed.name ||
          log.status == RoutineStatus.rescheduled.name ||
          log.status == RoutineStatus.recovered.name;
    }).length;
    final recoveredCount = logs
        .where((log) => log.status == RoutineStatus.recovered.name)
        .length;

    return AnalyticsSummary(
      startDate: start,
      endDate: end,
      dailyScores: dailyScores,
      completionByDay: completionByDay,
      categoryStats: categoryStats,
      focusByDay: focusByDay,
      mostSkippedRoutine: mostSkipped,
      recoveryRate: recoveryOpportunities == 0
          ? null
          : recoveredCount / recoveryOpportunities,
      totalFocusMinutes: focusSessions.fold<int>(
        0,
        (total, session) => total + session.actualDurationMinutes,
      ),
    );
  }

  Future<List<FocusSession>> _focusSessionsBetween(
    String startKey,
    String endKey,
  ) async {
    final sessions = await _database.select(_database.focusSessions).get();
    return sessions.where((session) {
      final dateKey = DateTimeUtils.dateKey(session.startedAt);
      return dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) <= 0;
    }).toList();
  }

  List<CategoryCompletionStat> _categoryStats({
    required List<RoutineLog> logs,
    required Map<String, Routine> routinesById,
    required Map<String, Category> categoriesById,
  }) {
    final builders = <String, _CategoryCompletionBuilder>{};

    for (final log in logs) {
      final routine = routinesById[log.routineId];
      if (routine == null) continue;
      final category = categoriesById[routine.categoryId];
      if (category == null) continue;
      final builder = builders.putIfAbsent(
        category.id,
        () => _CategoryCompletionBuilder(
          categoryId: category.id,
          categoryName: category.name,
          colorValue: category.colorValue,
        ),
      );
      builder.add(log.status);
    }

    final stats = builders.values.map((builder) => builder.build()).toList()
      ..sort(
        (left, right) => right.completedCount.compareTo(left.completedCount),
      );
    return stats;
  }

  MostSkippedRoutine? _mostSkippedRoutine(
    Map<String, int> skippedByRoutine,
    Map<String, Routine> routinesById,
  ) {
    if (skippedByRoutine.isEmpty) return null;
    final top = skippedByRoutine.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    final routine = routinesById[top.key];
    if (routine == null) return null;
    return MostSkippedRoutine(title: routine.title, skippedCount: top.value);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.startDate,
    required this.endDate,
    required this.dailyScores,
    required this.completionByDay,
    required this.categoryStats,
    required this.focusByDay,
    required this.mostSkippedRoutine,
    required this.recoveryRate,
    required this.totalFocusMinutes,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<DailyScorePoint> dailyScores;
  final List<CompletionPoint> completionByDay;
  final List<CategoryCompletionStat> categoryStats;
  final List<FocusMinutesPoint> focusByDay;
  final MostSkippedRoutine? mostSkippedRoutine;
  final double? recoveryRate;
  final int totalFocusMinutes;

  bool get hasAnyData {
    return dailyScores.any((point) => point.hasScore) ||
        completionByDay.any((point) => point.plannedCount > 0) ||
        focusByDay.any((point) => point.minutes > 0);
  }

  int get averageScore {
    final scored = dailyScores.where((point) => point.hasScore).toList();
    if (scored.isEmpty) return 0;
    final total = scored.fold<int>(0, (sum, point) => sum + point.score);
    return (total / scored.length).round();
  }

  int get completedRoutines {
    return completionByDay.fold<int>(
      0,
      (sum, point) => sum + point.completedCount,
    );
  }
}

class DailyScorePoint {
  const DailyScorePoint({
    required this.dateKey,
    required this.score,
    required this.hasScore,
  });

  final String dateKey;
  final int score;
  final bool hasScore;
}

class CompletionPoint {
  const CompletionPoint({
    required this.dateKey,
    required this.completedCount,
    required this.plannedCount,
  });

  factory CompletionPoint.fromLogs({
    required String dateKey,
    required Iterable<RoutineLog> logs,
  }) {
    var planned = 0;
    var completed = 0;
    for (final log in logs) {
      planned++;
      if (log.status == RoutineStatus.completed.name ||
          log.status == RoutineStatus.recovered.name) {
        completed++;
      }
    }
    return CompletionPoint(
      dateKey: dateKey,
      completedCount: completed,
      plannedCount: planned,
    );
  }

  final String dateKey;
  final int completedCount;
  final int plannedCount;

  double get completionRate {
    if (plannedCount == 0) return 0;
    return completedCount / plannedCount;
  }
}

class CategoryCompletionStat {
  const CategoryCompletionStat({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
    required this.completedCount,
    required this.totalCount,
  });

  final String categoryId;
  final String categoryName;
  final int colorValue;
  final int completedCount;
  final int totalCount;

  double get completionRate {
    if (totalCount == 0) return 0;
    return completedCount / totalCount;
  }
}

class FocusMinutesPoint {
  const FocusMinutesPoint({required this.dateKey, required this.minutes});

  final String dateKey;
  final int minutes;
}

class MostSkippedRoutine {
  const MostSkippedRoutine({required this.title, required this.skippedCount});

  final String title;
  final int skippedCount;
}

class _CategoryCompletionBuilder {
  _CategoryCompletionBuilder({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
  });

  final String categoryId;
  final String categoryName;
  final int colorValue;
  var completedCount = 0;
  var totalCount = 0;

  void add(String status) {
    totalCount++;
    if (status == RoutineStatus.completed.name ||
        status == RoutineStatus.recovered.name) {
      completedCount++;
    }
  }

  CategoryCompletionStat build() {
    return CategoryCompletionStat(
      categoryId: categoryId,
      categoryName: categoryName,
      colorValue: colorValue,
      completedCount: completedCount,
      totalCount: totalCount,
    );
  }
}
