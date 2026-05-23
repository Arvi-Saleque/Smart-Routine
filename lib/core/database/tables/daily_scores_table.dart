import 'package:drift/drift.dart';

class DailyScores extends Table {
  @override
  String get tableName => 'daily_scores';

  TextColumn get id => text()();
  TextColumn get date => text()();
  IntColumn get score => integer()();
  IntColumn get completionScore => integer()();
  IntColumn get onTimeScore => integer()();
  IntColumn get focusScore => integer()();
  IntColumn get recoveryScore => integer()();
  IntColumn get balanceScore => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
