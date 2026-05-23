import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/utils/score_calculator.dart';

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
    expect(score.completionScore, 0);
    expect(score.onTimeScore, 0);
    expect(score.focusScore, 0);
    expect(score.recoveryScore, 0);
    expect(score.balanceScore, 0);
  });

  test('does not award recovery points without a recovery opportunity', () {
    const calculator = ScoreCalculator();

    final score = calculator.calculate(
      const DailyScoreInput(
        plannedRoutineCount: 1,
        completedRoutineCount: 1,
        startedOnTimeCount: 0,
        plannedFocusMinutes: 0,
        actualFocusMinutes: 0,
        recoveredRoutineCount: 0,
        recoveryOpportunityCount: 0,
        plannedCategoryCount: 1,
        completedCategoryCount: 1,
      ),
    );

    expect(score.recoveryScore, 0);
  });

  test('awards recovery points only for recovered routines', () {
    const calculator = ScoreCalculator();

    final noRecovery = calculator.calculate(
      const DailyScoreInput(
        plannedRoutineCount: 2,
        completedRoutineCount: 1,
        startedOnTimeCount: 0,
        plannedFocusMinutes: 0,
        actualFocusMinutes: 0,
        recoveredRoutineCount: 0,
        recoveryOpportunityCount: 2,
        plannedCategoryCount: 1,
        completedCategoryCount: 1,
      ),
    );
    final partialRecovery = calculator.calculate(
      const DailyScoreInput(
        plannedRoutineCount: 2,
        completedRoutineCount: 1,
        startedOnTimeCount: 0,
        plannedFocusMinutes: 0,
        actualFocusMinutes: 0,
        recoveredRoutineCount: 1,
        recoveryOpportunityCount: 2,
        plannedCategoryCount: 1,
        completedCategoryCount: 1,
      ),
    );

    expect(noRecovery.recoveryScore, 0);
    expect(partialRecovery.recoveryScore, 5);
  });
}
