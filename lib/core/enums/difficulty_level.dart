enum DifficultyLevel {
  easy,
  normal,
  hard;

  String get label => switch (this) {
    DifficultyLevel.easy => 'Easy',
    DifficultyLevel.normal => 'Normal',
    DifficultyLevel.hard => 'Hard',
  };
}
