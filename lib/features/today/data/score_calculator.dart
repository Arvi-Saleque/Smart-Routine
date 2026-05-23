class ScoreCalculator {
  const ScoreCalculator();

  DailyScoreBreakdown calculate(DailyScoreInput input) {
    if (input.plannedRoutineCount <= 0) {
      return const DailyScoreBreakdown.empty();
    }

    final completionScore = _ratioScore(
      numerator: input.completedRoutineCount,
      denominator: input.plannedRoutineCount,
      maxScore: 40,
    );
    final onTimeScore = _ratioScore(
      numerator: input.startedOnTimeCount,
      denominator: input.completedRoutineCount,
      maxScore: 20,
    );
    final focusScore = _ratioScore(
      numerator: input.actualFocusMinutes,
      denominator: input.plannedFocusMinutes,
      maxScore: 20,
    );
    final recoveryScore = input.recoveryOpportunityCount == 0
        ? 10
        : _ratioScore(
            numerator: input.recoveredRoutineCount,
            denominator: input.recoveryOpportunityCount,
            maxScore: 10,
          );
    final balanceScore = _ratioScore(
      numerator: input.completedCategoryCount,
      denominator: input.plannedCategoryCount,
      maxScore: 10,
    );

    final total =
        completionScore +
        onTimeScore +
        focusScore +
        recoveryScore +
        balanceScore;

    return DailyScoreBreakdown(
      score: total.clamp(0, 100),
      completionScore: completionScore,
      onTimeScore: onTimeScore,
      focusScore: focusScore,
      recoveryScore: recoveryScore,
      balanceScore: balanceScore,
    );
  }

  int _ratioScore({
    required int numerator,
    required int denominator,
    required int maxScore,
  }) {
    if (denominator <= 0 || numerator <= 0) return 0;
    return ((numerator / denominator).clamp(0.0, 1.0) * maxScore).round();
  }
}

class DailyScoreInput {
  const DailyScoreInput({
    required this.plannedRoutineCount,
    required this.completedRoutineCount,
    required this.startedOnTimeCount,
    required this.plannedFocusMinutes,
    required this.actualFocusMinutes,
    required this.recoveredRoutineCount,
    required this.recoveryOpportunityCount,
    required this.plannedCategoryCount,
    required this.completedCategoryCount,
  });

  final int plannedRoutineCount;
  final int completedRoutineCount;
  final int startedOnTimeCount;
  final int plannedFocusMinutes;
  final int actualFocusMinutes;
  final int recoveredRoutineCount;
  final int recoveryOpportunityCount;
  final int plannedCategoryCount;
  final int completedCategoryCount;
}

class DailyScoreBreakdown {
  const DailyScoreBreakdown({
    required this.score,
    required this.completionScore,
    required this.onTimeScore,
    required this.focusScore,
    required this.recoveryScore,
    required this.balanceScore,
  });

  const DailyScoreBreakdown.empty()
    : score = 0,
      completionScore = 0,
      onTimeScore = 0,
      focusScore = 0,
      recoveryScore = 0,
      balanceScore = 0;

  final int score;
  final int completionScore;
  final int onTimeScore;
  final int focusScore;
  final int recoveryScore;
  final int balanceScore;
}
