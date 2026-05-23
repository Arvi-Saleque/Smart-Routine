import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';
import 'package:routine_os/core/enums/difficulty_level.dart';
import 'package:routine_os/core/enums/goal_type.dart';
import 'package:routine_os/core/enums/priority_level.dart';
import 'package:routine_os/core/enums/routine_status.dart';
import 'package:routine_os/core/enums/routine_type.dart';
import 'package:routine_os/core/enums/skip_reason.dart';
import 'package:routine_os/features/analytics/data/analytics_repository.dart';
import 'package:routine_os/features/focus/data/focus_repository.dart';
import 'package:routine_os/features/routines/data/routine_repository.dart';
import 'package:routine_os/features/today/data/today_repository.dart';

void main() {
  late AppDatabase database;
  late RoutineRepository routineRepository;
  late TodayRepository todayRepository;
  late FocusRepository focusRepository;
  late AnalyticsRepository analyticsRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    routineRepository = RoutineRepository(database);
    todayRepository = TodayRepository(database);
    focusRepository = FocusRepository(database);
    analyticsRepository = AnalyticsRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'summarizes scores, completion, categories, focus, skips, and recovery',
    () async {
      final date = DateTime(2026, 5, 18);
      final readingId = await _createRoutine(
        routineRepository,
        title: 'Reading',
        categoryId: 'reading',
        startTimeMinutes: 600,
        endTimeMinutes: 660,
        weekday: date.weekday,
      );
      await _createRoutine(
        routineRepository,
        title: 'Coding',
        categoryId: 'coding',
        startTimeMinutes: 700,
        endTimeMinutes: 760,
        weekday: date.weekday,
      );
      final recoveryId = await _createRoutine(
        routineRepository,
        title: 'Recovery',
        categoryId: 'health',
        startTimeMinutes: 800,
        endTimeMinutes: 830,
        weekday: date.weekday,
      );

      var timeline = await todayRepository.getTimelineForDate(
        date,
        now: DateTime(2026, 5, 18, 10, 30),
      );
      await todayRepository.markCompleted(timeline.entries[0]);
      await todayRepository.markSkipped(
        timeline.entries[1],
        SkipReason.busy.name,
      );

      final recoveryDetail = await routineRepository.getRoutineDetail(
        recoveryId,
      );
      await focusRepository.finishSession(
        FocusSessionDraft(
          routineDetail: recoveryDetail!,
          startedAt: DateTime(2026, 5, 18, 21),
          endedAt: DateTime(2026, 5, 18, 21, 5),
          actualDuration: const Duration(minutes: 5),
          plannedDurationMinutes: 5,
          distractionCount: 0,
          note: 'Recovered.',
          completionStatus: RoutineStatus.recovered,
        ),
      );

      final readingDetail = await routineRepository.getRoutineDetail(readingId);
      await focusRepository.finishSession(
        FocusSessionDraft(
          routineDetail: readingDetail!,
          startedAt: DateTime(2026, 5, 18, 10),
          endedAt: DateTime(2026, 5, 18, 10, 20),
          actualDuration: const Duration(minutes: 20),
          plannedDurationMinutes: 60,
          distractionCount: 1,
          note: 'Read.',
        ),
      );

      await todayRepository.getTimelineForDate(
        date,
        now: DateTime(2026, 5, 18, 22),
      );

      final summary = await analyticsRepository.getSummary(
        endDate: DateTime(2026, 5, 18),
      );

      expect(summary.hasAnyData, isTrue);
      expect(summary.dailyScores.last.hasScore, isTrue);
      expect(summary.completedRoutines, 2);
      expect(summary.totalFocusMinutes, 25);
      expect(summary.categoryStats, isNotEmpty);
      expect(summary.mostSkippedRoutine?.title, 'Coding');
      expect(summary.recoveryRate, isNotNull);
    },
  );
}

Future<String> _createRoutine(
  RoutineRepository repository, {
  required String title,
  required String categoryId,
  required int startTimeMinutes,
  required int endTimeMinutes,
  required int weekday,
}) {
  return repository.createRoutine(
    RoutineFormData(
      title: title,
      categoryId: categoryId,
      routineType: RoutineType.fixedTime,
      goalType: GoalType.duration,
      targetValue: (endTimeMinutes - startTimeMinutes).toDouble(),
      targetUnit: 'minutes',
      priority: PriorityLevel.medium,
      difficulty: DifficultyLevel.normal,
      startTimeMinutes: startTimeMinutes,
      endTimeMinutes: endTimeMinutes,
      repeatDays: {weekday},
      fullDurationMinutes: endTimeMinutes - startTimeMinutes,
      mediumDurationMinutes: 20,
      miniDurationMinutes: 5,
      reminderEnabled: true,
      timezone: 'Asia/Dhaka',
    ),
  );
}
