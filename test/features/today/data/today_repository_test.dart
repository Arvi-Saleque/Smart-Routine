import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';
import 'package:routine_os/core/enums/difficulty_level.dart';
import 'package:routine_os/core/enums/goal_type.dart';
import 'package:routine_os/core/enums/priority_level.dart';
import 'package:routine_os/core/enums/routine_status.dart';
import 'package:routine_os/core/enums/routine_type.dart';
import 'package:routine_os/core/enums/skip_reason.dart';
import 'package:routine_os/features/routines/data/routine_repository.dart';
import 'package:routine_os/features/today/data/today_repository.dart';

void main() {
  late AppDatabase database;
  late RoutineRepository routineRepository;
  late TodayRepository todayRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    routineRepository = RoutineRepository(database);
    todayRepository = TodayRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('loads scheduled routines and writes complete and skip logs', () async {
    final date = DateTime(2026, 5, 18);

    await routineRepository.createRoutine(
      RoutineFormData(
        title: 'Morning reading',
        categoryId: 'reading',
        routineType: RoutineType.fixedTime,
        goalType: GoalType.duration,
        targetValue: 30,
        targetUnit: 'minutes',
        priority: PriorityLevel.medium,
        difficulty: DifficultyLevel.normal,
        startTimeMinutes: 600,
        endTimeMinutes: 660,
        repeatDays: {date.weekday},
        fullDurationMinutes: 60,
        mediumDurationMinutes: 30,
        miniDurationMinutes: 10,
        reminderEnabled: true,
        timezone: 'Asia/Dhaka',
      ),
    );

    var timeline = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(2026, 5, 18, 10, 30),
    );

    expect(timeline.entries, hasLength(1));
    expect(timeline.entries.single.status, RoutineStatus.active);
    expect(timeline.activeEntry, isNotNull);

    await todayRepository.markCompleted(timeline.entries.single);
    timeline = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(2026, 5, 18, 11),
    );

    expect(timeline.entries.single.status, RoutineStatus.completed);
    expect(timeline.completedCount, 1);
    expect(timeline.progressScore, 100);
    expect(timeline.dailyScore, isNotNull);
    expect(timeline.dailyScore!.score, greaterThan(0));

    final logsAfterCompletion = await database
        .select(database.routineLogs)
        .get();
    expect(logsAfterCompletion.single.actualStartAt, isNull);
    expect(logsAfterCompletion.single.actualEndAt, isNotNull);
    expect(logsAfterCompletion.single.actualDurationMinutes, 60);

    final savedScore = await database.select(database.dailyScores).get();
    expect(savedScore, hasLength(1));
    expect(savedScore.single.date, timeline.entries.single.dateKey);

    await todayRepository.markSkipped(
      timeline.entries.single,
      SkipReason.busy.name,
    );
    timeline = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(2026, 5, 18, 11),
    );

    expect(timeline.entries.single.status, RoutineStatus.skipped);
    expect(timeline.skippedCount, 1);
  });

  test('reschedules missed routines and keeps recovery notes', () async {
    final date = DateTime.now();

    await routineRepository.createRoutine(
      RoutineFormData(
        title: 'Night reading',
        categoryId: 'reading',
        routineType: RoutineType.fixedTime,
        goalType: GoalType.duration,
        targetValue: 30,
        targetUnit: 'minutes',
        priority: PriorityLevel.medium,
        difficulty: DifficultyLevel.normal,
        startTimeMinutes: 60,
        endTimeMinutes: 90,
        repeatDays: {date.weekday},
        fullDurationMinutes: 30,
        mediumDurationMinutes: 20,
        miniDurationMinutes: 5,
        reminderEnabled: true,
        timezone: 'Asia/Dhaka',
      ),
    );

    var timeline = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(date.year, date.month, date.day, 10),
    );
    expect(timeline.entries.single.status, RoutineStatus.missed);

    await todayRepository.rescheduleLaterToday(timeline.entries.single);
    timeline = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(date.year, date.month, date.day, 10),
    );

    final rescheduled = timeline.entries.single;
    expect(rescheduled.log!.status, RoutineStatus.rescheduled.name);
    expect(rescheduled.log!.plannedStartTimeMinutes, greaterThan(90));
    expect(rescheduled.recoveryNote, contains('Rescheduled for'));

    final activeAtRescheduledTime = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(minutes: rescheduled.log!.plannedStartTimeMinutes)),
    );
    expect(activeAtRescheduledTime.entries.single.status, RoutineStatus.active);

    final missedAfterRescheduledTime = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(
        date.year,
        date.month,
        date.day,
      ).add(Duration(minutes: rescheduled.log!.plannedEndTimeMinutes + 1)),
    );
    expect(
      missedAfterRescheduledTime.entries.single.status,
      RoutineStatus.missed,
    );

    await todayRepository.moveToTomorrow(rescheduled);
    timeline = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(date.year, date.month, date.day, 10),
    );

    expect(timeline.entries.single.log!.status, RoutineStatus.rescheduled.name);
    expect(timeline.entries.single.recoveryNote, contains('Moved to'));
  });

  test(
    'move to tomorrow creates a one-time schedule for selected tomorrow',
    () async {
      final date = DateTime(2026, 5, 18);
      final tomorrow = DateTime(2026, 5, 19);

      await routineRepository.createRoutine(
        RoutineFormData(
          title: 'Single weekday reading',
          categoryId: 'reading',
          routineType: RoutineType.fixedTime,
          goalType: GoalType.duration,
          targetValue: 30,
          targetUnit: 'minutes',
          priority: PriorityLevel.medium,
          difficulty: DifficultyLevel.normal,
          startTimeMinutes: 600,
          endTimeMinutes: 660,
          repeatDays: {date.weekday},
          fullDurationMinutes: 60,
          mediumDurationMinutes: 30,
          miniDurationMinutes: 10,
          reminderEnabled: true,
          timezone: 'Asia/Dhaka',
        ),
      );

      final timeline = await todayRepository.getTimelineForDate(
        date,
        now: DateTime(2026, 5, 18, 11, 1),
      );
      expect(timeline.entries.single.status, RoutineStatus.missed);

      await todayRepository.moveToTomorrow(timeline.entries.single);

      final schedules = await database.select(database.routineSchedules).get();
      expect(
        schedules.where((schedule) => schedule.specificDate == '2026-05-19'),
        hasLength(1),
      );

      final tomorrowTimeline = await todayRepository.getTimelineForDate(
        tomorrow,
        now: DateTime(2026, 5, 19, 9),
      );

      expect(tomorrowTimeline.entries, hasLength(1));
      expect(
        tomorrowTimeline.entries.single.detail.routine.title,
        'Single weekday reading',
      );
    },
  );

  test('stale timeline entries update one log per routine and date', () async {
    final date = DateTime(2026, 5, 18);

    await routineRepository.createRoutine(
      RoutineFormData(
        title: 'No duplicate reading',
        categoryId: 'reading',
        routineType: RoutineType.fixedTime,
        goalType: GoalType.duration,
        targetValue: 30,
        targetUnit: 'minutes',
        priority: PriorityLevel.medium,
        difficulty: DifficultyLevel.normal,
        startTimeMinutes: 600,
        endTimeMinutes: 660,
        repeatDays: {date.weekday},
        fullDurationMinutes: 60,
        mediumDurationMinutes: 30,
        miniDurationMinutes: 10,
        reminderEnabled: true,
        timezone: 'Asia/Dhaka',
      ),
    );

    final timeline = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(2026, 5, 18, 10, 30),
    );
    final staleEntry = timeline.entries.single;

    await todayRepository.markCompleted(staleEntry);
    await todayRepository.markSkipped(staleEntry, SkipReason.busy.name);

    final logs = await database.select(database.routineLogs).get();

    expect(logs, hasLength(1));
    expect(logs.single.status, RoutineStatus.skipped.name);
  });

  test(
    'future date preview shows planned routines without saving score',
    () async {
      final now = DateTime(2026, 5, 18, 9);
      final futureDate = DateTime(2026, 5, 19);

      await routineRepository.createRoutine(
        RoutineFormData(
          title: 'Future reading',
          categoryId: 'reading',
          routineType: RoutineType.fixedTime,
          goalType: GoalType.duration,
          targetValue: 30,
          targetUnit: 'minutes',
          priority: PriorityLevel.medium,
          difficulty: DifficultyLevel.normal,
          startTimeMinutes: 600,
          endTimeMinutes: 660,
          repeatDays: {futureDate.weekday},
          fullDurationMinutes: 60,
          mediumDurationMinutes: 30,
          miniDurationMinutes: 10,
          reminderEnabled: true,
          timezone: 'Asia/Dhaka',
        ),
      );

      final timeline = await todayRepository.getTimelineForDate(
        futureDate,
        now: now,
      );

      expect(timeline.entries, hasLength(1));
      expect(timeline.entries.single.status, RoutineStatus.upcoming);
      expect(timeline.dailyScore, isNull);
      expect(timeline.scoreMessage, 'No saved score for this date yet.');

      final savedScores = await database.select(database.dailyScores).get();
      expect(savedScores, isEmpty);
    },
  );
}
