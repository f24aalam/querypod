import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysql_client_plus/exception.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../../../core/database/database_driver_factory.dart';
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
      _clearTransientState(
        session.copyWith(pageSize: pageSize, pageIndex: 0),
        clearError: false,
      ),
    );
    await _loadPage(key, 0);
  }

  Future<void> setSearchQuery(TableTabKey key, String query) async {
    final session = state.session(key);
    if (session == null || session.searchQuery == query) return;
    _setSession(
      _clearTransientState(
        session.copyWith(searchQuery: () => query, pageIndex: 0),
        clearError: false,
      ),
    );
    await _loadInitial(key);
  }

  Future<void> setFilters(TableTabKey key, List<TableFilter> filters) async {
    final session = state.session(key);
    if (session == null) return;
    
    // Check if filters changed
    if (session.filters.length == filters.length) {
      bool changed = false;
      for (int i = 0; i < filters.length; i++) {
        if (session.filters[i] != filters[i]) {
          changed = true;
          break;
        }
      }
      if (!changed) return;
    }

    _setSession(
      _clearTransientState(
        session.copyWith(filters: filters, pageIndex: 0),
        clearError: false,
      ),
    );
    await _loadInitial(key);
  }

  List<String> supportedOperators(TableTabKey key) {
    final connection = _connections[key];
    if (connection == null) return ['=', '!=', '>', '<', 'LIKE'];
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return driver.supportedOperators;
  }

  Future<void> refresh(TableTabKey key) async {
    if (!state.sessions.containsKey(key)) return;
    await _loadInitial(key, refreshing: true);
  }

  void showTableStructure(TableTabKey key) {
    final session = state.session(key);
    if (session == null) return;
    _setSession(
      session.copyWith(
        isShowingStructure: true,
        selectedRowIndexes: const {},
        selectionAnchorRowIndex: () => null,
        activeCellEdit: () => null,
      ),
    );
  }

  void hideTableStructure(TableTabKey key) {
    final session = state.session(key);
    if (session == null || !session.isShowingStructure) return;
    _setSession(session.copyWith(isShowingStructure: false));
  }

  void activateCell(
    TableTabKey key,
    int rowIndex,
    int columnIndex, {
    bool toggleSelection = false,
    bool extendSelection = false,
  }) {
    final session = state.session(key);
    if (session == null || rowIndex < 0 || rowIndex >= session.rows.length) {
      return;
    }

    if (toggleSelection) {
      _lastCellClicks.remove(key);
      toggleRowSelection(key, rowIndex);
      return;
    }

    if (extendSelection) {
      _lastCellClicks.remove(key);
      selectRowRange(key, rowIndex);
      return;
    }

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
    selectSingleRow(key, rowIndex);
  }

  void selectSingleRow(TableTabKey key, int rowIndex) {
    final session = state.session(key);
    if (!_isValidRow(session, rowIndex)) return;
    _setSession(
      session!.copyWith(
        selectedRowIndexes: {rowIndex},
        selectionAnchorRowIndex: () => rowIndex,
        activeCellEdit: () => null,
      ),
    );
  }

  void toggleRowSelection(TableTabKey key, int rowIndex) {
    final session = state.session(key);
    if (!_isValidRow(session, rowIndex)) return;
    final selected = Set<int>.from(session!.selectedRowIndexes);
    if (!selected.remove(rowIndex)) {
      selected.add(rowIndex);
    }
    _setSession(
      session.copyWith(
        selectedRowIndexes: selected,
        selectionAnchorRowIndex: () => rowIndex,
        activeCellEdit: () => null,
      ),
    );
  }

  void selectRowRange(TableTabKey key, int rowIndex) {
    final session = state.session(key);
    if (!_isValidRow(session, rowIndex)) return;
    final anchor = session!.selectionAnchorRowIndex ?? rowIndex;
    final start = anchor < rowIndex ? anchor : rowIndex;
    final end = anchor > rowIndex ? anchor : rowIndex;
    _setSession(
      session.copyWith(
        selectedRowIndexes: {
          for (var index = start; index <= end; index++) index,
        },
        selectionAnchorRowIndex: () => anchor,
        activeCellEdit: () => null,
      ),
    );
  }

  void clearSelection(TableTabKey key) {
    final session = state.session(key);
    if (session == null || !session.hasSelection) return;
    _setSession(
      session.copyWith(
        selectedRowIndexes: <int>{},
        selectionAnchorRowIndex: () => null,
        activeCellEdit: () => null,
      ),
    );
  }

  void beginCellEdit(TableTabKey key, int rowIndex, int columnIndex) {
    final session = state.session(key);
    if (session == null ||
        !session.isEditable ||
        !_isValidRow(session, rowIndex) ||
        columnIndex < 0 ||
        columnIndex >= session.rows[rowIndex].cells.length ||
        session.stagedDeletedRowIndexes.contains(rowIndex)) {
      return;
    }

    final coordinate = TableCellCoordinate(
      rowIndex: rowIndex,
      columnIndex: columnIndex,
    );
    final value = session.rows[rowIndex].cells[columnIndex];
    final activeEdit =
        session.stagedCellEdits[coordinate] ??
        TableCellEdit(
          rowIndex: rowIndex,
          columnIndex: columnIndex,
          originalText: value.editText,
          draftText: value.editText,
        );

    final selectedRows = session.selectedRowIndexes.contains(rowIndex)
        ? session.selectedRowIndexes
        : {rowIndex};

    _setSession(
      session.copyWith(
        selectedRowIndexes: selectedRows,
        selectionAnchorRowIndex: () => rowIndex,
        activeCellEdit: () => activeEdit,
      ),
    );
  }

  void updateCellDraft(TableTabKey key, String value) {
    final session = state.session(key);
    final edit = session?.activeCellEdit;
    if (session == null || edit == null) return;

    final updatedEdit = edit.copyWith(draftText: value);
    final staged = Map<TableCellCoordinate, TableCellEdit>.from(
      session.stagedCellEdits,
    );
    if (updatedEdit.isDirty) {
      staged[updatedEdit.coordinate] = updatedEdit;
    } else {
      staged.remove(updatedEdit.coordinate);
    }

    _setSession(
      session.copyWith(
        activeCellEdit: () => updatedEdit,
        stagedCellEdits: staged,
      ),
    );
  }

  void cancelActiveCellEdit(TableTabKey key) {
    final session = state.session(key);
    if (session == null || session.activeCellEdit == null) return;
    _setSession(session.copyWith(activeCellEdit: () => null));
  }

  void stageDeleteForRow(TableTabKey key, int rowIndex) {
    final session = state.session(key);
    if (session == null ||
        !session.isEditable ||
        !_isValidRow(session, rowIndex)) {
      return;
    }

    final targetSelection = session.selectedRowIndexes.contains(rowIndex)
        ? session.selectedRowIndexes
        : {rowIndex};
    final stagedDeletes = Set<int>.from(session.stagedDeletedRowIndexes)
      ..addAll(targetSelection);

    _setSession(
      session.copyWith(
        selectedRowIndexes: targetSelection,
        selectionAnchorRowIndex: () => rowIndex,
        stagedDeletedRowIndexes: stagedDeletes,
        activeCellEdit: () => null,
      ),
    );
  }

  void clearPendingChanges(TableTabKey key) {
    final session = state.session(key);
    if (session == null || !session.hasPendingChanges) return;
    _setSession(
      session.copyWith(
        activeCellEdit: () => null,
        stagedCellEdits: const {},
        stagedDeletedRowIndexes: const {},
      ),
    );
  }

  Future<void> commitPendingChanges(TableTabKey key) async {
    final connection = _connections[key];
    final session = state.session(key);
    final structure = session?.structure;
    if (connection == null ||
        session == null ||
        structure == null ||
        !session.hasPendingChanges ||
        session.isCommittingChanges) {
      return;
    }

    final deletedIndexes = session.stagedDeletedRowIndexes.toList()..sort();
    final deletedRows = [
      for (final rowIndex in deletedIndexes) session.rows[rowIndex],
    ];

    final cellChanges =
        session.stagedCellEdits.values
            .where(
              (edit) =>
                  !session.stagedDeletedRowIndexes.contains(edit.rowIndex),
            )
            .toList()
          ..sort((a, b) {
            final rowCompare = a.rowIndex.compareTo(b.rowIndex);
            if (rowCompare != 0) return rowCompare;
            return a.columnIndex.compareTo(b.columnIndex);
          });

    _setSession(session.copyWith(isCommittingChanges: true));
    try {
      await repository.commitChanges(
        connection,
        key.database,
        key.tableName,
        structure: structure,
        cellChanges: [
          for (final edit in cellChanges)
            TableCellChange(
              row: session.rows[edit.rowIndex],
              columnIndex: edit.columnIndex,
              value: edit.draftText,
            ),
        ],
        deletedRows: deletedRows,
      );
      final latest = state.session(key);
      if (latest == null) return;
      _setSession(_clearTransientState(latest, clearError: false));
      await _loadInitial(key, refreshing: true);
    } catch (error) {
      final latest = state.session(key);
      if (latest == null) return;
      _setSession(
        latest.copyWith(
          isCommittingChanges: false,
          errorMessage: () => _commitErrorMessage(error),
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
      _clearTransientState(
        current.copyWith(
          status: refreshing && current.hasRows
              ? TableDataStatus.refreshing
              : TableDataStatus.initialLoading,
        ),
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
        structure: structure,
        searchQuery: current.searchQuery,
        filters: current.filters,
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
        searchQuery: current.searchQuery,
        filters: current.filters,
      );
      if (!_isCurrent(key, generation)) return;

      _setSession(
        _clearTransientState(
          latest.copyWith(
            structure: () => structure,
            rows: page.rows,
            totalCount: total,
            pageIndex: pageIndex,
            queryDuration: page.queryDuration,
            status: TableDataStatus.ready,
          ),
        ),
      );
    } catch (error) {
      _handleError(key, generation, error);
    }
  }

  Future<void> _loadPage(TableTabKey key, int pageIndex) async {
    final connection = _connections[key];
    final current = state.session(key);
    final structure = current?.structure;
    if (connection == null || current == null || structure == null) return;
    final generation = _nextGeneration(key);

    _setSession(
      _clearTransientState(
        current.copyWith(status: TableDataStatus.pageLoading),
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
        searchQuery: current.searchQuery,
        filters: current.filters,
      );
      if (!_isCurrent(key, generation)) return;

      _setSession(
        _clearTransientState(
          current.copyWith(
            rows: page.rows,
            pageIndex: pageIndex,
            queryDuration: page.queryDuration,
            status: TableDataStatus.ready,
          ),
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

  TableDataSession _clearTransientState(
    TableDataSession session, {
    bool clearError = true,
  }) {
    return session.copyWith(
      selectedRowIndexes: const {},
      selectionAnchorRowIndex: () => null,
      activeCellEdit: () => null,
      stagedCellEdits: const {},
      stagedDeletedRowIndexes: const {},
      isCommittingChanges: false,
      errorMessage: clearError ? () => null : null,
    );
  }

  bool _isValidRow(TableDataSession? session, int rowIndex) {
    return session != null && rowIndex >= 0 && rowIndex < session.rows.length;
  }

  String _errorMessage(Object error) {
    if (error is MySQLException && error.message.isNotEmpty) {
      return 'Failed to load table: ${error.message}';
    }
    return 'Failed to load table: $error';
  }

  String _commitErrorMessage(Object error) {
    if (error is MySQLException && error.message.isNotEmpty) {
      return 'Failed to commit changes: ${error.message}';
    }
    if (error is FormatException) return error.message;
    return 'Failed to commit changes: $error';
  }

  int _nextGeneration(TableTabKey key) {
    final generation = (_generations[key] ?? 0) + 1;
    _generations[key] = generation;
    return generation;
  }

  bool _isCurrent(TableTabKey key, int generation) {
    return (_generations[key] ?? 0) == generation;
  }

  void _setSession(TableDataSession session) {
    final sessions = Map<TableTabKey, TableDataSession>.from(state.sessions)
      ..[session.key] = session;
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
