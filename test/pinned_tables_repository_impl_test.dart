import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/database.dart';
import 'package:querypod/features/editor/data/repositories/pinned_tables_repository_impl.dart';

import 'support/persistence_test_support.dart';

void main() {
  late QueryPodDatabase database;
  late PinnedTablesRepositoryImpl repository;

  setUp(() async {
    database = createTestDatabase();
    repository = PinnedTablesRepositoryImpl(database: database);
    await seedWorkspace(database);
    await seedConnection(database, id: 'first');
    await seedConnection(database, id: 'second');
  });

  tearDown(() => database.close());

  test('empty database returns no pinned tables', () async {
    expect(
      await repository.getPinnedTables(connectionId: 'first', database: 'app'),
      isEmpty,
    );
  });

  test('pinned tables round-trip in saved order', () async {
    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'app',
      tableNames: const ['orders', 'users'],
    );

    expect(
      await repository.getPinnedTables(connectionId: 'first', database: 'app'),
      ['orders', 'users'],
    );
  });

  test('replacing pins removes old values and preserves new order', () async {
    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'app',
      tableNames: const ['users', 'orders'],
    );
    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'app',
      tableNames: const ['events', 'users'],
    );

    expect(
      await repository.getPinnedTables(connectionId: 'first', database: 'app'),
      ['events', 'users'],
    );
  });

  test('pins are scoped by connection and database', () async {
    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'app',
      tableNames: const ['users'],
    );
    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'analytics',
      tableNames: const ['events'],
    );
    await repository.setPinnedTables(
      connectionId: 'second',
      database: 'app',
      tableNames: const ['orders'],
    );

    expect(
      await repository.getPinnedTables(connectionId: 'first', database: 'app'),
      ['users'],
    );
    expect(
      await repository.getPinnedTables(
        connectionId: 'first',
        database: 'analytics',
      ),
      ['events'],
    );
    expect(
      await repository.getPinnedTables(connectionId: 'second', database: 'app'),
      ['orders'],
    );
  });

  test('empty pin list removes stored database pins', () async {
    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'app',
      tableNames: const ['users'],
    );
    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'app',
      tableNames: const [],
    );

    expect(
      await repository.getPinnedTables(connectionId: 'first', database: 'app'),
      isEmpty,
    );
  });
}
