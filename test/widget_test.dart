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
    expect(find.text('Current routine'), findsOneWidget);
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
  Future<void> initializeAndReschedule() async {}

  @override
  Future<void> scheduleRoutineReminders(
    RoutineReminderSchedule routine,
  ) async {}
}
