import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/database.dart';
import 'package:querypod/features/workspaces/data/repositories/workspace_repository_impl.dart';
import 'package:querypod/features/workspaces/domain/entities/app_workspace.dart';

import 'support/persistence_test_support.dart';

void main() {
  late QueryPodDatabase database;
  late MemoryCredentialStore credentials;
  late WorkspaceRepositoryImpl repository;

  setUp(() {
    database = createTestDatabase();
    credentials = MemoryCredentialStore();
    repository = WorkspaceRepositoryImpl(
      database: database,
      credentialStore: credentials,
    );
  });

  tearDown(() => database.close());

  test('empty database returns no workspaces', () async {
    expect(await repository.getWorkspaces(), isEmpty);
  });

  test('getWorkspaces sorts by createdAt descending', () async {
    final older = _workspace('older', 'Older', DateTime(2024, 1, 1));
    final newer = _workspace('newer', 'Newer', DateTime(2025, 1, 1));

    await repository.createWorkspace(older);
    await repository.createWorkspace(newer);

    final workspaces = await repository.getWorkspaces();
    expect(workspaces.map((item) => item.id).toList(), ['newer', 'older']);
  });

  test('getWorkspace returns the matching workspace', () async {
    final target = _workspace('target', 'Target', DateTime(2024, 2, 1));
    await repository.createWorkspace(target);

    expect(await repository.getWorkspace('target'), target);
  });

  test('getWorkspace throws when the workspace is missing', () async {
    expect(() => repository.getWorkspace('missing'), throwsA(isA<Exception>()));
  });

  test('createWorkspace persists the workspace', () async {
    final created = _workspace('created', 'Created', DateTime(2024, 3, 1));

    await repository.createWorkspace(created);

    expect(await repository.getWorkspaces(), [created]);
  });

  test('updateWorkspace replaces only the matching workspace', () async {
    final first = _workspace('first', 'First', DateTime(2024, 1, 1));
    final second = _workspace('second', 'Second', DateTime(2024, 2, 1));
    await repository.createWorkspace(first);
    await repository.createWorkspace(second);
    final updatedSecond = second.copyWith(name: 'Renamed');

    await repository.updateWorkspace(updatedSecond);

    expect(await repository.getWorkspaces(), [updatedSecond, first]);
  });

  test('updateWorkspace throws when the workspace does not exist', () async {
    final missing = _workspace('missing', 'Missing', DateTime(2024, 1, 1));

    expect(
      () => repository.updateWorkspace(missing),
      throwsA(isA<Exception>()),
    );
  });

  test('deleteWorkspace removes only the target workspace', () async {
    final first = _workspace('first', 'First', DateTime(2024, 1, 1));
    final second = _workspace('second', 'Second', DateTime(2024, 2, 1));
    await repository.createWorkspace(first);
    await repository.createWorkspace(second);

    await repository.deleteWorkspace('first');

    expect(await repository.getWorkspaces(), [second]);
  });

  test('deleteWorkspace cascades child state and removes passwords', () async {
    await repository.createWorkspace(
      _workspace('team', 'Team', DateTime(2024, 1, 1)),
    );
    await seedConnection(database, id: 'first', workspaceId: 'team');
    await seedConnection(database, id: 'second', workspaceId: 'team');
    await credentials.writePassword('first', 'one');
    await credentials.writePassword('second', 'two');
    final now = DateTime(2026, 1, 1);
    await database
        .into(database.savedQueries)
        .insert(
          SavedQueriesCompanion.insert(
            id: 'query',
            connectionId: 'first',
            title: 'Query',
            sql: 'SELECT 1',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.queryHistoryEntries)
        .insert(
          QueryHistoryEntriesCompanion.insert(
            id: 'history',
            connectionId: 'second',
            sourceType: 'editor',
            sql: 'SELECT 1',
            executionTimeMs: 1,
            status: 'success',
            createdAt: now,
          ),
        );
    await database
        .into(database.pinnedTables)
        .insert(
          PinnedTablesCompanion.insert(
            connectionId: 'first',
            database: 'app',
            table: 'users',
            sortOrder: 0,
          ),
        );
    await database.customStatement(
      "UPDATE app_state SET selected_connection_id = 'first' WHERE id = 1",
    );

    await repository.deleteWorkspace('team');

    expect(await database.select(database.connections).get(), isEmpty);
    expect(await database.select(database.savedQueries).get(), isEmpty);
    expect(await database.select(database.queryHistoryEntries).get(), isEmpty);
    expect(await database.select(database.pinnedTables).get(), isEmpty);
    expect(
      (await database.select(database.appStateEntries).getSingle())
          .selectedConnectionId,
      isNull,
    );
    expect(credentials.values, isEmpty);
  });

  test(
    'deleteWorkspace still removes metadata when credential cleanup fails',
    () async {
      credentials = _DeleteFailingCredentialStore();
      repository = WorkspaceRepositoryImpl(
        database: database,
        credentialStore: credentials,
      );
      await repository.createWorkspace(
        _workspace('team', 'Team', DateTime(2024, 1, 1)),
      );
      await seedConnection(database, id: 'first', workspaceId: 'team');
      await credentials.writePassword('first', 'one');

      await repository.deleteWorkspace('team');

      expect(await database.select(database.workspaces).get(), isEmpty);
      expect(await database.select(database.connections).get(), isEmpty);
      expect(credentials.values['first'], 'one');
    },
  );
}

class _DeleteFailingCredentialStore extends MemoryCredentialStore {
  @override
  Future<void> deletePassword(String connectionId) async {
    throw Exception('keyring locked');
  }
}

AppWorkspace _workspace(String id, String name, DateTime createdAt) {
  return AppWorkspace(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}
