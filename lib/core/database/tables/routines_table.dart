import 'package:drift/drift.dart';

import 'categories_table.dart';

class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get routineType => text()();
  TextColumn get goalType => text()();
  RealColumn get targetValue => real().nullable()();
  TextColumn get targetUnit => text().nullable()();
  TextColumn get priority => text()();
  TextColumn get difficulty => text()();
  IntColumn get fullDurationMinutes => integer()();
  IntColumn get mediumDurationMinutes => integer()();
  IntColumn get miniDurationMinutes => integer()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
