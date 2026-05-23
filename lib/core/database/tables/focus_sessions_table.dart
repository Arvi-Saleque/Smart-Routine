import 'package:drift/drift.dart';

import 'routine_logs_table.dart';
import 'routines_table.dart';

class FocusSessions extends Table {
  @override
  String get tableName => 'focus_sessions';

  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id)();
  TextColumn get routineLogId =>
      text().nullable().references(RoutineLogs, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get plannedDurationMinutes => integer()();
  IntColumn get actualDurationMinutes => integer()();
  IntColumn get distractionCount => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
