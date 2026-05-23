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
  Future<void> initializeAndReschedule() async {}

  @override
  Future<void> scheduleRoutineReminders(RoutineReminderSchedule routine) async {
    scheduled.add(routine);
  }
}
