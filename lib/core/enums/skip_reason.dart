enum SkipReason {
  tooTired,
  busy,
  forgot,
  badTiming,
  notInterested,
  emergency,
  overplanned,
  other;

  String get label => switch (this) {
    SkipReason.tooTired => 'Too tired',
    SkipReason.busy => 'Busy',
    SkipReason.forgot => 'Forgot',
    SkipReason.badTiming => 'Bad timing',
    SkipReason.notInterested => 'Not interested',
    SkipReason.emergency => 'Emergency',
    SkipReason.overplanned => 'Overplanned',
    SkipReason.other => 'Other',
  };
}
