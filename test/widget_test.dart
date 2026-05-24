import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routine_os/app/app.dart';
import 'package:routine_os/core/notifications/notification_providers.dart';
import 'package:routine_os/core/notifications/notification_scheduler.dart';
import 'package:routine_os/features/today/application/today_providers.dart';
import 'package:routine_os/features/today/data/today_repository.dart';

void main() {
  testWidgets('RoutineOS app shell renders the today screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationSchedulerProvider.overrideWithValue(
            const _NoopRoutineNotificationScheduler(),
          ),
          todayTimelineProvider.overrideWith(
            (ref) async => TodayTimeline(
              date: DateTime(2026),
              entries: const [],
              dailyScore: null,
            ),
          ),
        ],
        child: const RoutineOSApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('RoutineOS'), findsOneWidget);
    expect(find.text('Daily progress'), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    expect(find.text('Add activity'), findsWidgets);
    expect(find.text('Current routine'), findsNothing);
  });

  test('major screen labels use Activity wording', () {
    final files = [
      'lib/features/today/presentation/today_screen.dart',
      'lib/features/routines/presentation/routine_list_screen.dart',
      'lib/features/routines/presentation/routine_form_screen.dart',
      'lib/features/routines/presentation/routine_detail_screen.dart',
    ];
    final bannedLabels = [
      'Create Routine',
      'Create routine',
      'Routine List',
      'Routine Detail',
      'Routine Health Score',
      'Current routine',
      'Next routine',
      'No routines planned for today',
    ];

    for (final path in files) {
      final source = File(path).readAsStringSync();
      for (final label in bannedLabels) {
        expect(source.contains(label), isFalse, reason: '$path has $label');
      }
    }
  });
}

class _NoopRoutineNotificationScheduler
    implements RoutineNotificationScheduler {
  const _NoopRoutineNotificationScheduler();

  @override
  Future<void> cancelRoutineReminders(String routineId) async {}

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
  Future<void> scheduleRoutineReminders(
    RoutineReminderSchedule routine,
  ) async {}
}
