import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysql_client_plus/exception.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/workspace_table.dart';
import '../../domain/entities/table_data.dart';
import '../../domain/repositories/workspace_metadata_repository.dart';
import 'workspace_metadata_state.dart';

class WorkspaceMetadataCubit extends Cubit<WorkspaceMetadataState> {
  final WorkspaceMetadataRepository _repository;
  int _requestGeneration = 0;

  WorkspaceMetadataCubit({required this._repository})
    : super(const WorkspaceMetadataState());

  WorkspaceMetadataState _feedback(
    String message, {
    required bool isError,
    WorkspaceMetadataStatus status = WorkspaceMetadataStatus.idle,
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
        tables: const [],
        filteredTables: const [],
        selectedTable: () => null,
        query: '',
        status: WorkspaceMetadataStatus.loadingDatabases,
      ),
    );

    try {
      final databases = await _repository.listDatabases(connection);
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
              ? WorkspaceMetadataStatus.idle
              : WorkspaceMetadataStatus.loadingTables,
        ),
      );

      if (initialDatabase != null) {
        await _loadTables(
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
          status: WorkspaceMetadataStatus.error,
        ).copyWith(
          databases: const [],
          selectedDatabase: () => null,
          tables: const [],
          filteredTables: const [],
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
        query: '',
        tables: const [],
        filteredTables: const [],
        selectedTable: () => null,
        status: WorkspaceMetadataStatus.loadingTables,
      ),
    );

    try {
      await _loadTables(
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
          status: WorkspaceMetadataStatus.error,
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

  void selectTable(WorkspaceTable table) {
    emit(state.copyWith(selectedTable: () => table));
  }

  void clear() {
    _requestGeneration++;
    emit(const WorkspaceMetadataState());
  }

  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {
    try {
      await _repository.createDatabase(
        connection,
        name,
        charset: charset,
        collation: collation,
      );

      // Refresh databases
      final databases = await _repository.listDatabases(connection);
      final session = connection.sessionIdentity;
      
      if (state.connectionSession != session) return;

      emit(state.copyWith(databases: databases));

      // Select the newly created database
      await selectDatabase(connection, name);
    } catch (e) {
      emit(
        _feedback(
          _metadataErrorMessage(
            e,
            fallback: 'Failed to create database $name',
          ),
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
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {
    try {
      await _repository.createTable(connection, database, tableName, columns);
      
      // Refresh tables
      await selectDatabase(connection, database);
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

  Future<void> _loadTables(
    Connection connection,
    String database, {
    required int request,
    required ConnectionSessionIdentity session,
  }) async {
    final tables = await _repository.listTables(connection, database);
    if (!_isCurrent(request, session, database: database)) return;
    final filteredTables = _filter(tables, state.query);

    emit(
      state.copyWith(
        tables: tables,
        filteredTables: filteredTables,
        selectedTable: () =>
            filteredTables.isNotEmpty ? filteredTables.first : null,
        status: WorkspaceMetadataStatus.idle,
      ),
    );
  }

  bool _isCurrent(
    int request,
    ConnectionSessionIdentity session, {
    String? database,
  }) {
    return request == _requestGeneration &&
        state.connectionSession == session &&
        (database == null || state.selectedDatabase == database);
  }

  List<WorkspaceTable> _filter(List<WorkspaceTable> tables, String query) {
    if (query.isEmpty) return List.from(tables);

    final q = query.toLowerCase();
    return tables
        .where((table) => table.name.toLowerCase().contains(q))
        .toList();
  }
}
