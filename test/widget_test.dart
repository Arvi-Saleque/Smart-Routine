import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:routine_os/app/app.dart';

void main() {
  testWidgets('RoutineOS app shell renders the today screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RoutineOSApp()));
    await tester.pumpAndSettle();

    expect(find.text('RoutineOS'), findsOneWidget);
    expect(find.text('Daily score'), findsOneWidget);
    expect(find.text('Current routine'), findsOneWidget);
  });
}
