import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/database.dart';
import 'package:querypod/features/editor/data/repositories/query_repository_impl.dart';
import 'package:querypod/features/editor/domain/entities/connection_query.dart';

import 'support/persistence_test_support.dart';

void main() {
  late QueryPodDatabase database;
  late QueryRepositoryImpl repository;

  setUp(() async {
    database = createTestDatabase();
    repository = QueryRepositoryImpl(database: database);
    await seedWorkspace(database);
    await seedConnection(database, id: 'conn-1');
    await seedConnection(database, id: 'conn-2');
  });

  tearDown(() => database.close());

  test('repository scopes and orders queries by connection', () async {
    await repository.save(_query(id: 'later', connectionId: 'conn-1', day: 2));
    await repository.save(_query(id: 'other', connectionId: 'conn-2', day: 1));
    await repository.save(
      _query(id: 'earlier', connectionId: 'conn-1', day: 1),
    );

    final queries = await repository.getAllForConnection('conn-1');
    expect(queries.map((query) => query.id), ['earlier', 'later']);
  });

  test('duplicate save updates instead of inserting another row', () async {
    await repository.save(
      _query(id: 'query', connectionId: 'conn-1', title: 'Old'),
    );
    await repository.save(
      _query(id: 'query', connectionId: 'conn-1', title: 'New'),
    );

    final queries = await repository.getAllForConnection('conn-1');
    expect(queries, hasLength(1));
    expect(queries.single.title, 'New');
    expect(queries.single.database, 'app');
  });

  test('delete and deleteByConnection remove only matching queries', () async {
    await repository.save(_query(id: 'q1', connectionId: 'conn-1'));
    await repository.save(_query(id: 'q2', connectionId: 'conn-1'));
    await repository.save(_query(id: 'q3', connectionId: 'conn-2'));

    await repository.delete('q1');
    expect(
      (await repository.getAllForConnection('conn-1')).map((query) => query.id),
      ['q2'],
    );

    await repository.deleteByConnection('conn-1');
    expect(await repository.getAllForConnection('conn-1'), isEmpty);
    expect(await repository.getAllForConnection('conn-2'), hasLength(1));
  });
}

ConnectionQuery _query({
  required String id,
  required String connectionId,
  String title = 'demo',
  int day = 1,
}) {
  final now = DateTime(2026, 1, day);
  return ConnectionQuery(
    id: id,
    connectionId: connectionId,
    title: title,
    sql: 'SELECT 1;',
    database: 'app',
    createdAt: now,
    updatedAt: now,
  );
}
