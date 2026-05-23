import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/categories_table.dart';
import 'tables/daily_scores_table.dart';
import 'tables/focus_sessions_table.dart';
import 'tables/reminders_table.dart';
import 'tables/routine_logs_table.dart';
import 'tables/routine_schedules_table.dart';
import 'tables/routines_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Categories,
    Routines,
    RoutineSchedules,
    RoutineLogs,
    FocusSessions,
    Reminders,
    DailyScores,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await seedDefaultCategories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await seedDefaultCategories();
    },
  );

  Future<void> seedDefaultCategories() async {
    final now = DateTime.now();

    await batch((batch) {
      batch.insertAllOnConflictUpdate(categories, [
        _category(
          id: 'reading',
          name: 'Reading',
          iconName: 'menu_book',
          colorValue: 0xFF2563EB,
          weeklyTargetMinutes: 300,
          timestamp: now,
        ),
        _category(
          id: 'coding',
          name: 'Coding',
          iconName: 'code',
          colorValue: 0xFF7C3AED,
          weeklyTargetMinutes: 600,
          timestamp: now,
        ),
        _category(
          id: 'work',
          name: 'Work',
          iconName: 'work',
          colorValue: 0xFF4F46E5,
          weeklyTargetMinutes: 900,
          timestamp: now,
        ),
        _category(
          id: 'study',
          name: 'Study',
          iconName: 'school',
          colorValue: 0xFF0F766E,
          weeklyTargetMinutes: 600,
          timestamp: now,
        ),
        _category(
          id: 'health',
          name: 'Health',
          iconName: 'fitness_center',
          colorValue: 0xFF16A34A,
          weeklyTargetMinutes: 300,
          timestamp: now,
        ),
        _category(
          id: 'spiritual',
          name: 'Spiritual',
          iconName: 'self_improvement',
          colorValue: 0xFFD97706,
          weeklyTargetMinutes: 240,
          timestamp: now,
        ),
        _category(
          id: 'skill',
          name: 'Skill',
          iconName: 'psychology',
          colorValue: 0xFF0891B2,
          weeklyTargetMinutes: 300,
          timestamp: now,
        ),
        _category(
          id: 'break',
          name: 'Break',
          iconName: 'coffee',
          colorValue: 0xFFEA580C,
          weeklyTargetMinutes: 420,
          timestamp: now,
        ),
        _category(
          id: 'planning',
          name: 'Planning',
          iconName: 'event_note',
          colorValue: 0xFFDB2777,
          weeklyTargetMinutes: 120,
          timestamp: now,
        ),
        _category(
          id: 'personal',
          name: 'Personal',
          iconName: 'home',
          colorValue: 0xFF92400E,
          weeklyTargetMinutes: 300,
          timestamp: now,
        ),
      ]);
    });
  }

  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(reminders).go();
      await delete(focusSessions).go();
      await delete(routineLogs).go();
      await delete(dailyScores).go();
      await delete(routineSchedules).go();
      await delete(routines).go();
      await seedDefaultCategories();
    });
  }

  static CategoriesCompanion _category({
    required String id,
    required String name,
    required String iconName,
    required int colorValue,
    required int weeklyTargetMinutes,
    required DateTime timestamp,
  }) {
    return CategoriesCompanion.insert(
      id: id,
      name: name,
      iconName: iconName,
      colorValue: colorValue,
      weeklyTargetMinutes: weeklyTargetMinutes,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final file = File(p.join(documentsDirectory.path, 'routine_os.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
