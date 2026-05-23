import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';
import 'package:routine_os/core/enums/difficulty_level.dart';
import 'package:routine_os/core/enums/goal_type.dart';
import 'package:routine_os/core/enums/priority_level.dart';
import 'package:routine_os/core/enums/routine_type.dart';
import 'package:routine_os/core/enums/skip_reason.dart';
import 'package:routine_os/features/coach/application/smart_coach_engine.dart';
import 'package:routine_os/features/coach/data/smart_coach_repository.dart';
import 'package:routine_os/features/routines/data/routine_repository.dart';
import 'package:routine_os/features/today/data/today_repository.dart';

void main() {
  late AppDatabase database;
  late RoutineRepository routineRepository;
  late TodayRepository todayRepository;
  late SmartCoachRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    routineRepository = RoutineRepository(database);
    todayRepository = TodayRepository(database);
    repository = SmartCoachRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('returns empty insights when there is not enough local data', () async {
    final insights = await repository.getInsights(
      now: DateTime(2026, 5, 24, 12),
    );

    expect(insights, isEmpty);
  });

  test('builds local insights from routines and logs', () async {
    final today = DateTime(2026, 5, 24);
    await _createRoutine(
      routineRepository,
      title: 'Late study',
      categoryId: 'study',
      startTimeMinutes: 22 * 60,
      endTimeMinutes: (22 * 60) + 45,
      repeatDays: {1, 2, 3, 4, 5, 6, 7},
    );
    await _createRoutine(
      routineRepository,
      title: 'Bangla reading',
      categoryId: 'reading',
      startTimeMinutes: 8 * 60,
      endTimeMinutes: (8 * 60) + 60,
      repeatDays: {1, 2, 3, 4, 5, 6, 7},
    );

    for (var offset = 1; offset <= 3; offset++) {
      final date = today.subtract(Duration(days: offset));
      final timeline = await todayRepository.getTimelineForDate(
        date,
        now: DateTime(date.year, date.month, date.day, 23),
      );
      await todayRepository.markCompleted(timeline.entries[0]);
      await todayRepository.markSkipped(
        timeline.entries[1],
        SkipReason.tooTired.name,
      );
    }

    final insights = await repository.getInsights(
      now: DateTime(2026, 5, 24, 23),
    );

    expect(insights, isNotEmpty);
    expect(
      insights.map((insight) => insight.category),
      contains(SmartCoachCategory.timing),
    );
    expect(
      insights.map((insight) => insight.category),
      contains(SmartCoachCategory.recovery),
    );
    expect(
      insights.map((insight) => insight.category),
      contains(SmartCoachCategory.routineHealth),
    );
  });
}

Future<void> _createRoutine(
  RoutineRepository repository, {
  required String title,
  required String categoryId,
  required int startTimeMinutes,
  required int endTimeMinutes,
  required Set<int> repeatDays,
}) async {
  await repository.createRoutine(
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
      repeatDays: repeatDays,
      fullDurationMinutes: endTimeMinutes - startTimeMinutes,
      mediumDurationMinutes: 20,
      miniDurationMinutes: 10,
      reminderEnabled: true,
      timezone: 'Asia/Dhaka',
    ),
  );
}
