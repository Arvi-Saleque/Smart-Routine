import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/enums/routine_status.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/recurrence_utils.dart';

class CalendarRepository {
  CalendarRepository(this._database);

  final AppDatabase _database;

  Future<CalendarMonthSummary> getMonthSummary(
    DateTime month, {
    DateTime? now,
  }) async {
    final focusedMonth = DateTime(month.year, month.month);
    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final firstKey = DateTimeUtils.dateKey(firstDay);
    final lastKey = DateTimeUtils.dateKey(lastDay);
    final currentTime = now ?? DateTime.now();
    final currentDateKey = DateTimeUtils.dateKey(currentTime);
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;

    final routineRows = await (_database.select(_database.routines).join([
      innerJoin(
        _database.routineSchedules,
        _database.routineSchedules.routineId.equalsExp(_database.routines.id),
      ),
    ])..where(_database.routines.isActive.equals(true))).get();

    final logs =
        await (_database.select(_database.routineLogs)
              ..where((table) => table.date.isBiggerOrEqualValue(firstKey))
              ..where((table) => table.date.isSmallerOrEqualValue(lastKey)))
            .get();
    final logsByRoutineDate = {
      for (final log in logs) _routineDateKey(log.routineId, log.date): log,
    };

    final scores =
        await (_database.select(_database.dailyScores)
              ..where((table) => table.date.isBiggerOrEqualValue(firstKey))
              ..where((table) => table.date.isSmallerOrEqualValue(lastKey)))
            .get();
    final scoresByDate = {for (final score in scores) score.date: score};

    final markers = <String, CalendarDayMarker>{};
    for (var day = firstDay; !day.isAfter(lastDay); day = _nextDay(day)) {
      final dateKey = DateTimeUtils.dateKey(day);
      final builder = _CalendarDayMarkerBuilder(
        dateKey: dateKey,
        score: scoresByDate[dateKey],
      );

      for (final row in routineRows) {
        final routine = row.readTable(_database.routines);
        final schedule = row.readTable(_database.routineSchedules);
        if (!_isScheduledFor(schedule, day, dateKey)) continue;

        final log = logsByRoutineDate[_routineDateKey(routine.id, dateKey)];
        final status = log == null
            ? _implicitStatus(
                dateKey: dateKey,
                currentDateKey: currentDateKey,
                currentMinutes: currentMinutes,
                schedule: schedule,
              )
            : RoutineStatus.values.byName(log.status);

        builder.add(status);
      }

      final marker = builder.build();
      if (marker.hasActivity) {
        markers[dateKey] = marker;
      }
    }

    return CalendarMonthSummary(
      focusedMonth: focusedMonth,
      markersByDateKey: markers,
    );
  }

  bool _isScheduledFor(RoutineSchedule schedule, DateTime day, String dateKey) {
    if (schedule.specificDate != null) {
      return schedule.specificDate == dateKey;
    }
    return RecurrenceUtils.repeatsOnWeekday(schedule.repeatDays, day.weekday);
  }

  RoutineStatus _implicitStatus({
    required String dateKey,
    required String currentDateKey,
    required int currentMinutes,
    required RoutineSchedule schedule,
  }) {
    if (dateKey.compareTo(currentDateKey) < 0) return RoutineStatus.missed;
    if (dateKey.compareTo(currentDateKey) > 0) return RoutineStatus.upcoming;
    if (currentMinutes > schedule.endTimeMinutes) return RoutineStatus.missed;
    if (currentMinutes >= schedule.startTimeMinutes) {
      return RoutineStatus.active;
    }
    return RoutineStatus.upcoming;
  }

  String _routineDateKey(String routineId, String dateKey) {
    return '$routineId|$dateKey';
  }

  DateTime _nextDay(DateTime day) => day.add(const Duration(days: 1));
}

class CalendarMonthSummary {
  const CalendarMonthSummary({
    required this.focusedMonth,
    required this.markersByDateKey,
  });

  final DateTime focusedMonth;
  final Map<String, CalendarDayMarker> markersByDateKey;

  CalendarDayMarker? markerFor(DateTime day) {
    return markersByDateKey[DateTimeUtils.dateKey(day)];
  }
}

class CalendarDayMarker {
  const CalendarDayMarker({
    required this.dateKey,
    required this.plannedCount,
    required this.completedCount,
    required this.skippedCount,
    required this.missedCount,
    required this.recoveredCount,
    required this.rescheduledCount,
    required this.score,
  });

  final String dateKey;
  final int plannedCount;
  final int completedCount;
  final int skippedCount;
  final int missedCount;
  final int recoveredCount;
  final int rescheduledCount;
  final DailyScore? score;

  bool get hasActivity => plannedCount > 0 || score != null;
}

class _CalendarDayMarkerBuilder {
  _CalendarDayMarkerBuilder({required this.dateKey, required this.score});

  final String dateKey;
  final DailyScore? score;
  var plannedCount = 0;
  var completedCount = 0;
  var skippedCount = 0;
  var missedCount = 0;
  var recoveredCount = 0;
  var rescheduledCount = 0;

  void add(RoutineStatus status) {
    plannedCount++;
    switch (status) {
      case RoutineStatus.completed:
        completedCount++;
        break;
      case RoutineStatus.recovered:
        recoveredCount++;
        completedCount++;
        break;
      case RoutineStatus.skipped:
        skippedCount++;
        break;
      case RoutineStatus.missed:
        missedCount++;
        break;
      case RoutineStatus.rescheduled:
      case RoutineStatus.moved:
        rescheduledCount++;
        break;
      case RoutineStatus.upcoming:
      case RoutineStatus.active:
      case RoutineStatus.started:
        break;
    }
  }

  CalendarDayMarker build() {
    return CalendarDayMarker(
      dateKey: dateKey,
      plannedCount: plannedCount,
      completedCount: completedCount,
      skippedCount: skippedCount,
      missedCount: missedCount,
      recoveredCount: recoveredCount,
      rescheduledCount: rescheduledCount,
      score: score,
    );
  }
}
