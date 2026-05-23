class SmartCoachEngine {
  const SmartCoachEngine();

  List<SmartCoachInsight> generate(SmartCoachContext context) {
    final insights = <SmartCoachInsight>[
      ?_overplanningInsight(context),
      ?_badTimeInsight(context),
      ?_weakCategoryInsight(context),
      ..._recoveryInsights(context),
      ?_goodStreakInsight(context),
    ];

    insights.sort((left, right) {
      return _severityRank(
        right.severity,
      ).compareTo(_severityRank(left.severity));
    });
    return insights;
  }

  SmartCoachInsight? _overplanningInsight(SmartCoachContext context) {
    if (context.averageCompletedMinutes <= 0) return null;
    if (context.plannedMinutesToday <= context.averageCompletedMinutes * 1.5) {
      return null;
    }

    return SmartCoachInsight(
      id: 'overplanning',
      title: 'Today may be overloaded',
      message:
          'You planned ${context.plannedMinutesToday} minutes today, but your recent average completed time is ${context.averageCompletedMinutes} minutes.',
      severity: SmartCoachSeverity.warning,
      category: SmartCoachCategory.overplanning,
      actionLabel: 'Trim today',
      createdAt: context.generatedAt,
    );
  }

  SmartCoachInsight? _badTimeInsight(SmartCoachContext context) {
    final rate = context.lateNightCompletionRate;
    if (context.lateNightPlannedCount < 2 || rate == null || rate >= 0.4) {
      return null;
    }

    return SmartCoachInsight(
      id: 'late-night-timing',
      title: 'Late-night routines look fragile',
      message:
          'Your routines after 10 PM are completed only ${(rate * 100).round()}% of the time. Move important work earlier.',
      severity: SmartCoachSeverity.warning,
      category: SmartCoachCategory.timing,
      actionLabel: 'Move earlier',
      createdAt: context.generatedAt,
    );
  }

  SmartCoachInsight? _weakCategoryInsight(SmartCoachContext context) {
    if (context.weakCategories.isEmpty) return null;
    final category = context.weakCategories.first;

    return SmartCoachInsight(
      id: 'weak-category-${category.categoryId}',
      title: '${category.categoryName} needs a smaller target',
      message:
          '${category.categoryName} completion is ${(category.completionRate * 100).round()}% this week. Try a mini version or shorter block.',
      severity: SmartCoachSeverity.warning,
      category: SmartCoachCategory.categoryBalance,
      actionLabel: 'Make smaller',
      createdAt: context.generatedAt,
    );
  }

  List<SmartCoachInsight> _recoveryInsights(SmartCoachContext context) {
    return [
      for (final routine in context.missedRecoverableRoutines.take(3))
        SmartCoachInsight(
          id: 'recovery-${routine.routineId}',
          title: 'Recover ${routine.title}',
          message:
              'You missed ${routine.title}. Try the ${routine.miniDurationMinutes}-minute mini version today.',
          severity: SmartCoachSeverity.info,
          category: SmartCoachCategory.recovery,
          actionLabel: 'Try mini',
          createdAt: context.generatedAt,
        ),
    ];
  }

  SmartCoachInsight? _goodStreakInsight(SmartCoachContext context) {
    if (context.streaks.isEmpty) return null;
    final streak = context.streaks.first;

    return SmartCoachInsight(
      id: 'streak-${streak.routineId}',
      title: '${streak.title} is building consistency',
      message:
          'You completed ${streak.title} ${streak.dayCount} days in a row. Keep the streak alive.',
      severity: SmartCoachSeverity.success,
      category: SmartCoachCategory.routineHealth,
      actionLabel: 'Keep going',
      createdAt: context.generatedAt,
    );
  }

  int _severityRank(SmartCoachSeverity severity) {
    return switch (severity) {
      SmartCoachSeverity.warning => 3,
      SmartCoachSeverity.success => 2,
      SmartCoachSeverity.info => 1,
    };
  }
}

class SmartCoachContext {
  const SmartCoachContext({
    required this.generatedAt,
    required this.plannedMinutesToday,
    required this.averageCompletedMinutes,
    required this.lateNightPlannedCount,
    required this.lateNightCompletionRate,
    required this.weakCategories,
    required this.missedRecoverableRoutines,
    required this.streaks,
  });

  final DateTime generatedAt;
  final int plannedMinutesToday;
  final int averageCompletedMinutes;
  final int lateNightPlannedCount;
  final double? lateNightCompletionRate;
  final List<WeakCategorySignal> weakCategories;
  final List<RecoverableRoutineSignal> missedRecoverableRoutines;
  final List<RoutineStreakSignal> streaks;

  bool get hasEnoughData {
    return averageCompletedMinutes > 0 ||
        lateNightPlannedCount > 0 ||
        weakCategories.isNotEmpty ||
        missedRecoverableRoutines.isNotEmpty ||
        streaks.isNotEmpty;
  }
}

class SmartCoachInsight {
  const SmartCoachInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.category,
    required this.actionLabel,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final SmartCoachSeverity severity;
  final SmartCoachCategory category;
  final String actionLabel;
  final DateTime createdAt;
}

enum SmartCoachSeverity { info, warning, success }

enum SmartCoachCategory {
  overplanning,
  routineHealth,
  recovery,
  timing,
  categoryBalance,
}

class WeakCategorySignal {
  const WeakCategorySignal({
    required this.categoryId,
    required this.categoryName,
    required this.completionRate,
  });

  final String categoryId;
  final String categoryName;
  final double completionRate;
}

class RecoverableRoutineSignal {
  const RecoverableRoutineSignal({
    required this.routineId,
    required this.title,
    required this.miniDurationMinutes,
  });

  final String routineId;
  final String title;
  final int miniDurationMinutes;
}

class RoutineStreakSignal {
  const RoutineStreakSignal({
    required this.routineId,
    required this.title,
    required this.dayCount,
  });

  final String routineId;
  final String title;
  final int dayCount;
}
