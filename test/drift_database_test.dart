import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/database.dart';
import 'package:querypod/features/connections/data/repositories/connection_repository_impl.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/data/repositories/pinned_tables_repository_impl.dart';
import 'package:querypod/features/editor/data/repositories/query_history_repository_impl.dart';
import 'package:querypod/features/editor/data/repositories/query_repository_impl.dart';
import 'package:querypod/features/editor/domain/entities/connection_query.dart';
import 'package:querypod/features/editor/domain/entities/query_history.dart';

import 'support/persistence_test_support.dart';

void main() {
  late QueryPodDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() => database.close());

  test(
    'fresh schema enables foreign keys, indexes, and singleton app state',
    () async {
      final foreignKeys = await database
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      expect(foreignKeys.read<int>('foreign_keys'), 1);
      expect(database.schemaVersion, 1);

      final schemaRows = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type IN ('table', 'index')",
          )
          .get();
      final names = schemaRows.map((row) => row.read<String>('name')).toSet();
      expect(
        names,
        containsAll({
          'workspaces',
          'connections',
          'saved_queries',
          'query_history',
          'pinned_tables',
          'app_state',
          'idx_connections_workspace_id',
          'idx_saved_queries_connection_id',
          'idx_query_history_connection_id',
        }),
      );

      final appState = await database.select(database.appStateEntries).get();
      expect(appState, hasLength(1));
      expect(appState.single.id, 1);
      expect(appState.single.selectedConnectionId, isNull);
      expect(
        () => database.customStatement('INSERT INTO app_state (id) VALUES (2)'),
        throwsA(anything),
      );
    },
  );

  test('foreign-key enforcement rejects orphaned connections', () async {
    expect(
      () => seedConnection(database, workspaceId: 'missing'),
      throwsA(anything),
    );
  });

  test('connection deletion cascades all related state and password', () async {
    final credentials = MemoryCredentialStore();
    final connections = ConnectionRepositoryImpl(
      database: database,
      credentialStore: credentials,
    );
    final queries = QueryRepositoryImpl(database: database);
    final history = QueryHistoryRepositoryImpl(database: database);
    final pins = PinnedTablesRepositoryImpl(database: database);
    await seedWorkspace(database);
    await connections.save(_connection());
    await connections.setSelectedId('connection');
    await queries.save(_query());
    await history.save(_history(id: 'history'));
    await pins.setPinnedTables(
      connectionId: 'connection',
      database: 'app',
      tableNames: const ['users'],
    );

    await connections.delete('connection');

    expect(await queries.getAllForConnection('connection'), isEmpty);
    expect(await history.getAllForConnection('connection'), isEmpty);
    expect(
      await pins.getPinnedTables(connectionId: 'connection', database: 'app'),
      isEmpty,
    );
    expect(await connections.getSelectedId(), isNull);
    expect(credentials.values, isEmpty);
  });

  test(
    'history is reverse chronological and watched after save and clear',
    () async {
      final repository = QueryHistoryRepositoryImpl(database: database);
      await seedWorkspace(database);
      await seedConnection(database);
      await repository.save(_history(id: 'older', day: 1));
      await repository.save(_history(id: 'newer', day: 2));

      expect(
        (await repository.getAllForConnection(
          'connection',
        )).map((row) => row.id),
        ['newer', 'older'],
      );

      final saveEvent = expectLater(
        repository.watchHistory('connection'),
        emits(anything),
      );
      await repository.save(_history(id: 'latest', day: 3));
      await saveEvent;

      final clearEvent = expectLater(
        repository.watchHistory('connection'),
        emits(anything),
      );
      await repository.clearHistory('connection');
      await clearEvent;
      expect(await repository.getAllForConnection('connection'), isEmpty);
    },
  );
}

Connection _connection() => const Connection(
  id: 'connection',
  name: 'Local DB',
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: 'secret',
  database: 'app',
  workspaceId: 'default',
  type: ConnectionType.postgresql,
  useTls: false,
);

ConnectionQuery _query() {
  final now = DateTime(2026, 1, 1);
  return ConnectionQuery(
    id: 'query',
    connectionId: 'connection',
    title: 'Query',
    sql: 'SELECT 1',
    createdAt: now,
    updatedAt: now,
  );
}

QueryHistory _history({required String id, int day = 1}) => QueryHistory(
  id: id,
  connectionId: 'connection',
  sourceType: 'editor',
  sourceId: 'query',
  sql: 'SELECT 1',
  executionTimeMs: 10,
  status: 'success',
  createdAt: DateTime(2026, 1, day),
);
