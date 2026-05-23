enum PriorityLevel {
  low,
  medium,
  high;

  String get label => switch (this) {
    PriorityLevel.low => 'Low',
    PriorityLevel.medium => 'Medium',
    PriorityLevel.high => 'High',
  };
}
