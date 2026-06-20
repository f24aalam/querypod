import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysql_client_plus/exception.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/table_data.dart';
import '../../domain/repositories/table_data_repository.dart';
import 'editor_tabs_state.dart';
import 'table_data_state.dart';

class TableDataCubit extends Cubit<TableDataState> {
  final TableDataRepository repository;
  final Map<TableTabKey, Connection> _connections = {};
  final Map<TableTabKey, int> _generations = {};
  final Map<TableTabKey, _CellClick> _lastCellClicks = {};

  TableDataCubit({required this.repository}) : super(TableDataState());

  Future<void> openTable(Connection connection, TableTabKey key) async {
    _connections[key] = connection;
    if (state.sessions.containsKey(key)) return;

    _setSession(TableDataSession(key: key));
    await _loadInitial(key);
  }

  Future<void> previousPage(TableTabKey key) async {
    final session = state.session(key);
    if (session == null || !session.canGoPrevious) return;
    await _loadPage(key, session.pageIndex - 1);
  }

  Future<void> nextPage(TableTabKey key) async {
    final session = state.session(key);
    if (session == null || !session.canGoNext) return;
    await _loadPage(key, session.pageIndex + 1);
  }

  Future<void> setPageSize(TableTabKey key, int pageSize) async {
    final session = state.session(key);
    if (session == null || session.pageSize == pageSize) return;
    _setSession(
      session.copyWith(
        pageSize: pageSize,
        pageIndex: 0,
        selectedRowIndex: () => null,
        cellEdit: () => null,
        rowDelete: () => null,
      ),
    );
    await _loadPage(key, 0);
  }

  Future<void> refresh(TableTabKey key) async {
    if (!state.sessions.containsKey(key)) return;
    await _loadInitial(key, refreshing: true);
  }

  void selectRow(TableTabKey key, int index) {
    final session = state.session(key);
    if (session == null || index < 0 || index >= session.rows.length) return;
    if (session.selectedRowIndex == index) return;
    _setSession(session.copyWith(selectedRowIndex: () => index));
  }

  void clearRowSelection(TableTabKey key) {
    final session = state.session(key);
    if (session == null || session.selectedRowIndex == null) return;
    _setSession(session.copyWith(selectedRowIndex: () => null));
  }

  void beginCellEdit(TableTabKey key, int rowIndex, int columnIndex) {
    final session = state.session(key);
    if (session == null ||
        !session.isEditable ||
        session.rowDelete != null ||
        rowIndex < 0 ||
        rowIndex >= session.rows.length ||
        columnIndex < 0 ||
        columnIndex >= session.rows[rowIndex].cells.length) {
      return;
    }
    final value = session.rows[rowIndex].cells[columnIndex];
    _setSession(
      session.copyWith(
        selectedRowIndex: () => rowIndex,
        cellEdit: () => TableCellEdit(
          rowIndex: rowIndex,
          columnIndex: columnIndex,
          originalText: value.editText,
          draftText: value.editText,
        ),
      ),
    );
  }

  void activateCell(TableTabKey key, int rowIndex, int columnIndex) {
    final now = DateTime.now();
    final lastClick = _lastCellClicks[key];
    final isDoubleClick =
        lastClick != null &&
        lastClick.rowIndex == rowIndex &&
        lastClick.columnIndex == columnIndex &&
        now.difference(lastClick.timestamp) <=
            const Duration(milliseconds: 500);

    if (isDoubleClick) {
      _lastCellClicks.remove(key);
      beginCellEdit(key, rowIndex, columnIndex);
      return;
    }

    _lastCellClicks[key] = _CellClick(
      rowIndex: rowIndex,
      columnIndex: columnIndex,
      timestamp: now,
    );
    selectRow(key, rowIndex);
  }

  void updateCellDraft(TableTabKey key, String value) {
    final session = state.session(key);
    final edit = session?.cellEdit;
    if (session == null || edit == null || edit.isSaving) return;
    _setSession(
      session.copyWith(cellEdit: () => edit.copyWith(draftText: value)),
    );
  }

  void cancelCellEdit(TableTabKey key) {
    final session = state.session(key);
    if (session == null || session.cellEdit == null) return;
    _setSession(session.copyWith(cellEdit: () => null));
  }

  void stageRowDelete(TableTabKey key, int rowIndex) {
    final session = state.session(key);
    if (session == null ||
        !session.isEditable ||
        session.rowDelete != null ||
        rowIndex < 0 ||
        rowIndex >= session.rows.length ||
        (session.cellEdit?.isDirty ?? false)) {
      return;
    }
    _setSession(
      session.copyWith(
        selectedRowIndex: () => rowIndex,
        cellEdit: () => null,
        rowDelete: () => TableRowDelete(rowIndex: rowIndex),
      ),
    );
  }

  void cancelRowDelete(TableTabKey key) {
    final session = state.session(key);
    if (session == null || session.rowDelete == null) return;
    _setSession(session.copyWith(rowDelete: () => null));
  }

  Future<void> commitRowDelete(TableTabKey key) async {
    final connection = _connections[key];
    final session = state.session(key);
    final deletion = session?.rowDelete;
    final structure = session?.structure;
    if (connection == null ||
        session == null ||
        deletion == null ||
        structure == null ||
        deletion.isSaving) {
      return;
    }

    _setSession(
      session.copyWith(rowDelete: () => deletion.copyWith(isSaving: true)),
    );
    try {
      await repository.deleteRow(
        connection,
        key.database,
        key.tableName,
        structure: structure,
        row: session.rows[deletion.rowIndex],
      );
      final latest = state.session(key);
      if (latest == null) return;
      _setSession(
        latest.copyWith(rowDelete: () => null, selectedRowIndex: () => null),
      );
      await _loadInitial(key, refreshing: true);
    } catch (error) {
      final latest = state.session(key);
      if (latest == null) return;
      _setSession(
        latest.copyWith(
          rowDelete: () => deletion,
          errorMessage: () => _deleteErrorMessage(error),
          feedbackNonce: latest.feedbackNonce + 1,
        ),
      );
    }
  }

  Future<void> commitCellEdit(TableTabKey key) async {
    final connection = _connections[key];
    final session = state.session(key);
    final edit = session?.cellEdit;
    final structure = session?.structure;
    if (connection == null ||
        session == null ||
        edit == null ||
        structure == null ||
        !edit.isDirty ||
        edit.isSaving) {
      return;
    }

    _setSession(
      session.copyWith(cellEdit: () => edit.copyWith(isSaving: true)),
    );
    try {
      await repository.updateCell(
        connection,
        key.database,
        key.tableName,
        structure: structure,
        row: session.rows[edit.rowIndex],
        columnIndex: edit.columnIndex,
        value: edit.draftText,
      );
      final latest = state.session(key);
      if (latest == null) return;
      _setSession(latest.copyWith(cellEdit: () => null));
      await _loadPage(key, latest.pageIndex, preserveSelection: true);
    } catch (error) {
      final latest = state.session(key);
      if (latest == null) return;
      _setSession(
        latest.copyWith(
          cellEdit: () => edit,
          errorMessage: () => _saveErrorMessage(error),
          feedbackNonce: latest.feedbackNonce + 1,
        ),
      );
    }
  }

  void closeSession(TableTabKey key) {
    _generations[key] = (_generations[key] ?? 0) + 1;
    _connections.remove(key);
    _lastCellClicks.remove(key);
    if (!state.sessions.containsKey(key)) return;
    final sessions = Map<TableTabKey, TableDataSession>.from(state.sessions)
      ..remove(key);
    emit(TableDataState(sessions: sessions));
  }

  void clear() {
    for (final key in _generations.keys.toList()) {
      _generations[key] = (_generations[key] ?? 0) + 1;
    }
    _connections.clear();
    _lastCellClicks.clear();
    emit(TableDataState());
  }

  Future<void> _loadInitial(TableTabKey key, {bool refreshing = false}) async {
    final connection = _connections[key];
    final current = state.session(key);
    if (connection == null || current == null) return;
    final generation = _nextGeneration(key);

    _setSession(
      current.copyWith(
        status: refreshing && current.hasRows
            ? TableDataStatus.refreshing
            : TableDataStatus.initialLoading,
        errorMessage: () => null,
        cellEdit: () => null,
        rowDelete: () => null,
      ),
    );

    try {
      final structure = await repository.inspectTable(
        connection,
        key.database,
        key.tableName,
      );
      if (!_isCurrent(key, generation)) return;
      final total = await repository.countRows(
        connection,
        key.database,
        key.tableName,
      );
      if (!_isCurrent(key, generation)) return;

      final latest = state.session(key);
      if (latest == null) return;
      final maxPage = total == 0 ? 0 : (total - 1) ~/ latest.pageSize;
      final pageIndex = latest.pageIndex.clamp(0, maxPage);
      final page = await repository.fetchRows(
        connection,
        key.database,
        key.tableName,
        structure: structure,
        offset: pageIndex * latest.pageSize,
        limit: latest.pageSize,
      );
      if (!_isCurrent(key, generation)) return;

      _setSession(
        latest.copyWith(
          structure: () => structure,
          rows: page.rows,
          totalCount: total,
          pageIndex: pageIndex,
          selectedRowIndex: () => null,
          cellEdit: () => null,
          rowDelete: () => null,
          queryDuration: page.queryDuration,
          status: TableDataStatus.ready,
          errorMessage: () => null,
        ),
      );
    } catch (error) {
      _handleError(key, generation, error);
    }
  }

  Future<void> _loadPage(
    TableTabKey key,
    int pageIndex, {
    bool preserveSelection = false,
  }) async {
    final connection = _connections[key];
    final current = state.session(key);
    final structure = current?.structure;
    if (connection == null || current == null || structure == null) return;
    final generation = _nextGeneration(key);

    _setSession(
      current.copyWith(
        status: TableDataStatus.pageLoading,
        errorMessage: () => null,
        cellEdit: () => null,
        rowDelete: () => null,
      ),
    );

    try {
      final page = await repository.fetchRows(
        connection,
        key.database,
        key.tableName,
        structure: structure,
        offset: pageIndex * current.pageSize,
        limit: current.pageSize,
      );
      if (!_isCurrent(key, generation)) return;

      _setSession(
        current.copyWith(
          rows: page.rows,
          pageIndex: pageIndex,
          selectedRowIndex: () =>
              preserveSelection ? current.selectedRowIndex : null,
          cellEdit: () => null,
          rowDelete: () => null,
          queryDuration: page.queryDuration,
          status: TableDataStatus.ready,
          errorMessage: () => null,
        ),
      );
    } catch (error) {
      _handleError(key, generation, error);
    }
  }

  void _handleError(TableTabKey key, int generation, Object error) {
    if (!_isCurrent(key, generation)) return;
    final session = state.session(key);
    if (session == null) return;
    final message = _errorMessage(error);
    _setSession(
      session.copyWith(
        status: TableDataStatus.error,
        errorMessage: () => message,
        feedbackNonce: session.feedbackNonce + 1,
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is MySQLException && error.message.isNotEmpty) {
      return 'Failed to load table: ${error.message}';
    }
    return 'Failed to load table: $error';
  }

  String _saveErrorMessage(Object error) {
    if (error is MySQLException && error.message.isNotEmpty) {
      return 'Failed to save cell: ${error.message}';
    }
    if (error is FormatException) return error.message;
    return 'Failed to save cell: $error';
  }

  String _deleteErrorMessage(Object error) {
    if (error is MySQLException && error.message.isNotEmpty) {
      return 'Failed to delete row: ${error.message}';
    }
    return 'Failed to delete row: $error';
  }

  int _nextGeneration(TableTabKey key) {
    final generation = (_generations[key] ?? 0) + 1;
    _generations[key] = generation;
    return generation;
  }

  bool _isCurrent(TableTabKey key, int generation) =>
      _generations[key] == generation && state.sessions.containsKey(key);

  void _setSession(TableDataSession session) {
    final sessions = Map<TableTabKey, TableDataSession>.from(state.sessions);
    sessions[session.key] = session;
    emit(TableDataState(sessions: sessions));
  }
}

class _CellClick {
  final int rowIndex;
  final int columnIndex;
  final DateTime timestamp;

  const _CellClick({
    required this.rowIndex,
    required this.columnIndex,
    required this.timestamp,
  });
}
