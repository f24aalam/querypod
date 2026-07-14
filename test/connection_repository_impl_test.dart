import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/database.dart';
import 'package:querypod/features/connections/data/repositories/connection_repository_impl.dart';
import 'package:querypod/features/connections/data/services/connection_credential_store.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';

import 'support/persistence_test_support.dart';

void main() {
  late QueryPodDatabase database;
  late MemoryCredentialStore credentials;
  late ConnectionRepositoryImpl repository;

  setUp(() async {
    database = createTestDatabase();
    credentials = MemoryCredentialStore();
    repository = ConnectionRepositoryImpl(
      database: database,
      credentialStore: credentials,
    );
    await seedWorkspace(database);
  });

  tearDown(() => database.close());

  test('empty database returns no connections', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('save persists metadata and keeps password out of SQLite', () async {
    await repository.save(_connection());

    final row = (await database.select(database.connections).get()).single;
    expect(row.name, 'Local DB');
    expect(credentials.values['connection-1'], 'secret');

    final columns = await database
        .customSelect('PRAGMA table_info(connections)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      isNot(contains('password')),
    );
  });

  test(
    'save updates an existing connection instead of duplicating it',
    () async {
      await repository.save(_connection(name: 'Old Name'));
      await repository.save(_connection(name: 'New Name'));

      final connections = await repository.getAll();
      expect(connections, hasLength(1));
      expect(connections.single.name, 'New Name');
    },
  );

  test('getAll and getById rehydrate the stored password', () async {
    await repository.save(_connection(password: 'db-secret'));

    expect((await repository.getAll()).single.password, 'db-secret');
    expect((await repository.getById('connection-1'))!.password, 'db-secret');
  });

  test('delete removes the connection and its stored password', () async {
    await repository.save(_connection());

    await repository.delete('connection-1');

    expect(await repository.getAll(), isEmpty);
    expect(credentials.values, isEmpty);
  });

  test('getById returns null for missing ids', () async {
    expect(await repository.getById('missing'), isNull);
  });

  test('selected connection id round-trips and clears', () async {
    await repository.save(_connection());

    await repository.setSelectedId('connection-1');
    expect(await repository.getSelectedId(), 'connection-1');

    await repository.setSelectedId(null);
    expect(await repository.getSelectedId(), isNull);
  });

  test('profile databases and credential keys can be isolated', () async {
    final sharedSecrets = <String, String>{};
    final alphaCredentials = MemoryCredentialStore(
      values: sharedSecrets,
      namespace: 'alpha',
    );
    final betaCredentials = MemoryCredentialStore(
      values: sharedSecrets,
      namespace: 'beta',
    );
    final alpha = ConnectionRepositoryImpl(
      database: database,
      credentialStore: alphaCredentials,
    );
    await alpha.save(_connection(password: 'alpha-secret'));
    expect((await alpha.getAll()).single.password, 'alpha-secret');

    await database.close();
    database = createTestDatabase();
    final beta = ConnectionRepositoryImpl(
      database: database,
      credentialStore: betaCredentials,
    );
    await seedWorkspace(database);
    await beta.save(_connection(password: 'beta-secret'));

    expect((await beta.getAll()).single.password, 'beta-secret');
    expect(sharedSecrets, {
      'alpha::connection-1': 'alpha-secret',
      'beta::connection-1': 'beta-secret',
    });
    expect(
      QueryPodDatabase.filenameForProfile('alpha'),
      isNot(QueryPodDatabase.filenameForProfile('beta')),
    );
    expect(
      QueryPodDatabase.filenameForProfile('../unsafe'),
      isNot(contains('/')),
    );
    expect(
      SecureConnectionCredentialStore(
        keyNamespace: 'alpha',
      ).keyFor('connection-1'),
      'alpha_querypod_connection_connection-1',
    );
  });
}

Connection _connection({
  String id = 'connection-1',
  String name = 'Local DB',
  String password = 'secret',
}) {
  return Connection(
    id: id,
    name: name,
    host: 'localhost',
    port: 5432,
    user: 'postgres',
    password: password,
    database: 'app',
    workspaceId: 'default',
    type: ConnectionType.postgresql,
    useTls: false,
  );
}
