enum GoalType {
  simpleCheck,
  duration,
  count,
  quantity;

  String get label => switch (this) {
    GoalType.simpleCheck => 'Just mark as done',
    GoalType.duration => 'Track time',
    GoalType.count => 'Track count',
    GoalType.quantity => 'Track quantity',
  };
}
