import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/domain/entities/connection_database.dart';
import 'package:querypod/features/editor/domain/entities/connection_table.dart';
import 'package:querypod/features/editor/domain/repositories/connection_metadata_repository.dart';
import 'package:querypod/features/editor/presentation/cubit/connection_metadata_cubit.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';

void main() {
  const firstConnection = Connection(
    id: 'same-id',
    name: 'First',
    host: 'first',
    port: 3306,
    user: 'root',
    password: '',
    database: '',
    workspaceId: 'default',
  );
  const secondConnection = Connection(
    id: 'same-id',
    name: 'Second',
    host: 'second',
    port: 3306,
    user: 'root',
    password: '',
    database: '',
    workspaceId: 'default',
  );

  test(
    'stale connection metadata cannot replace the current session',
    () async {
      final repository = _ControlledRepository();
      final cubit = ConnectionMetadataCubit(repository: repository);

      final firstLoad = cubit.loadConnection(firstConnection);
      final secondLoad = cubit.loadConnection(secondConnection);

      repository.databases['second']!.complete([
        const ConnectionDatabase(name: 'current_db'),
      ]);
      await Future<void>.delayed(Duration.zero);
      repository.tables['current_db']!.complete([
        const ConnectionTable(
          name: 'current_table',
          type: ConnectionTableType.table,
        ),
      ]);
      await secondLoad;

      repository.databases['first']!.complete([
        const ConnectionDatabase(name: 'stale_db'),
      ]);
      await firstLoad;

      expect(cubit.state.connectionSession, secondConnection.sessionIdentity);
      expect(cubit.state.selectedDatabase, 'current_db');
      expect(cubit.state.tables.single.name, 'current_table');
    },
  );

  test('stale request errors do not produce feedback', () async {
    final repository = _ControlledRepository();
    final cubit = ConnectionMetadataCubit(repository: repository);

    final firstLoad = cubit.loadConnection(firstConnection);
    final secondLoad = cubit.loadConnection(secondConnection);
    repository.databases['second']!.complete(const []);
    await secondLoad;
    repository.databases['first']!.completeError(Exception('stale failure'));
    await firstLoad;

    expect(cubit.state.connectionSession, secondConnection.sessionIdentity);
    expect(cubit.state.feedbackNonce, 0);
    expect(cubit.state.feedbackMessage, isNull);
  });

  test('stale table results cannot replace a newer database', () async {
    final repository = _DatabaseSwitchRepository();
    final cubit = ConnectionMetadataCubit(repository: repository);

    final initialLoad = cubit.loadConnection(firstConnection);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.selectedDatabase, 'first_db');

    final switchLoad = cubit.selectDatabase(firstConnection, 'second_db');
    repository.tables['second_db']!.complete([
      const ConnectionTable(
        name: 'current_table',
        type: ConnectionTableType.table,
      ),
    ]);
    await switchLoad;
    repository.tables['first_db']!.complete([
      const ConnectionTable(name: 'stale_table', type: ConnectionTableType.table),
    ]);
    await initialLoad;

    expect(cubit.state.selectedDatabase, 'second_db');
    expect(cubit.state.tables.single.name, 'current_table');
  });
}

class _ControlledRepository implements ConnectionMetadataRepository {
  final databases = <String, Completer<List<ConnectionDatabase>>>{};
  final tables = <String, Completer<List<ConnectionTable>>>{};

  @override
  Future<List<ConnectionDatabase>> listDatabases(Connection connection) {
    return (databases[connection.host] ??= Completer<List<ConnectionDatabase>>())
        .future;
  }

  @override
  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
  ) {
    return (tables[database] ??= Completer<List<ConnectionTable>>()).future;
  }

  @override
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {}

  @override
  Future<void> createTable(
    Connection connection,
    String database,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String table,
  ) async {
    return [];
  }

  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {}

  @override
  Future<void> dropTable(
    Connection connection,
    String database,
    String tableName, {
    bool cascade = false,
  }) async {}

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String tableName, {
    bool cascade = false,
  }) async {}
}

class _DatabaseSwitchRepository implements ConnectionMetadataRepository {
  final tables = <String, Completer<List<ConnectionTable>>>{};

  @override
  Future<List<ConnectionDatabase>> listDatabases(Connection connection) async {
    return const [
      ConnectionDatabase(name: 'first_db'),
      ConnectionDatabase(name: 'second_db'),
    ];
  }

  @override
  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
  ) {
    return (tables[database] ??= Completer<List<ConnectionTable>>()).future;
  }

  @override
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {}

  @override
  Future<void> createTable(
    Connection connection,
    String database,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String table,
  ) async {
    return [];
  }

  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {}

  @override
  Future<void> dropTable(
    Connection connection,
    String database,
    String tableName, {
    bool cascade = false,
  }) async {}

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String tableName, {
    bool cascade = false,
  }) async {}
}
