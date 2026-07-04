import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_cubit.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_state.dart';
import 'package:querypod/features/editor/domain/entities/connection_query.dart';
import 'package:querypod/features/editor/domain/repositories/query_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('testing a connection does not activate or open it', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'querypod_connection_test_',
    );
    final databasePath = '${temporaryDirectory.path}/database.sqlite';
    final cubit = ConnectionCubit(
      repository: _FakeConnectionRepository(),
      queryRepository: _FakeQueryRepository(),
    );
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
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Connection>> getAll() async => [];

  @override
  Future<Connection?> getById(String id) async => null;

  @override
  Future<String?> getSelectedId() async => null;

  @override
  Future<Connection> save(Connection connection) async => connection;

  @override
  Future<void> setSelectedId(String? id) async {}
}

class _FakeQueryRepository implements QueryRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteByConnection(String connectionId) async {}

  @override
  Future<List<ConnectionQuery>> getAllForConnection(
    String connectionId,
  ) async => [];

  @override
  Future<ConnectionQuery> save(ConnectionQuery query) async => query;
}
