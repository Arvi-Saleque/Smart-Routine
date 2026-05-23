import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/features/coach/application/smart_coach_engine.dart';

void main() {
  test('generates expected rule-based insights', () {
    const engine = SmartCoachEngine();
    final insights = engine.generate(
      SmartCoachContext(
        generatedAt: DateTime(2026, 5, 24, 12),
        plannedMinutesToday: 240,
        averageCompletedMinutes: 100,
        lateNightPlannedCount: 3,
        lateNightCompletionRate: 0.33,
        weakCategories: const [
          WeakCategorySignal(
            categoryId: 'reading',
            categoryName: 'Reading',
            completionRate: 0.25,
          ),
        ],
        missedRecoverableRoutines: const [
          RecoverableRoutineSignal(
            routineId: 'r1',
            title: 'Bangla reading',
            miniDurationMinutes: 10,
          ),
        ],
        streaks: const [
          RoutineStreakSignal(routineId: 'r2', title: 'Prayer', dayCount: 4),
        ],
      ),
    );

    expect(insights.map((insight) => insight.id), contains('overplanning'));
    expect(
      insights.map((insight) => insight.category),
      containsAll([
        SmartCoachCategory.timing,
        SmartCoachCategory.categoryBalance,
        SmartCoachCategory.recovery,
        SmartCoachCategory.routineHealth,
      ]),
    );
    expect(insights.first.severity, SmartCoachSeverity.warning);
  });
}
