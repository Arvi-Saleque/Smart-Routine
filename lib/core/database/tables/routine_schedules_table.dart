import 'package:drift/drift.dart';

import 'routines_table.dart';

class RoutineSchedules extends Table {
  @override
  String get tableName => 'routine_schedules';

  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id)();
  IntColumn get startTimeMinutes => integer()();
  IntColumn get endTimeMinutes => integer()();
  TextColumn get repeatDays => text()();
  TextColumn get specificDate => text().nullable()();
  TextColumn get timezone => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
