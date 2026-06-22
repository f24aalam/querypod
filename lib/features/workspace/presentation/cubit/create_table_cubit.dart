import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../connections/presentation/cubit/connection_cubit.dart';
import '../../domain/entities/table_data.dart';
import 'create_table_state.dart';
import 'workspace_metadata_cubit.dart';

class CreateTableCubit extends Cubit<CreateTableState> {
  final ConnectionCubit _connectionCubit;
  final WorkspaceMetadataCubit _workspaceMetadataCubit;

  CreateTableCubit({
    required ConnectionCubit connectionCubit,
    required WorkspaceMetadataCubit workspaceMetadataCubit,
    // ignore: prefer_initializing_formals
  })  : _connectionCubit = connectionCubit,
        // ignore: prefer_initializing_formals
        _workspaceMetadataCubit = workspaceMetadataCubit,
        super(const CreateTableState());

  void setTableName(String name) {
    emit(state.copyWith(tableName: name, errorMessage: null));
  }

  void addColumn() {
    final connType = _connectionCubit.state.activeConnection?.type;
    final isSqlite = connType != null && connType.name == 'sqlite';
    final defaultType = isSqlite ? 'TEXT' : 'VARCHAR';
    final defaultLength = defaultType == 'VARCHAR' ? 255 : null;

    final columns = List<TableColumnDefinition>.from(state.columns);
    columns.add(
      TableColumnDefinition(
        name: '',
        type: defaultType,
        length: defaultLength,
      ),
    );
    emit(state.copyWith(columns: columns, errorMessage: null));
  }

  void updateColumn(int index, TableColumnDefinition column) {
    if (index < 0 || index >= state.columns.length) return;
    
    final columns = List<TableColumnDefinition>.from(state.columns);
    final oldColumn = columns[index];
    var newColumn = column;

    if (oldColumn.type != newColumn.type) {
      final type = newColumn.type.toUpperCase();
      if (type.contains('VARCHAR') || type.contains('CHAR') || type.contains('VARBINARY') || type.contains('BINARY')) {
        if (newColumn.length == null) {
          newColumn = TableColumnDefinition(
            name: newColumn.name,
            type: newColumn.type,
            length: 255,
            isPrimaryKey: newColumn.isPrimaryKey,
            isNullable: newColumn.isNullable,
            isAutoIncrement: newColumn.isAutoIncrement,
            defaultValue: newColumn.defaultValue,
          );
        }
      } else {
        newColumn = TableColumnDefinition(
          name: newColumn.name,
          type: newColumn.type,
          length: null,
          isPrimaryKey: newColumn.isPrimaryKey,
          isNullable: newColumn.isNullable,
          isAutoIncrement: newColumn.isAutoIncrement,
          defaultValue: newColumn.defaultValue,
        );
      }
    }

    columns[index] = newColumn;
    emit(state.copyWith(columns: columns, errorMessage: null));
  }

  void removeColumn(int index) {
    if (index < 0 || index >= state.columns.length) return;
    final columns = List<TableColumnDefinition>.from(state.columns);
    columns.removeAt(index);
    emit(state.copyWith(columns: columns, errorMessage: null));
  }

  Future<void> submit(String database) async {
    if (state.tableName.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Table name cannot be empty.'));
      return;
    }
    if (state.columns.isEmpty) {
      emit(state.copyWith(errorMessage: 'Table must have at least one column.'));
      return;
    }
    for (var col in state.columns) {
      if (col.name.trim().isEmpty) {
        emit(state.copyWith(errorMessage: 'Column names cannot be empty.'));
        return;
      }
    }

    final connection = _connectionCubit.state.activeConnection;

    if (connection == null) {
      emit(state.copyWith(errorMessage: 'No active connection found.'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      if (state.originalTableName != null && state.originalColumns != null) {
        await _workspaceMetadataCubit.alterTable(
          connection,
          database,
          state.originalTableName!,
          state.tableName,
          state.originalColumns!,
          state.columns,
        );
      } else {
        await _workspaceMetadataCubit.createTable(connection, database, state.tableName, state.columns);
      }
      emit(state.copyWith(isSubmitting: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> loadTableSchema(String database, String table) async {
    final connection = _connectionCubit.state.activeConnection;
    if (connection == null) return;

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final columns = await _workspaceMetadataCubit.getTableSchema(connection, database, table);
      emit(state.copyWith(
        isLoading: false,
        tableName: table,
        originalTableName: table,
        columns: columns,
        originalColumns: columns,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
