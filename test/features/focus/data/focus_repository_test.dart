import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';
import 'package:routine_os/core/enums/difficulty_level.dart';
import 'package:routine_os/core/enums/goal_type.dart';
import 'package:routine_os/core/enums/priority_level.dart';
import 'package:routine_os/core/enums/routine_status.dart';
import 'package:routine_os/core/enums/routine_type.dart';
import 'package:routine_os/core/notifications/notification_scheduler.dart';
import 'package:routine_os/core/utils/date_time_utils.dart';
import 'package:routine_os/features/focus/data/focus_repository.dart';
import 'package:routine_os/features/routines/data/routine_repository.dart';

void main() {
  late AppDatabase database;
  late RoutineRepository routineRepository;
  late FocusRepository focusRepository;
  late _FakeRoutineNotificationScheduler scheduler;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    scheduler = _FakeRoutineNotificationScheduler();
    routineRepository = RoutineRepository(database);
    focusRepository = FocusRepository(
      database,
      notificationScheduler: scheduler,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('saves focus session and completed routine log', () async {
    final routineId = await routineRepository.createRoutine(
      const RoutineFormData(
        title: 'Coding practice',
        categoryId: 'coding',
        routineType: RoutineType.fixedTime,
        goalType: GoalType.duration,
        targetValue: 45,
        targetUnit: 'minutes',
        priority: PriorityLevel.high,
        difficulty: DifficultyLevel.hard,
        startTimeMinutes: 1200,
        endTimeMinutes: 1260,
        repeatDays: {1, 2, 3, 4, 5, 6, 7},
        fullDurationMinutes: 60,
        mediumDurationMinutes: 30,
        miniDurationMinutes: 10,
        reminderEnabled: true,
        timezone: 'Asia/Dhaka',
      ),
    );
    final detail = await routineRepository.getRoutineDetail(routineId);
    final startedAt = DateTime(2026, 5, 18, 20);
    final endedAt = DateTime(2026, 5, 18, 20, 42);

    final result = await focusRepository.finishSession(
      FocusSessionDraft(
        routineDetail: detail!,
        startedAt: startedAt,
        endedAt: endedAt,
        actualDuration: const Duration(minutes: 42),
        plannedDurationMinutes: 60,
        distractionCount: 2,
        note: 'Solved dynamic programming problems.',
      ),
    );

    final sessions = await database.select(database.focusSessions).get();
    expect(sessions, hasLength(1));
    expect(sessions.single.id, result.focusSessionId);
    expect(sessions.single.routineLogId, result.routineLogId);
    expect(sessions.single.actualDurationMinutes, 42);
    expect(sessions.single.distractionCount, 2);

    final logs = await database.select(database.routineLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.status, RoutineStatus.completed.name);
    expect(logs.single.date, DateTimeUtils.dateKey(startedAt));
    expect(logs.single.actualDurationMinutes, 42);
    expect(logs.single.completionValue, 42);
    expect(logs.single.note, 'Solved dynamic programming problems.');

    final scores = await database.select(database.dailyScores).get();
    expect(scores, hasLength(1));
    expect(scores.single.focusScore, 14);
  });

  test('can save a mini recovery session as recovered', () async {
    final routineId = await routineRepository.createRoutine(
      const RoutineFormData(
        title: 'Prayer recovery',
        categoryId: 'spiritual',
        routineType: RoutineType.fixedTime,
        goalType: GoalType.duration,
        targetValue: 10,
        targetUnit: 'minutes',
        priority: PriorityLevel.high,
        difficulty: DifficultyLevel.easy,
        startTimeMinutes: 300,
        endTimeMinutes: 330,
        repeatDays: {1, 2, 3, 4, 5, 6, 7},
        fullDurationMinutes: 30,
        mediumDurationMinutes: 15,
        miniDurationMinutes: 5,
        reminderEnabled: true,
        timezone: 'Asia/Dhaka',
      ),
    );
    final detail = await routineRepository.getRoutineDetail(routineId);
    final startedAt = DateTime(2026, 5, 18, 22);

    await focusRepository.finishSession(
      FocusSessionDraft(
        routineDetail: detail!,
        startedAt: startedAt,
        endedAt: DateTime(2026, 5, 18, 22, 5),
        actualDuration: const Duration(minutes: 5),
        plannedDurationMinutes: 5,
        distractionCount: 0,
        note: 'Mini recovery done.',
        completionStatus: RoutineStatus.recovered,
      ),
    );

    final logs = await database.select(database.routineLogs).get();
    expect(logs.single.status, RoutineStatus.recovered.name);
    expect(logs.single.actualDurationMinutes, 5);
    expect(logs.single.note, 'Mini recovery done.');

    final scores = await database.select(database.dailyScores).get();
    expect(scores.single.recoveryScore, 10);
  });

  test('finishSession triggers current-day reminder cancellation', () async {
    final routineId = await routineRepository.createRoutine(
      const RoutineFormData(
        title: 'Cancellation focus',
        categoryId: 'coding',
        routineType: RoutineType.fixedTime,
        goalType: GoalType.duration,
        targetValue: 45,
        targetUnit: 'minutes',
        priority: PriorityLevel.high,
        difficulty: DifficultyLevel.hard,
        startTimeMinutes: 1200,
        endTimeMinutes: 1260,
        repeatDays: {1, 2, 3, 4, 5, 6, 7},
        fullDurationMinutes: 60,
        mediumDurationMinutes: 30,
        miniDurationMinutes: 10,
        reminderEnabled: true,
        timezone: 'Asia/Dhaka',
      ),
    );
    final detail = await routineRepository.getRoutineDetail(routineId);
    final startedAt = DateTime(2026, 5, 18, 20);

    await focusRepository.finishSession(
      FocusSessionDraft(
        routineDetail: detail!,
        startedAt: startedAt,
        endedAt: DateTime(2026, 5, 18, 20, 42),
        actualDuration: const Duration(minutes: 42),
        plannedDurationMinutes: 60,
        distractionCount: 0,
        note: '',
      ),
    );

    expect(scheduler.cancelledRemaining, hasLength(1));
    expect(scheduler.cancelledRemaining.single.routineId, routineId);
    expect(
      scheduler.cancelledRemaining.single.dateKey,
      DateTimeUtils.dateKey(startedAt),
    );
  });

  test('startSession triggers current-day reminder cancellation', () async {
    final routineId = await routineRepository.createRoutine(
      const RoutineFormData(
        title: 'Start cancellation',
        categoryId: 'coding',
        routineType: RoutineType.fixedTime,
        goalType: GoalType.duration,
        targetValue: 45,
        targetUnit: 'minutes',
        priority: PriorityLevel.high,
        difficulty: DifficultyLevel.hard,
        startTimeMinutes: 1200,
        endTimeMinutes: 1260,
        repeatDays: {1, 2, 3, 4, 5, 6, 7},
        fullDurationMinutes: 60,
        mediumDurationMinutes: 30,
        miniDurationMinutes: 10,
        reminderEnabled: true,
        timezone: 'Asia/Dhaka',
      ),
    );
    final detail = await routineRepository.getRoutineDetail(routineId);
    final startedAt = DateTime(2026, 5, 18, 20);

    await focusRepository.startSession(detail!, startedAt: startedAt);

    expect(scheduler.cancelledRemaining, hasLength(1));
    expect(scheduler.cancelledRemaining.single.routineId, routineId);
    expect(
      scheduler.cancelledRemaining.single.dateKey,
      DateTimeUtils.dateKey(startedAt),
    );
  });
}

class _FakeRoutineNotificationScheduler
    implements RoutineNotificationScheduler {
  final cancelledRemaining = <_CancellationCall>[];

  @override
  Future<void> cancelAllRoutineReminders() async {}

  @override
  Future<void> cancelRemainingTodayReminders(
    String routineId, {
    DateTime? now,
  }) async {
    cancelledRemaining.add(
      _CancellationCall(
        routineId,
        now == null ? null : DateTimeUtils.dateKey(now),
      ),
    );
  }

  @override
  Future<void> cancelRoutineReminderType(
    String routineId,
    RoutineReminderType type, {
    DateTime? now,
  }) async {}

  @override
  Future<void> cancelRoutineReminders(String routineId) async {}

  @override
  Future<void> initializeAndReschedule() async {}

  @override
  Future<void> scheduleRoutineReminders(
    RoutineReminderSchedule routine,
  ) async {}
}

class _CancellationCall {
  const _CancellationCall(this.routineId, this.dateKey);

  final String routineId;
  final String? dateKey;
}
