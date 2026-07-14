// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';

import '../../../../app/database.dart';
import '../../domain/entities/connection.dart';
import '../../domain/repositories/connection_repository.dart';
import '../services/connection_credential_store.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  final QueryPodDatabase _database;
  final ConnectionCredentialStore _credentialStore;

  ConnectionRepositoryImpl({
    required QueryPodDatabase database,
    required ConnectionCredentialStore credentialStore,
  }) : _database = database,
       _credentialStore = credentialStore;

  @override
  Future<List<Connection>> getAll() async {
    final rows = await _database.select(_database.connections).get();
    final connections = <Connection>[];
    for (final row in rows) {
      connections.add(await _toEntity(row));
    }
    return connections;
  }

  @override
  Future<Connection?> getById(String id) async {
    final query = _database.select(_database.connections)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<Connection> save(Connection connection) async {
    await _database
        .into(_database.connections)
        .insertOnConflictUpdate(
          ConnectionsCompanion.insert(
            id: connection.id,
            workspaceId: connection.workspaceId,
            name: connection.name,
            host: connection.host,
            port: connection.port,
            user: connection.user,
            database: connection.database,
            connectionType: _connectionTypeToStorage(connection.type),
            useTls: connection.useTls,
          ),
        );
    await _credentialStore.writePassword(connection.id, connection.password);
    return connection;
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(
      _database.connections,
    )..where((row) => row.id.equals(id))).go();
    await _credentialStore.deletePassword(id);
  }

  @override
  Future<String?> getSelectedId() async {
    final row = await (_database.select(
      _database.appStateEntries,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    return row?.selectedConnectionId;
  }

  @override
  Future<void> setSelectedId(String? id) async {
    await (_database.update(_database.appStateEntries)
          ..where((row) => row.id.equals(1)))
        .write(AppStateEntriesCompanion(selectedConnectionId: Value(id)));
  }

  Future<Connection> _toEntity(ConnectionRow row) async {
    return Connection(
      id: row.id,
      name: row.name,
      host: row.host,
      port: row.port,
      user: row.user,
      password: await _credentialStore.readPassword(row.id) ?? '',
      database: row.database,
      workspaceId: row.workspaceId,
      type: _connectionTypeFromStorage(row.connectionType),
      useTls: row.useTls,
    );
  }

  String _connectionTypeToStorage(ConnectionType type) => switch (type) {
    ConnectionType.mysql => 'mysql',
    ConnectionType.sqlite => 'sqlite',
    ConnectionType.postgresql => 'postgresql',
  };

  ConnectionType _connectionTypeFromStorage(String value) => switch (value) {
    'sqlite' => ConnectionType.sqlite,
    'postgresql' => ConnectionType.postgresql,
    _ => ConnectionType.mysql,
  };
}
