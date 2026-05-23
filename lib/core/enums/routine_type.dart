enum RoutineType {
  fixedTime,
  flexible,
  durationBased,
  countBased;

  String get label => switch (this) {
    RoutineType.fixedTime => 'Fixed time',
    RoutineType.flexible => 'Flexible',
    RoutineType.durationBased => 'Duration based',
    RoutineType.countBased => 'Count based',
  };
}
