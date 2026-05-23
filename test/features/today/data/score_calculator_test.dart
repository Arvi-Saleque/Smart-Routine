import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/features/today/data/score_calculator.dart';

void main() {
  test('calculates weighted daily score breakdown', () {
    const calculator = ScoreCalculator();

    final score = calculator.calculate(
      const DailyScoreInput(
        plannedRoutineCount: 4,
        completedRoutineCount: 2,
        startedOnTimeCount: 1,
        plannedFocusMinutes: 120,
        actualFocusMinutes: 60,
        recoveredRoutineCount: 1,
        recoveryOpportunityCount: 2,
        plannedCategoryCount: 4,
        completedCategoryCount: 2,
      ),
    );

    expect(score.completionScore, 20);
    expect(score.onTimeScore, 10);
    expect(score.focusScore, 10);
    expect(score.recoveryScore, 5);
    expect(score.balanceScore, 5);
    expect(score.score, 50);
  });

  test('returns zero score when no routines are planned', () {
    const calculator = ScoreCalculator();

    final score = calculator.calculate(
      const DailyScoreInput(
        plannedRoutineCount: 0,
        completedRoutineCount: 0,
        startedOnTimeCount: 0,
        plannedFocusMinutes: 0,
        actualFocusMinutes: 0,
        recoveredRoutineCount: 0,
        recoveryOpportunityCount: 0,
        plannedCategoryCount: 0,
        completedCategoryCount: 0,
      ),
    );

    expect(score.score, 0);
  });
}
