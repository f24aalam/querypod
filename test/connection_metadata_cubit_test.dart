import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/domain/entities/connection_database.dart';
import 'package:querypod/features/editor/domain/entities/connection_schema.dart';
import 'package:querypod/features/editor/domain/entities/connection_table.dart';
import 'package:querypod/features/editor/domain/repositories/connection_metadata_repository.dart';
import 'package:querypod/features/editor/domain/repositories/pinned_tables_repository.dart';
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
      final cubit = ConnectionMetadataCubit(
        repository: repository,
        pinnedTablesRepository: _MemoryPinnedTablesRepository(),
      );

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
    final cubit = ConnectionMetadataCubit(
      repository: repository,
      pinnedTablesRepository: _MemoryPinnedTablesRepository(),
    );

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
    final cubit = ConnectionMetadataCubit(
      repository: repository,
      pinnedTablesRepository: _MemoryPinnedTablesRepository(),
    );

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
      const ConnectionTable(
        name: 'stale_table',
        type: ConnectionTableType.table,
      ),
    ]);
    await initialLoad;

    expect(cubit.state.selectedDatabase, 'second_db');
    expect(cubit.state.tables.single.name, 'current_table');
  });

  test('loads and orders pinned tables for the selected database', () async {
    final repository = _ImmediateRepository(
      tables: const [
        ConnectionTable(name: 'users', type: ConnectionTableType.table),
        ConnectionTable(name: 'orders', type: ConnectionTableType.table),
        ConnectionTable(name: 'profiles', type: ConnectionTableType.table),
      ],
    );
    final pins = _MemoryPinnedTablesRepository()
      ..seed(
        connectionId: firstConnection.id,
        database: 'first_db',
        tableNames: const ['orders', 'users'],
      );
    final cubit = ConnectionMetadataCubit(
      repository: repository,
      pinnedTablesRepository: pins,
    );

    await cubit.loadConnection(firstConnection);

    expect(cubit.state.pinnedTableNames, ['orders', 'users']);
    expect(cubit.state.pinnedFilteredTables.map((table) => table.name), [
      'orders',
      'users',
    ]);
    expect(cubit.state.unpinnedFilteredTables.map((table) => table.name), [
      'profiles',
    ]);
  });

  test(
    'toggleTablePin persists pins for the active connection database',
    () async {
      final repository = _ImmediateRepository(
        tables: const [
          ConnectionTable(name: 'users', type: ConnectionTableType.table),
        ],
      );
      final pins = _MemoryPinnedTablesRepository();
      final cubit = ConnectionMetadataCubit(
        repository: repository,
        pinnedTablesRepository: pins,
      );

      await cubit.loadConnection(firstConnection);
      await cubit.toggleTablePin(
        const ConnectionTable(name: 'users', type: ConnectionTableType.table),
      );

      expect(cubit.state.pinnedTableNames, ['users']);
      expect(
        await pins.getPinnedTables(
          connectionId: firstConnection.id,
          database: 'first_db',
        ),
        ['users'],
      );
    },
  );

  test('refresh prunes pinned tables that no longer exist', () async {
    final repository = _MutableRepository(
      tables: [
        const ConnectionTable(name: 'users', type: ConnectionTableType.table),
        const ConnectionTable(name: 'orders', type: ConnectionTableType.table),
      ],
    );
    final pins = _MemoryPinnedTablesRepository()
      ..seed(
        connectionId: firstConnection.id,
        database: 'first_db',
        tableNames: const ['orders', 'missing'],
      );
    final cubit = ConnectionMetadataCubit(
      repository: repository,
      pinnedTablesRepository: pins,
    );

    await cubit.loadConnection(firstConnection);
    repository.tables = [
      const ConnectionTable(name: 'users', type: ConnectionTableType.table),
    ];
    await cubit.refreshTables(firstConnection, 'first_db');

    expect(cubit.state.pinnedTableNames, isEmpty);
    expect(
      await pins.getPinnedTables(
        connectionId: firstConnection.id,
        database: 'first_db',
      ),
      isEmpty,
    );
  });

  test('search filters pinned tables too', () async {
    final repository = _ImmediateRepository(
      tables: const [
        ConnectionTable(name: 'users', type: ConnectionTableType.table),
        ConnectionTable(name: 'orders', type: ConnectionTableType.table),
      ],
    );
    final pins = _MemoryPinnedTablesRepository()
      ..seed(
        connectionId: firstConnection.id,
        database: 'first_db',
        tableNames: const ['orders'],
      );
    final cubit = ConnectionMetadataCubit(
      repository: repository,
      pinnedTablesRepository: pins,
    );

    await cubit.loadConnection(firstConnection);
    cubit.search('use');

    expect(cubit.state.pinnedFilteredTables, isEmpty);
    expect(cubit.state.unpinnedFilteredTables.map((table) => table.name), [
      'users',
    ]);
  });

  test(
    'postgres load restores selected schema and loads tables for it',
    () async {
      final repository =
          _MutableRepository(
              tables: const [
                ConnectionTable(
                  name: 'events',
                  type: ConnectionTableType.table,
                ),
              ],
            )
            ..schemas = const [
              ConnectionSchema(name: 'analytics'),
              ConnectionSchema(name: 'public'),
            ]
            ..selectedSchemas['same-id::first_db'] = 'analytics';
      final cubit = ConnectionMetadataCubit(
        repository: repository,
        pinnedTablesRepository: _MemoryPinnedTablesRepository(),
      );
      final connection = firstConnection.copyWith(
        database: 'first_db',
        type: ConnectionType.postgresql,
      );

      await cubit.loadConnection(connection);

      expect(cubit.state.selectedDatabase, 'first_db');
      expect(cubit.state.selectedSchema, 'analytics');
      expect(repository.lastListTablesSchema, 'analytics');
      expect(cubit.state.tables.single.name, 'events');
    },
  );
}

class _MemoryPinnedTablesRepository implements PinnedTablesRepository {
  final _pins = <String, List<String>>{};

  void seed({
    required String connectionId,
    required String database,
    String? schema,
    required List<String> tableNames,
  }) {
    _pins[_key(connectionId, database, schema)] = List<String>.from(tableNames);
  }

  @override
  Future<List<String>> getPinnedTables({
    required String connectionId,
    required String database,
    String? schema,
  }) async {
    return List<String>.from(
      _pins[_key(connectionId, database, schema)] ?? const [],
    );
  }

  @override
  Future<void> setPinnedTables({
    required String connectionId,
    required String database,
    String? schema,
    required List<String> tableNames,
  }) async {
    _pins[_key(connectionId, database, schema)] = List<String>.from(tableNames);
  }

  String _key(String connectionId, String database, String? schema) =>
      '$connectionId::$database::${schema ?? 'public'}';
}

class _ImmediateRepository extends _MutableRepository {
  _ImmediateRepository({required super.tables});
}

class _MutableRepository implements ConnectionMetadataRepository {
  _MutableRepository({required this.tables});

  List<ConnectionTable> tables;
  List<ConnectionSchema> schemas = const [ConnectionSchema(name: 'public')];
  final selectedSchemas = <String, String>{};
  String? lastListTablesSchema;

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
    String? schema,
  ) async {
    lastListTablesSchema = schema;
    return tables;
  }

  @override
  Future<List<ConnectionSchema>> listSchemas(
    Connection connection,
    String database,
  ) async {
    return schemas;
  }

  @override
  Future<String?> getSelectedSchema({
    required String connectionId,
    required String database,
  }) async => selectedSchemas['$connectionId::$database'];

  @override
  Future<void> setSelectedSchema({
    required String connectionId,
    required String database,
    required String? schema,
  }) async {
    if (schema == null) {
      selectedSchemas.remove('$connectionId::$database');
    } else {
      selectedSchemas['$connectionId::$database'] = schema;
    }
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
    String? schema,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String? schema,
    String table,
  ) async {
    return [];
  }

  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String? schema,
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
    String? schema,
    bool cascade = false,
  }) async {}

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String tableName, {
    String? schema,
    bool cascade = false,
  }) async {}

  @override
  Future<void> createSchema(
    Connection connection,
    String database,
    String name,
  ) async {}
}

class _ControlledRepository implements ConnectionMetadataRepository {
  final databases = <String, Completer<List<ConnectionDatabase>>>{};
  final tables = <String, Completer<List<ConnectionTable>>>{};

  @override
  Future<List<ConnectionDatabase>> listDatabases(Connection connection) {
    return (databases[connection.host] ??=
            Completer<List<ConnectionDatabase>>())
        .future;
  }

  @override
  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
    String? schema,
  ) {
    return (tables[database] ??= Completer<List<ConnectionTable>>()).future;
  }

  @override
  Future<List<ConnectionSchema>> listSchemas(
    Connection connection,
    String database,
  ) async {
    return const [ConnectionSchema(name: 'public')];
  }

  @override
  Future<String?> getSelectedSchema({
    required String connectionId,
    required String database,
  }) async => null;

  @override
  Future<void> setSelectedSchema({
    required String connectionId,
    required String database,
    required String? schema,
  }) async {}

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
    String? schema,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String? schema,
    String table,
  ) async {
    return [];
  }

  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String? schema,
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
    String? schema,
    bool cascade = false,
  }) async {}

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String tableName, {
    String? schema,
    bool cascade = false,
  }) async {}

  @override
  Future<void> createSchema(
    Connection connection,
    String database,
    String name,
  ) async {}
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
    String? schema,
  ) {
    return (tables[database] ??= Completer<List<ConnectionTable>>()).future;
  }

  @override
  Future<List<ConnectionSchema>> listSchemas(
    Connection connection,
    String database,
  ) async {
    return const [ConnectionSchema(name: 'public')];
  }

  @override
  Future<String?> getSelectedSchema({
    required String connectionId,
    required String database,
  }) async => null;

  @override
  Future<void> setSelectedSchema({
    required String connectionId,
    required String database,
    required String? schema,
  }) async {}

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
    String? schema,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String? schema,
    String table,
  ) async {
    return [];
  }

  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String? schema,
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
    String? schema,
    bool cascade = false,
  }) async {}

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String tableName, {
    String? schema,
    bool cascade = false,
  }) async {}

  @override
  Future<void> createSchema(
    Connection connection,
    String database,
    String name,
  ) async {}
}
