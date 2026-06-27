import 'package:flutter_test/flutter_test.dart';
import 'package:postgres/postgres.dart' as pg;

void main() {
  test('test postgres empty insert', () async {
    // We can't really test postgres without a running database, 
    // but we can check if Sql.named throws or hangs before connecting?
    try {
      final sql = pg.Sql.named('INSERT INTO "table" DEFAULT VALUES');
      print('Sql.named created: $sql');
    } catch (e) {
      print('Sql.named failed: $e');
    }
  });
}
