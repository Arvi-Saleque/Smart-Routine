import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';
import 'package:routine_os/core/enums/difficulty_level.dart';
import 'package:routine_os/core/enums/goal_type.dart';
import 'package:routine_os/core/enums/priority_level.dart';
import 'package:routine_os/core/enums/routine_type.dart';
import 'package:routine_os/core/enums/skip_reason.dart';
import 'package:routine_os/features/calendar/data/calendar_repository.dart';
import 'package:routine_os/features/routines/data/routine_repository.dart';
import 'package:routine_os/features/today/data/today_repository.dart';

void main() {
  late AppDatabase database;
  late RoutineRepository routineRepository;
  late TodayRepository todayRepository;
  late CalendarRepository calendarRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    routineRepository = RoutineRepository(database);
    todayRepository = TodayRepository(database);
    calendarRepository = CalendarRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('builds month markers with routine status counts and score', () async {
    final date = DateTime(2026, 5, 18);

    await _createRoutine(
      routineRepository,
      title: 'Reading',
      startTimeMinutes: 600,
      endTimeMinutes: 660,
      weekday: date.weekday,
    );
    await _createRoutine(
      routineRepository,
      title: 'Coding',
      startTimeMinutes: 700,
      endTimeMinutes: 760,
      weekday: date.weekday,
    );
    await _createRoutine(
      routineRepository,
      title: 'Planning',
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

    await todayRepository.getTimelineForDate(date, now: DateTime(2026, 5, 24));

    final summary = await calendarRepository.getMonthSummary(
      date,
      now: DateTime(2026, 5, 24),
    );
    final marker = summary.markerFor(date);

    expect(marker, isNotNull);
    expect(marker!.plannedCount, 3);
    expect(marker.completedCount, 1);
    expect(marker.skippedCount, 1);
    expect(marker.missedCount, 1);
    expect(marker.score, isNotNull);
  });
}

Future<void> _createRoutine(
  RoutineRepository repository, {
  required String title,
  required int startTimeMinutes,
  required int endTimeMinutes,
  required int weekday,
}) async {
  await repository.createRoutine(
    RoutineFormData(
      title: title,
      categoryId: 'reading',
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
