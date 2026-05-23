enum GoalType {
  simpleCheck,
  duration,
  count,
  quantity;

  String get label => switch (this) {
    GoalType.simpleCheck => 'Simple check',
    GoalType.duration => 'Duration',
    GoalType.count => 'Count',
    GoalType.quantity => 'Quantity',
  };
}
