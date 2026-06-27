import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('test empty insert', () async {
    final dbFactory = databaseFactoryFfi;
    final db = await dbFactory.openDatabase(inMemoryDatabasePath);

    await db.execute('''
      CREATE TABLE test (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    try {
      await db.transaction((txn) async {
        await txn.execute('INSERT INTO "test" DEFAULT VALUES', []);
      });
      print('Insert succeeded!');
    } catch (e) {
      print('Insert failed: $e');
    }

    await db.close();
  });
}
