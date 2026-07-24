import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysql_client_plus/exception.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/connection_table.dart';
import '../../domain/entities/table_data.dart';
import '../../domain/repositories/connection_metadata_repository.dart';
import '../../domain/repositories/pinned_tables_repository.dart';
import 'connection_metadata_state.dart';

class ConnectionMetadataCubit extends Cubit<ConnectionMetadataState> {
  final ConnectionMetadataRepository repository;
  final PinnedTablesRepository pinnedTablesRepository;
  int _requestGeneration = 0;

  ConnectionMetadataCubit({
    required this.repository,
    required this.pinnedTablesRepository,
  }) : super(const ConnectionMetadataState());

  ConnectionMetadataState _feedback(
    String message, {
    required bool isError,
    ConnectionMetadataStatus status = ConnectionMetadataStatus.idle,
  }) {
    return state.copyWith(
      status: status,
      feedbackMessage: () => message,
      feedbackIsError: isError,
      feedbackNonce: state.feedbackNonce + 1,
    );
  }

  String _metadataErrorMessage(Object error, {required String fallback}) {
    if (error is MySQLException) {
      final base = error.message.isNotEmpty ? error.message : fallback;
      return '$fallback: $base';
    }

    return '$fallback: $error';
  }

  Future<void> loadConnection(Connection connection) async {
    final session = connection.sessionIdentity;
    if (state.connectionSession == session && state.databases.isNotEmpty) {
      return;
    }
    final request = ++_requestGeneration;

    emit(
      state.copyWith(
        connectionId: () => connection.id,
        connectionSession: () => session,
        databases: const [],
        selectedDatabase: () => null,
        schemas: const [],
        selectedSchema: () => null,
        tables: const [],
        filteredTables: const [],
        pinnedTableNames: const [],
        selectedTable: () => null,
        query: '',
        status: ConnectionMetadataStatus.loadingDatabases,
      ),
    );

    try {
      final databases = await repository.listDatabases(connection);
      if (!_isCurrent(request, session)) return;
      final savedDatabase = connection.database;
      final initialDatabase = databases.any((db) => db.name == savedDatabase)
          ? savedDatabase
          : (databases.isNotEmpty ? databases.first.name : null);

      emit(
        state.copyWith(
          databases: databases,
          selectedDatabase: () => initialDatabase,
          status: initialDatabase == null
              ? ConnectionMetadataStatus.idle
              : ConnectionMetadataStatus.loadingTables,
        ),
      );

      if (initialDatabase != null) {
        await _loadSchemasAndTables(
          connection,
          initialDatabase,
          request: request,
          session: session,
        );
      }
    } catch (e) {
      if (!_isCurrent(request, session)) return;
      emit(
        _feedback(
          _metadataErrorMessage(e, fallback: 'Failed to load databases'),
          isError: true,
          status: ConnectionMetadataStatus.error,
        ).copyWith(
          databases: const [],
          selectedDatabase: () => null,
          schemas: const [],
          selectedSchema: () => null,
          tables: const [],
          filteredTables: const [],
          pinnedTableNames: const [],
          selectedTable: () => null,
        ),
      );
    }
  }

  Future<void> selectDatabase(Connection connection, String database) async {
    if (state.selectedDatabase == database) return;
    final session = connection.sessionIdentity;
    if (state.connectionSession != session) return;
    final request = ++_requestGeneration;

    emit(
      state.copyWith(
        selectedDatabase: () => database,
        schemas: const [],
        selectedSchema: () => null,
        query: '',
        tables: const [],
        filteredTables: const [],
        pinnedTableNames: const [],
        selectedTable: () => null,
        status: ConnectionMetadataStatus.loadingTables,
      ),
    );

    try {
      await _loadSchemasAndTables(
        connection,
        database,
        request: request,
        session: session,
      );
    } catch (e) {
      if (!_isCurrent(request, session, database: database)) return;
      emit(
        _feedback(
          _metadataErrorMessage(
            e,
            fallback: 'Failed to load tables for $database',
          ),
          isError: true,
          status: ConnectionMetadataStatus.error,
        ),
      );
    }
  }

  Future<void> refreshTables(Connection connection, String database) async {
    final session = connection.sessionIdentity;
    if (state.connectionSession != session) return;
    final request = ++_requestGeneration;

    emit(state.copyWith(status: ConnectionMetadataStatus.loadingTables));

    try {
      await _loadTables(
        connection,
        database,
        schema: state.selectedSchema,
        request: request,
        session: session,
      );
    } catch (e) {
      if (!_isCurrent(request, session, database: database)) return;
      emit(
        _feedback(
          _metadataErrorMessage(
            e,
            fallback: 'Failed to refresh tables for $database',
          ),
          isError: true,
          status: ConnectionMetadataStatus.error,
        ),
      );
    }
  }

  void search(String query) {
    final filtered = _filter(state.tables, query);
    final selectedTable =
        filtered.any((table) => table.name == state.selectedTable?.name)
        ? state.selectedTable
        : (filtered.isNotEmpty ? filtered.first : null);

    emit(
      state.copyWith(
        query: query,
        filteredTables: filtered,
        selectedTable: () => selectedTable,
      ),
    );
  }

  void selectTable(ConnectionTable table) {
    emit(state.copyWith(selectedTable: () => table));
  }

  Future<void> toggleTablePin(ConnectionTable table) async {
    final connectionId = state.connectionId;
    final database = state.selectedDatabase;
    final schema = state.selectedSchema;
    if (connectionId == null || database == null) return;

    final pinned = List<String>.from(state.pinnedTableNames);
    if (pinned.contains(table.name)) {
      pinned.remove(table.name);
    } else {
      pinned.add(table.name);
    }

    emit(state.copyWith(pinnedTableNames: pinned));
    await pinnedTablesRepository.setPinnedTables(
      connectionId: connectionId,
      database: database,
      schema: schema,
      tableNames: pinned,
    );
  }

  void clear() {
    _requestGeneration++;
    emit(const ConnectionMetadataState());
  }

  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {
    try {
      await repository.createDatabase(
        connection,
        name,
        charset: charset,
        collation: collation,
      );

      // Refresh databases
      final databases = await repository.listDatabases(connection);
      final session = connection.sessionIdentity;

      if (state.connectionSession != session) return;

      emit(state.copyWith(databases: databases));

      // Select the newly created database
      await selectDatabase(connection, name);
    } catch (e) {
      emit(
        _feedback(
          _metadataErrorMessage(e, fallback: 'Failed to create database $name'),
          isError: true,
          status: state.status, // Preserve current status
        ),
      );
      // Re-throw if the UI wants to catch it
      rethrow;
    }
  }

  Future<void> createTable(
    Connection connection,
    String database,
    String? schema,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {
    try {
      await repository.createTable(
        connection,
        database,
        schema,
        tableName,
        columns,
      );

      // Refresh tables
      await _loadTables(
        connection,
        database,
        schema: schema,
        request: ++_requestGeneration,
        session: connection.sessionIdentity,
      );
    } catch (e) {
      emit(
        _feedback(
          _metadataErrorMessage(
            e,
            fallback: 'Failed to create table $tableName',
          ),
          isError: true,
          status: state.status,
        ),
      );
      rethrow;
    }
  }

  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String? schema,
    String table,
  ) async {
    try {
      return await repository.getTableSchema(
        connection,
        database,
        schema,
        table,
      );
    } catch (e) {
      emit(
        _feedback(
          _metadataErrorMessage(
            e,
            fallback: 'Failed to get schema for table $table',
          ),
          isError: true,
          status: state.status,
        ),
      );
      rethrow;
    }
  }

  Future<void> alterTable(
    Connection connection,
    String database,
    String? schema,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {
    try {
      await repository.alterTable(
        connection,
        database,
        schema,
        oldTableName,
        newTableName,
        oldColumns,
        newColumns,
      );

      await _loadTables(
        connection,
        database,
        schema: schema,
        request: ++_requestGeneration,
        session: connection.sessionIdentity,
      );
    } catch (e) {
      emit(
        _feedback(
          _metadataErrorMessage(
            e,
            fallback: 'Failed to alter table $oldTableName',
          ),
          isError: true,
          status: state.status,
        ),
      );
      rethrow;
    }
  }

  Future<void> dropTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    bool cascade = false,
  }) async {
    try {
      await repository.dropTable(
        connection,
        database,
        table,
        schema: schema,
        cascade: cascade,
      );

      await _loadTables(
        connection,
        database,
        schema: schema,
        request: ++_requestGeneration,
        session: connection.sessionIdentity,
      );
    } catch (e) {
      emit(
        _feedback(
          _metadataErrorMessage(e, fallback: 'Failed to drop table $table'),
          isError: true,
          status: state.status,
        ),
      );
      rethrow;
    }
  }

  Future<void> truncateTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    bool cascade = false,
  }) async {
    try {
      await repository.truncateTable(
        connection,
        database,
        table,
        schema: schema,
        cascade: cascade,
      );

      // we usually don't need to refresh tables after truncate because the table still exists
      // but if the data view is open it might need to refresh its data,
      // which is handled by the data view's own cubit, not the metadata cubit.
    } catch (e) {
      emit(
        _feedback(
          _metadataErrorMessage(e, fallback: 'Failed to truncate table $table'),
          isError: true,
          status: state.status,
        ),
      );
      rethrow;
    }
  }

  Future<void> _loadTables(
    Connection connection,
    String database, {
    String? schema,
    required int request,
    required ConnectionSessionIdentity session,
  }) async {
    final pinnedFuture = pinnedTablesRepository.getPinnedTables(
      connectionId: connection.id,
      database: database,
      schema: schema,
    );
    final tables = await repository.listTables(connection, database, schema);
    if (!_isCurrent(request, session, database: database, schema: schema)) {
      return;
    }
    final pinnedTableNames = await pinnedFuture;
    if (!_isCurrent(request, session, database: database, schema: schema)) {
      return;
    }
    final filteredTables = _filter(tables, state.query);

    emit(
      state.copyWith(
        tables: tables,
        filteredTables: filteredTables,
        pinnedTableNames: await _prunedPinnedTables(
          connection.id,
          database,
          schema,
          tables,
          pinnedTableNames,
        ),
        selectedTable: () =>
            filteredTables.isNotEmpty ? filteredTables.first : null,
        status: ConnectionMetadataStatus.idle,
      ),
    );
  }

  bool _isCurrent(
    int request,
    ConnectionSessionIdentity session, {
    String? database,
    String? schema,
  }) {
    return request == _requestGeneration &&
        state.connectionSession == session &&
        (database == null || state.selectedDatabase == database) &&
        (schema == null || state.selectedSchema == schema);
  }

  List<ConnectionTable> _filter(List<ConnectionTable> tables, String query) {
    if (query.isEmpty) return List.from(tables);

    final q = query.toLowerCase();
    return tables
        .where((table) => table.name.toLowerCase().contains(q))
        .toList();
  }

  Future<List<String>> _prunedPinnedTables(
    String connectionId,
    String database,
    String? schema,
    List<ConnectionTable> tables,
    List<String> pinnedTableNames,
  ) async {
    final existingNames = tables.map((table) => table.name).toSet();
    final pinned = pinnedTableNames.where(existingNames.contains).toList();

    if (pinned.length != pinnedTableNames.length) {
      await pinnedTablesRepository.setPinnedTables(
        connectionId: connectionId,
        database: database,
        schema: schema,
        tableNames: pinned,
      );
    }

    return pinned;
  }

  Future<void> selectSchema(
    Connection connection,
    String database,
    String schema,
  ) async {
    if (state.selectedDatabase != database || state.selectedSchema == schema) {
      return;
    }
    final session = connection.sessionIdentity;
    if (state.connectionSession != session) return;
    final request = ++_requestGeneration;

    await repository.setSelectedSchema(
      connectionId: connection.id,
      database: database,
      schema: schema,
    );

    emit(
      state.copyWith(
        selectedSchema: () => schema,
        query: '',
        tables: const [],
        filteredTables: const [],
        pinnedTableNames: const [],
        selectedTable: () => null,
        status: ConnectionMetadataStatus.loadingTables,
      ),
    );

    await _loadTables(
      connection,
      database,
      schema: schema,
      request: request,
      session: session,
    );
  }

  Future<void> createSchema(
    Connection connection,
    String database,
    String name,
  ) async {
    try {
      await repository.createSchema(connection, database, name);
      final schemas = await repository.listSchemas(connection, database);
      final session = connection.sessionIdentity;
      if (state.connectionSession != session) return;
      emit(state.copyWith(schemas: schemas));
      await selectSchema(connection, database, name);
    } catch (e) {
      emit(
        _feedback(
          _metadataErrorMessage(e, fallback: 'Failed to create schema $name'),
          isError: true,
          status: state.status,
        ),
      );
      rethrow;
    }
  }

  Future<void> _loadSchemasAndTables(
    Connection connection,
    String database, {
    required int request,
    required ConnectionSessionIdentity session,
  }) async {
    if (connection.type != ConnectionType.postgresql) {
      emit(state.copyWith(schemas: const [], selectedSchema: () => null));
      await _loadTables(
        connection,
        database,
        schema: null,
        request: request,
        session: session,
      );
      return;
    }

    final schemas = await repository.listSchemas(connection, database);
    if (!_isCurrent(request, session, database: database)) return;
    final remembered = await repository.getSelectedSchema(
      connectionId: connection.id,
      database: database,
    );
    if (!_isCurrent(request, session, database: database)) return;

    final schemaNames = schemas.map((schema) => schema.name).toSet();
    final initialSchema = remembered != null && schemaNames.contains(remembered)
        ? remembered
        : (schemaNames.contains('public')
              ? 'public'
              : (schemas.isNotEmpty ? schemas.first.name : null));

    emit(
      state.copyWith(
        schemas: schemas,
        selectedSchema: () => initialSchema,
        status: initialSchema == null
            ? ConnectionMetadataStatus.idle
            : ConnectionMetadataStatus.loadingTables,
      ),
    );

    if (initialSchema != null) {
      await repository.setSelectedSchema(
        connectionId: connection.id,
        database: database,
        schema: initialSchema,
      );
      await _loadTables(
        connection,
        database,
        schema: initialSchema,
        request: request,
        session: session,
      );
    }
  }
}
