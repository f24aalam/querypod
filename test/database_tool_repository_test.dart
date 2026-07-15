import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/database_transfer/data/database_tool_repository_impl.dart';
import 'package:querypod/features/database_transfer/domain/database_tool.dart';

import 'support/persistence_test_support.dart';

void main() {
  test('tool overrides persist and can be reset', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = DatabaseToolRepositoryImpl(database: database);

    expect(await repository.getOverride(DatabaseTool.pgDump), isNull);
    await repository.setOverride(DatabaseTool.pgDump, '/custom/pg_dump');
    expect(
      await repository.getOverride(DatabaseTool.pgDump),
      '/custom/pg_dump',
    );

    final secondRepository = DatabaseToolRepositoryImpl(database: database);
    expect(
      await secondRepository.getOverride(DatabaseTool.pgDump),
      '/custom/pg_dump',
    );

    await repository.setOverride(DatabaseTool.pgDump, null);
    expect(await repository.getOverride(DatabaseTool.pgDump), isNull);
  });
}
