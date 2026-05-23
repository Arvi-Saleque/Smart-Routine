import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds default categories once', () async {
    final firstSeed = await database.select(database.categories).get();

    expect(firstSeed, hasLength(10));
    expect(firstSeed.map((category) => category.id), contains('reading'));
    expect(firstSeed.map((category) => category.id), contains('coding'));

    await database.seedDefaultCategories();
    final secondSeed = await database.select(database.categories).get();

    expect(secondSeed, hasLength(10));
  });

  test('clears user data while preserving default categories', () async {
    final now = DateTime(2026, 5, 24);
    await database
        .into(database.routines)
        .insert(
          RoutinesCompanion.insert(
            id: 'routine-1',
            title: 'Reading',
            categoryId: 'reading',
            routineType: 'fixedTime',
            goalType: 'duration',
            targetValue: const Value(30),
            targetUnit: const Value('minutes'),
            priority: 'medium',
            difficulty: 'normal',
            fullDurationMinutes: 30,
            mediumDurationMinutes: 20,
            miniDurationMinutes: 5,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.routineSchedules)
        .insert(
          RoutineSchedulesCompanion.insert(
            id: 'schedule-1',
            routineId: 'routine-1',
            startTimeMinutes: 600,
            endTimeMinutes: 630,
            repeatDays: '1',
            timezone: 'Asia/Dhaka',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.routineLogs)
        .insert(
          RoutineLogsCompanion.insert(
            id: 'log-1',
            routineId: 'routine-1',
            date: '2026-05-24',
            status: 'completed',
            plannedStartTimeMinutes: 600,
            plannedEndTimeMinutes: 630,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await database.clearUserData();

    expect(await database.select(database.routines).get(), isEmpty);
    expect(await database.select(database.routineLogs).get(), isEmpty);
    expect(await database.select(database.categories).get(), hasLength(10));
  });
}
