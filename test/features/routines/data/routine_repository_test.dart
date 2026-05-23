import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';
import 'package:routine_os/core/enums/difficulty_level.dart';
import 'package:routine_os/core/enums/goal_type.dart';
import 'package:routine_os/core/enums/priority_level.dart';
import 'package:routine_os/core/enums/routine_type.dart';
import 'package:routine_os/core/notifications/notification_scheduler.dart';
import 'package:routine_os/features/routines/data/routine_repository.dart';

void main() {
  late AppDatabase database;
  late _FakeRoutineNotificationScheduler scheduler;
  late RoutineRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    scheduler = _FakeRoutineNotificationScheduler();
    repository = RoutineRepository(database, scheduler: scheduler);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'creates, updates, pauses, and deletes a routine with schedule',
    () async {
      final routineId = await repository.createRoutine(
        const RoutineFormData(
          title: 'Read Bangla',
          description: 'Read literature at night',
          categoryId: 'reading',
          routineType: RoutineType.fixedTime,
          goalType: GoalType.quantity,
          targetValue: 20,
          targetUnit: 'pages',
          priority: PriorityLevel.high,
          difficulty: DifficultyLevel.normal,
          startTimeMinutes: 1320,
          endTimeMinutes: 1380,
          repeatDays: {1, 2, 3, 4, 5, 6, 7},
          fullDurationMinutes: 60,
          mediumDurationMinutes: 30,
          miniDurationMinutes: 10,
          reminderEnabled: true,
          timezone: 'Asia/Dhaka',
        ),
      );

      final created = await repository.getRoutineDetail(routineId);
      expect(created, isNotNull);
      expect(created!.routine.title, 'Read Bangla');
      expect(created.category.id, 'reading');
      expect(created.schedule!.startTimeMinutes, 1320);

      await repository.updateRoutine(
        routineId,
        const RoutineFormData(
          title: 'Read Bangla Book',
          categoryId: 'reading',
          routineType: RoutineType.fixedTime,
          goalType: GoalType.quantity,
          targetValue: 15,
          targetUnit: 'pages',
          priority: PriorityLevel.medium,
          difficulty: DifficultyLevel.easy,
          startTimeMinutes: 1260,
          endTimeMinutes: 1320,
          repeatDays: {1, 3, 5},
          fullDurationMinutes: 60,
          mediumDurationMinutes: 30,
          miniDurationMinutes: 10,
          reminderEnabled: false,
          timezone: 'Asia/Dhaka',
        ),
      );

      final updated = await repository.getRoutineDetail(routineId);
      expect(updated!.routine.title, 'Read Bangla Book');
      expect(updated.routine.reminderEnabled, isFalse);
      expect(updated.schedule!.repeatDays, '1,3,5');

      await repository.setRoutineActive(routineId, false);
      final paused = await repository.getRoutineDetail(routineId);
      expect(paused!.routine.isActive, isFalse);
      expect(scheduler.cancelled, contains(routineId));

      await repository.updateRoutine(
        routineId,
        const RoutineFormData(
          title: 'Paused Bangla Book',
          categoryId: 'reading',
          routineType: RoutineType.fixedTime,
          goalType: GoalType.quantity,
          targetValue: 10,
          targetUnit: 'pages',
          priority: PriorityLevel.medium,
          difficulty: DifficultyLevel.easy,
          startTimeMinutes: 1260,
          endTimeMinutes: 1320,
          repeatDays: {1, 3, 5},
          fullDurationMinutes: 60,
          mediumDurationMinutes: 30,
          miniDurationMinutes: 10,
          reminderEnabled: true,
          timezone: 'Asia/Dhaka',
        ),
      );
      expect(scheduler.scheduled.last.isActive, isFalse);

      await repository.deleteRoutine(routineId);
      expect(await repository.getRoutineDetail(routineId), isNull);
    },
  );

  test('invalid empty title fails', () async {
    await expectLater(
      repository.createRoutine(_validFormData(title: ' ')),
      throwsA(isA<RoutineFormValidationException>()),
    );
  });

  test('end before start fails', () async {
    await expectLater(
      repository.createRoutine(
        _validFormData(startTimeMinutes: 660, endTimeMinutes: 600),
      ),
      throwsA(isA<RoutineFormValidationException>()),
    );
  });

  test('no repeat day fails', () async {
    await expectLater(
      repository.createRoutine(_validFormData(repeatDays: const {})),
      throwsA(isA<RoutineFormValidationException>()),
    );
  });

  test('simpleCheck can save without target', () async {
    final routineId = await repository.createRoutine(
      _validFormData(goalType: GoalType.simpleCheck, targetValue: null),
    );

    final detail = await repository.getRoutineDetail(routineId);

    expect(detail, isNotNull);
    expect(detail!.routine.goalType, GoalType.simpleCheck.name);
    expect(detail.routine.targetValue, isNull);
  });

  test('duration count and quantity goals require target', () async {
    for (final goalType in [
      GoalType.duration,
      GoalType.count,
      GoalType.quantity,
    ]) {
      await expectLater(
        repository.createRoutine(
          _validFormData(goalType: goalType, targetValue: null),
        ),
        throwsA(isA<RoutineFormValidationException>()),
      );
    }
  });
}

RoutineFormData _validFormData({
  String title = 'Read Bangla',
  String categoryId = 'reading',
  RoutineType routineType = RoutineType.fixedTime,
  GoalType goalType = GoalType.quantity,
  double? targetValue = 20,
  int startTimeMinutes = 600,
  int endTimeMinutes = 660,
  Set<int> repeatDays = const {1, 2, 3},
  int fullDurationMinutes = 60,
  int mediumDurationMinutes = 30,
  int miniDurationMinutes = 10,
}) {
  return RoutineFormData(
    title: title,
    categoryId: categoryId,
    routineType: routineType,
    goalType: goalType,
    targetValue: targetValue,
    targetUnit: 'pages',
    priority: PriorityLevel.medium,
    difficulty: DifficultyLevel.normal,
    startTimeMinutes: startTimeMinutes,
    endTimeMinutes: endTimeMinutes,
    repeatDays: repeatDays,
    fullDurationMinutes: fullDurationMinutes,
    mediumDurationMinutes: mediumDurationMinutes,
    miniDurationMinutes: miniDurationMinutes,
    reminderEnabled: true,
    timezone: 'Asia/Dhaka',
  );
}

class _FakeRoutineNotificationScheduler
    implements RoutineNotificationScheduler {
  final scheduled = <RoutineReminderSchedule>[];
  final cancelled = <String>[];

  @override
  Future<void> cancelRoutineReminders(String routineId) async {
    cancelled.add(routineId);
  }

  @override
  Future<void> cancelAllRoutineReminders() async {}

  @override
  Future<void> cancelRemainingTodayReminders(
    String routineId, {
    DateTime? now,
  }) async {}

  @override
  Future<void> cancelRoutineReminderType(
    String routineId,
    RoutineReminderType type, {
    DateTime? now,
  }) async {}

  @override
  Future<void> initializeAndReschedule() async {}

  @override
  Future<void> scheduleRoutineReminders(RoutineReminderSchedule routine) async {
    scheduled.add(routine);
  }
}
