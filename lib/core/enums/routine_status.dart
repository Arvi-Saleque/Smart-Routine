enum RoutineStatus {
  upcoming,
  active,
  started,
  completed,
  skipped,
  missed,
  rescheduled,
  recovered;

  String get label => switch (this) {
    RoutineStatus.upcoming => 'Upcoming',
    RoutineStatus.active => 'Active',
    RoutineStatus.started => 'Started',
    RoutineStatus.completed => 'Completed',
    RoutineStatus.skipped => 'Skipped',
    RoutineStatus.missed => 'Missed',
    RoutineStatus.rescheduled => 'Rescheduled',
    RoutineStatus.recovered => 'Recovered',
  };
}
