import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysql_client_plus/exception.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/workspace_table.dart';
import '../../domain/repositories/workspace_metadata_repository.dart';
import 'workspace_metadata_state.dart';

class WorkspaceMetadataCubit extends Cubit<WorkspaceMetadataState> {
  final WorkspaceMetadataRepository _repository;

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
    if (state.connectionId == connection.id && state.databases.isNotEmpty) {
      return;
    }

    emit(
      state.copyWith(
        connectionId: () => connection.id,
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
        await _loadTables(connection, initialDatabase);
      }
    } catch (e) {
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
      await _loadTables(connection, database);
    } catch (e) {
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
    emit(const WorkspaceMetadataState());
  }

  Future<void> _loadTables(Connection connection, String database) async {
    final tables = await _repository.listTables(connection, database);
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

  List<WorkspaceTable> _filter(List<WorkspaceTable> tables, String query) {
    if (query.isEmpty) return List.from(tables);

    final q = query.toLowerCase();
    return tables
        .where((table) => table.name.toLowerCase().contains(q))
        .toList();
  }
}
