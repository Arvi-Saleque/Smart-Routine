import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_os/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds default categories once', () async {
    final firstSeed = await database.select(database.categories).get();

    expect(firstSeed, hasLength(10));
    expect(firstSeed.map((category) => category.id), contains('reading'));
    expect(firstSeed.map((category) => category.id), contains('coding'));

    await database.seedDefaultCategories();
    final secondSeed = await database.select(database.categories).get();

    expect(secondSeed, hasLength(10));
  });
}
