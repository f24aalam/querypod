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
  })  : _connectionCubit = connectionCubit,
        _workspaceMetadataCubit = workspaceMetadataCubit,
        super(const CreateTableState());

  void setTableName(String name) {
    emit(state.copyWith(tableName: name, errorMessage: null));
  }

  void addColumn() {
    final columns = List<TableColumnDefinition>.from(state.columns);
    columns.add(
      const TableColumnDefinition(
        name: '',
        type: 'VARCHAR',
        length: 255,
      ),
    );
    emit(state.copyWith(columns: columns, errorMessage: null));
  }

  void updateColumn(int index, TableColumnDefinition column) {
    if (index < 0 || index >= state.columns.length) return;
    final columns = List<TableColumnDefinition>.from(state.columns);
    columns[index] = column;
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
      await _workspaceMetadataCubit.createTable(connection, database, state.tableName, state.columns);
      emit(state.copyWith(isSubmitting: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }
}
