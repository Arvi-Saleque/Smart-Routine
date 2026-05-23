import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';
import 'package:routine_os/core/enums/difficulty_level.dart';
import 'package:routine_os/core/enums/goal_type.dart';
import 'package:routine_os/core/enums/priority_level.dart';
import 'package:routine_os/core/enums/routine_type.dart';
import 'package:routine_os/core/notifications/notification_scheduler.dart';
import 'package:routine_os/core/notifications/notification_settings.dart';
import 'package:routine_os/features/routines/data/routine_repository.dart';
import 'package:routine_os/features/settings/application/settings_providers.dart';
import 'package:routine_os/features/settings/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('settings persist in SharedPreferences', () async {
    final repository = SettingsRepository();
    addTearDown(repository.dispose);

    await repository.setThemeMode(ThemeMode.dark);
    await repository.setReminderSettings(
      const ReminderSettings(
        remindersEnabled: false,
        defaultPreparationReminderMinutes: 15,
        defaultLateReminderMinutes: 20,
      ),
    );
    await repository.setStartOfWeek(StartOfWeek.sunday);

    final nextRepository = SettingsRepository();
    addTearDown(nextRepository.dispose);

    expect(await nextRepository.themeMode(), ThemeMode.dark);
    expect(await nextRepository.startOfWeek(), StartOfWeek.sunday);

    final reminders = await nextRepository.reminderSettings();
    expect(reminders.remindersEnabled, isFalse);
    expect(reminders.defaultPreparationReminderMinutes, 15);
    expect(reminders.defaultLateReminderMinutes, 20);
  });

  test('theme mode provider returns selected value', () async {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettingsRepository(themeMode: ThemeMode.light),
        ),
      ],
    );
    addTearDown(container.dispose);

    final completer = Completer<ThemeMode>();
    final subscription = container.listen<AsyncValue<ThemeMode>>(
      themeModeProvider,
      (_, next) {
        if (next.hasValue && !completer.isCompleted) {
          completer.complete(next.requireValue);
        }
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    expect(
      await completer.future.timeout(const Duration(seconds: 1)),
      ThemeMode.light,
    );
  });

  test(
    'clear data removes user routine data but preserves default categories',
    () async {
      final repository = SettingsRepository();
      final database = AppDatabase(NativeDatabase.memory());
      final scheduler = _FakeRoutineNotificationScheduler();
      final routineRepository = RoutineRepository(database);
      addTearDown(repository.dispose);
      addTearDown(database.close);

      await repository.setThemeMode(ThemeMode.dark);
      await repository.setReminderSettings(
        const ReminderSettings(
          remindersEnabled: false,
          defaultPreparationReminderMinutes: 5,
          defaultLateReminderMinutes: 12,
        ),
      );
      await routineRepository.createRoutine(
        const RoutineFormData(
          title: 'Temporary routine',
          categoryId: 'reading',
          routineType: RoutineType.fixedTime,
          goalType: GoalType.duration,
          targetValue: 30,
          targetUnit: 'minutes',
          priority: PriorityLevel.medium,
          difficulty: DifficultyLevel.normal,
          startTimeMinutes: 600,
          endTimeMinutes: 660,
          repeatDays: {1, 2, 3},
          fullDurationMinutes: 60,
          mediumDurationMinutes: 30,
          miniDurationMinutes: 10,
          reminderEnabled: true,
          timezone: 'Asia/Dhaka',
        ),
      );

      expect(await database.select(database.routines).get(), hasLength(1));
      expect(
        await database.select(database.routineSchedules).get(),
        hasLength(1),
      );

      await repository.clearAllData(database: database, scheduler: scheduler);

      expect(scheduler.cancelAllCalls, 1);
      expect(await database.select(database.routines).get(), isEmpty);
      expect(await database.select(database.routineSchedules).get(), isEmpty);
      expect(await database.select(database.routineLogs).get(), isEmpty);
      expect(await database.select(database.focusSessions).get(), isEmpty);
      expect(await database.select(database.reminders).get(), isEmpty);
      expect(await database.select(database.dailyScores).get(), isEmpty);
      expect(await database.select(database.categories).get(), isNotEmpty);
      expect(await repository.themeMode(), ThemeMode.dark);

      final reminders = await repository.reminderSettings();
      expect(reminders.remindersEnabled, isFalse);
      expect(reminders.defaultPreparationReminderMinutes, 5);
      expect(reminders.defaultLateReminderMinutes, 12);
    },
  );
}

class _FakeSettingsRepository extends SettingsRepository {
  _FakeSettingsRepository({required ThemeMode themeMode})
    : _themeMode = themeMode;

  final ThemeMode _themeMode;

  @override
  Stream<ThemeMode> watchThemeMode() {
    return Stream.value(_themeMode);
  }

  @override
  void dispose() {}
}

class _FakeRoutineNotificationScheduler
    implements RoutineNotificationScheduler {
  int cancelAllCalls = 0;

  @override
  Future<void> cancelAllRoutineReminders() async {
    cancelAllCalls++;
  }

  @override
  Future<void> cancelRoutineReminders(String routineId) async {}

  @override
  Future<void> initializeAndReschedule() async {}

  @override
  Future<void> scheduleRoutineReminders(
    RoutineReminderSchedule routine,
  ) async {}
}
