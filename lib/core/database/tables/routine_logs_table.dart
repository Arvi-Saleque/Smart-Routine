import 'package:drift/drift.dart';

import 'routines_table.dart';

class RoutineLogs extends Table {
  @override
  String get tableName => 'routine_logs';

  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get date => text()();
  TextColumn get status => text()();
  IntColumn get plannedStartTimeMinutes => integer()();
  IntColumn get plannedEndTimeMinutes => integer()();
  DateTimeColumn get actualStartAt => dateTime().nullable()();
  DateTimeColumn get actualEndAt => dateTime().nullable()();
  IntColumn get actualDurationMinutes => integer().nullable()();
  RealColumn get completionValue => real().nullable()();
  TextColumn get mood => text().nullable()();
  TextColumn get difficultyFeedback => text().nullable()();
  TextColumn get skipReason => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
