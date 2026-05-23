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
    expect(rescheduled.status, RoutineStatus.rescheduled);
    expect(rescheduled.log!.plannedStartTimeMinutes, greaterThan(90));
    expect(rescheduled.recoveryNote, contains('Rescheduled for'));

    await todayRepository.moveToTomorrow(rescheduled);
    timeline = await todayRepository.getTimelineForDate(
      date,
      now: DateTime(date.year, date.month, date.day, 10),
    );

    expect(timeline.entries.single.status, RoutineStatus.rescheduled);
    expect(timeline.entries.single.recoveryNote, contains('Moved to'));
  });
}
