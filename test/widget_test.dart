import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routine_os/app/app.dart';
import 'package:routine_os/features/today/application/today_providers.dart';
import 'package:routine_os/features/today/data/today_repository.dart';

void main() {
  testWidgets('RoutineOS app shell renders the today screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayTimelineProvider.overrideWith(
            (ref) async =>
                TodayTimeline(date: DateTime(2026), entries: const []),
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
