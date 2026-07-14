import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_cubit.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  Connection connection({
    String id = 'connection-1',
    String name = 'Local DB',
    String host = 'localhost',
    int port = 5432,
    String user = 'postgres',
    String password = '',
    String database = 'app',
    String workspaceId = 'default',
    ConnectionType type = ConnectionType.postgresql,
    bool useTls = false,
  }) {
    return Connection(
      id: id,
      name: name,
      host: host,
      port: port,
      user: user,
      password: password,
      database: database,
      workspaceId: workspaceId,
      type: type,
      useTls: useTls,
    );
  }

  test(
    'load filters by active workspace and clears an invalid selected id',
    () async {
      final repository = _FakeConnectionRepository(
        connections: [
          connection(id: 'a', workspaceId: 'workspace-a'),
          connection(id: 'b', workspaceId: 'workspace-b'),
        ],
        selectedId: 'a',
      );
      final cubit = ConnectionCubit(repository: repository);

      await cubit.setWorkspace('workspace-b');

      expect(cubit.state.activeWorkspaceId, 'workspace-b');
      expect(cubit.state.connections.map((item) => item.id).toList(), ['b']);
      expect(cubit.state.filteredConnections.map((item) => item.id).toList(), [
        'b',
      ]);
      expect(cubit.state.selectedId, isNull);
      expect(repository.selectedId, isNull);
      await cubit.close();
    },
  );

  test(
    'save selects the connection reloads and emits success feedback',
    () async {
      final repository = _FakeConnectionRepository();
      final cubit = ConnectionCubit(repository: repository);
      final saved = connection(id: 'saved', name: 'Saved');

      final result = await cubit.save(saved);

      expect(result, isTrue);
      expect(repository.selectedId, 'saved');
      expect(cubit.state.selectedId, 'saved');
      expect(cubit.state.activeConnection?.id, 'saved');
      expect(cubit.state.feedbackMessage, 'Connection saved');
      expect(cubit.state.feedbackIsError, isFalse);
      expect(cubit.state.connections.map((item) => item.id).toList(), [
        'saved',
      ]);
      await cubit.close();
    },
  );

  test('save stores connections in the active workspace', () async {
    final repository = _FakeConnectionRepository();
    final cubit = ConnectionCubit(repository: repository);
    await cubit.setWorkspace('workspace-a');

    final result = await cubit.save(
      connection(id: 'saved', name: 'Saved', workspaceId: 'default'),
    );

    expect(result, isTrue);
    expect(repository.connections.single.workspaceId, 'workspace-a');
    expect(cubit.state.connections.single.workspaceId, 'workspace-a');
    expect(cubit.state.filteredConnections.single.id, 'saved');
    expect(cubit.state.activeConnection?.workspaceId, 'workspace-a');
    await cubit.close();
  });

  test('save emits error feedback when repository save fails', () async {
    final cubit = ConnectionCubit(
      repository: _FakeConnectionRepository(
        saveError: Exception('save failed'),
      ),
    );

    final result = await cubit.save(connection());

    expect(result, isFalse);
    expect(cubit.state.status, ConnectionStatus.error);
    expect(cubit.state.feedbackMessage, 'Failed to save connection');
    expect(cubit.state.feedbackIsError, isTrue);
    await cubit.close();
  });

  test(
    'delete clears selected state and relies on repository cascades',
    () async {
      final repository = _FakeConnectionRepository(
        connections: [connection(id: 'selected')],
        selectedId: 'selected',
      );
      final cubit = ConnectionCubit(repository: repository);
      await cubit.load();

      await cubit.delete('selected');

      expect(cubit.state.selectedId, isNull);
      expect(cubit.state.activeConnection, isNull);
      expect(repository.selectedId, isNull);
      expect(cubit.state.connections, isEmpty);
      await cubit.close();
    },
  );

  test('delete sets error state when repository delete fails', () async {
    final cubit = ConnectionCubit(
      repository: _FakeConnectionRepository(
        deleteError: Exception('delete failed'),
      ),
    );

    await cubit.delete('missing');

    expect(cubit.state.status, ConnectionStatus.error);
    await cubit.close();
  });

  test('search filters by name or host and resets on empty query', () async {
    final repository = _FakeConnectionRepository(
      connections: [
        connection(id: 'alpha', name: 'Alpha', host: 'db-alpha'),
        connection(id: 'beta', name: 'Beta', host: 'db-beta'),
      ],
    );
    final cubit = ConnectionCubit(repository: repository);
    await cubit.load();

    cubit.search('beta');
    expect(cubit.state.filteredConnections.map((item) => item.id).toList(), [
      'beta',
    ]);

    cubit.search('db-alpha');
    expect(cubit.state.filteredConnections.map((item) => item.id).toList(), [
      'alpha',
    ]);

    cubit.search('');
    expect(cubit.state.filteredConnections.map((item) => item.id).toList(), [
      'alpha',
      'beta',
    ]);
    await cubit.close();
  });

  test('select persists the selected id', () async {
    final repository = _FakeConnectionRepository();
    final cubit = ConnectionCubit(repository: repository);

    await cubit.select('picked');

    expect(repository.selectedId, 'picked');
    expect(cubit.state.selectedId, 'picked');
    await cubit.close();
  });

  test(
    'openSavedConnection updates selected connection and open nonce',
    () async {
      final repository = _FakeConnectionRepository(
        connections: [connection(id: 'opened')],
      );
      final cubit = ConnectionCubit(repository: repository);
      await cubit.load();

      await cubit.openSavedConnection('opened');

      expect(repository.selectedId, 'opened');
      expect(cubit.state.selectedId, 'opened');
      expect(cubit.state.activeConnection?.id, 'opened');
      expect(cubit.state.openConnectionNonce, 1);
      await cubit.close();
    },
  );

  test('validation errors are returned before test execution', () async {
    final cubit = ConnectionCubit(repository: _FakeConnectionRepository());

    await cubit.test(connection(name: '', type: ConnectionType.postgresql));
    expect(cubit.state.feedbackMessage, 'Name is required');

    await cubit.test(
      connection(type: ConnectionType.mysql, host: '', port: 3306),
    );
    expect(cubit.state.feedbackMessage, 'Host is required');

    await cubit.test(connection(type: ConnectionType.mysql, port: 0));
    expect(cubit.state.feedbackMessage, 'Port is required');

    await cubit.test(
      connection(type: ConnectionType.sqlite, database: '', host: '', port: 0),
    );
    expect(cubit.state.feedbackMessage, 'Database File Path is required');
    await cubit.close();
  });

  test('driver failures surface user-facing feedback', () async {
    final cubit = ConnectionCubit(repository: _FakeConnectionRepository());

    await cubit.test(
      connection(
        type: ConnectionType.sqlite,
        host: '',
        port: 0,
        database: '/this/path/does/not/exist/database.sqlite',
      ),
    );

    expect(cubit.state.status, ConnectionStatus.error);
    expect(cubit.state.feedbackMessage, isNotNull);
    expect(cubit.state.feedbackMessage, isNot('Connection successful'));
    expect(cubit.state.feedbackIsError, isTrue);
    await cubit.close();
  });

  test('testing a connection does not activate or open it', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'querypod_connection_test_',
    );
    final databasePath = '${temporaryDirectory.path}/database.sqlite';
    final cubit = ConnectionCubit(repository: _FakeConnectionRepository());
    final connection = Connection(
      id: 'connection-under-test',
      name: 'Connection under test',
      host: '',
      port: 0,
      user: '',
      password: '',
      database: databasePath,
      workspaceId: 'default',
      type: ConnectionType.sqlite,
    );

    try {
      await cubit.test(connection);

      expect(cubit.state.status, ConnectionStatus.idle);
      expect(cubit.state.feedbackMessage, 'Connection successful');
      expect(cubit.state.activeConnection, isNull);
      expect(cubit.state.openConnectionNonce, 0);
    } finally {
      await cubit.close();
      await databaseFactoryFfi.deleteDatabase(databasePath);
      await temporaryDirectory.delete(recursive: true);
    }
  });
}

class _FakeConnectionRepository implements ConnectionRepository {
  _FakeConnectionRepository({
    List<Connection>? connections,
    this.selectedId,
    this.saveError,
    this.deleteError,
  }) : _connections = [...?connections];

  final List<Connection> _connections;
  String? selectedId;
  final Object? saveError;
  final Object? deleteError;

  List<Connection> get connections => List<Connection>.from(_connections);

  @override
  Future<void> delete(String id) async {
    if (deleteError != null) throw deleteError!;
    _connections.removeWhere((connection) => connection.id == id);
  }

  @override
  Future<List<Connection>> getAll() async =>
      List<Connection>.from(_connections);

  @override
  Future<Connection?> getById(String id) async {
    return _connections.where((connection) => connection.id == id).firstOrNull;
  }

  @override
  Future<String?> getSelectedId() async => selectedId;

  @override
  Future<Connection> save(Connection connection) async {
    if (saveError != null) throw saveError!;
    _connections.removeWhere((existing) => existing.id == connection.id);
    _connections.add(connection);
    return connection;
  }

  @override
  Future<void> setSelectedId(String? id) async {
    selectedId = id;
  }
}
