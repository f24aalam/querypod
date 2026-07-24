import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysql_client_plus/exception.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../../../core/database/database_driver_factory.dart';
import '../../domain/entities/table_data.dart';
import '../../domain/repositories/table_data_repository.dart';
import 'editor_tabs_state.dart';
import 'table_data_state.dart';

class TableDataCubit extends Cubit<TableDataState> {
  static const double minColumnWidth = 80;
  static const double maxColumnWidth = 520;

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

  Future<void> setSearch(
    TableTabKey key, {
    String? query,
    String? column,
  }) async {
    final session = state.session(key);
    if (session == null) return;

    final newQuery = query ?? session.searchQuery;
    final newColumn = column ?? session.searchColumn;

    if (session.searchQuery == newQuery && session.searchColumn == newColumn) {
      return;
    }

    final hadSearchText = session.searchQuery?.trim().isNotEmpty ?? false;
    final hasSearchText = newQuery?.trim().isNotEmpty ?? false;
    if (!hadSearchText && !hasSearchText) {
      _setSession(
        session.copyWith(
          searchQuery: () => newQuery,
          searchColumn: () => newColumn,
        ),
      );
      return;
    }

    _setSession(
      _clearTransientState(
        session.copyWith(
          searchQuery: () => newQuery,
          searchColumn: () => newColumn,
          pageIndex: 0,
        ),
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

  void pinColumn(TableTabKey key, int columnIndex) {
    final session = state.session(key);
    final columns = session?.structure?.columns;
    if (session == null ||
        columns == null ||
        columnIndex < 0 ||
        columnIndex >= columns.length ||
        session.pinnedColumnIndexes.contains(columnIndex)) {
      return;
    }
    _setSession(
      session.copyWith(
        pinnedColumnIndexes: [...session.pinnedColumnIndexes, columnIndex],
      ),
    );
  }

  void unpinColumn(TableTabKey key, [int? columnIndex]) {
    final session = state.session(key);
    if (session == null || session.pinnedColumnIndexes.isEmpty) return;
    if (columnIndex == null) {
      _setSession(session.copyWith(pinnedColumnIndexes: const []));
      return;
    }
    if (!session.pinnedColumnIndexes.contains(columnIndex)) return;
    _setSession(
      session.copyWith(
        pinnedColumnIndexes: [
          for (final index in session.pinnedColumnIndexes)
            if (index != columnIndex) index,
        ],
      ),
    );
  }

  void movePinnedColumnLeft(TableTabKey key, int columnIndex) {
    _movePinnedColumn(key, columnIndex, -1);
  }

  void movePinnedColumnRight(TableTabKey key, int columnIndex) {
    _movePinnedColumn(key, columnIndex, 1);
  }

  void _movePinnedColumn(TableTabKey key, int columnIndex, int delta) {
    final session = state.session(key);
    if (session == null) return;
    final currentIndex = session.pinnedColumnIndexes.indexOf(columnIndex);
    if (currentIndex < 0) return;
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= session.pinnedColumnIndexes.length) {
      return;
    }
    final pinned = List<int>.from(session.pinnedColumnIndexes);
    final moved = pinned.removeAt(currentIndex);
    pinned.insert(nextIndex, moved);
    _setSession(session.copyWith(pinnedColumnIndexes: pinned));
  }

  void resizeColumn(TableTabKey key, int columnIndex, double width) {
    final session = state.session(key);
    final columns = session?.structure?.columns;
    if (session == null ||
        columns == null ||
        columnIndex < 0 ||
        columnIndex >= columns.length) {
      return;
    }
    _setSession(
      session.copyWith(
        columnWidthOverrides: {
          ...session.columnWidthOverrides,
          columnIndex: width.clamp(minColumnWidth, maxColumnWidth).toDouble(),
        },
      ),
    );
  }

  void resetColumnWidth(TableTabKey key, int columnIndex) {
    final session = state.session(key);
    if (session == null ||
        !session.columnWidthOverrides.containsKey(columnIndex)) {
      return;
    }
    _setSession(
      session.copyWith(
        columnWidthOverrides: {
          for (final entry in session.columnWidthOverrides.entries)
            if (entry.key != columnIndex) entry.key: entry.value,
        },
      ),
    );
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
        foreignRowPreview: () => null,
      ),
    );
  }

  void hideTableStructure(TableTabKey key) {
    final session = state.session(key);
    if (session == null || !session.isShowingStructure) return;
    _setSession(session.copyWith(isShowingStructure: false));
  }

  Future<void> previewForeignRow(
    TableTabKey key,
    TableForeignKey fk,
    String cellValue,
  ) async {
    final session = state.session(key);
    final connection = _connections[key];
    if (session == null || connection == null) return;

    _setSession(session.copyWith(isFetchingForeignRow: true));

    try {
      final targetStructure = await repository.inspectTable(
        connection,
        key.database,
        fk.targetTable,
        key.schema,
      );

      final filter = TableFilter(
        column: fk.targetColumn,
        operator: '=',
        value: cellValue,
      );

      final resultPage = await repository.fetchRows(
        connection,
        key.database,
        fk.targetTable,
        schema: key.schema,
        structure: targetStructure,
        offset: 0,
        limit: 1,
        filters: [filter],
      );

      if (resultPage.rows.isNotEmpty) {
        final currentSession = state.session(key);
        if (currentSession != null) {
          _setSession(
            currentSession.copyWith(
              isFetchingForeignRow: false,
              selectedRowIndexes: const {},
              selectionAnchorRowIndex: () => null,
              activeCellEdit: () => null,
              isShowingStructure: false,
              foreignRowPreview: () => ForeignRowPreview(
                tableName: fk.targetTable,
                structure: targetStructure,
                row: resultPage.rows.first,
              ),
            ),
          );
        }
      } else {
        final currentSession = state.session(key);
        if (currentSession != null) {
          _setSession(currentSession.copyWith(isFetchingForeignRow: false));
        }
      }
    } catch (e) {
      final currentSession = state.session(key);
      if (currentSession != null) {
        _setSession(
          currentSession.copyWith(
            isFetchingForeignRow: false,
            errorMessage: () => 'Failed to load foreign row: $e',
            feedbackNonce: currentSession.feedbackNonce + 1,
          ),
        );
      }
    }
  }

  void clearForeignRowPreview(TableTabKey key) {
    final session = state.session(key);
    if (session == null || session.foreignRowPreview == null) return;
    _setSession(session.copyWith(foreignRowPreview: () => null));
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
        isShowingStructure: false,
        foreignRowPreview: () => null,
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
        isShowingStructure: false,
        foreignRowPreview: () => null,
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
        isShowingStructure: false,
        foreignRowPreview: () => null,
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

    _setSession(
      session.copyWith(
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

  void stageInsert(TableTabKey key) {
    final session = state.session(key);
    if (session == null || !session.isEditable || session.structure == null) {
      return;
    }

    final newRow = TableDataRow([
      for (var _ in session.structure!.columns)
        const TableCellValue.nullValue(),
    ]);

    final newRows = List<TableDataRow>.from(session.rows)..insert(0, newRow);
    const newIndex = 0;

    final shiftedInserts = <int>{newIndex};
    for (final i in session.stagedInsertedRowIndexes) {
      shiftedInserts.add(i + 1);
    }

    final shiftedDeletes = <int>{};
    for (final i in session.stagedDeletedRowIndexes) {
      shiftedDeletes.add(i + 1);
    }

    final shiftedEdits = <TableCellCoordinate, TableCellEdit>{};
    for (final edit in session.stagedCellEdits.values) {
      final newEditRowIndex = edit.rowIndex + 1;
      final newCoord = TableCellCoordinate(
        rowIndex: newEditRowIndex,
        columnIndex: edit.columnIndex,
      );
      shiftedEdits[newCoord] = edit.copyWith(rowIndex: newEditRowIndex);
    }

    final activeEdit = session.activeCellEdit?.copyWith(
      rowIndex: session.activeCellEdit!.rowIndex + 1,
    );

    _setSession(
      session.copyWith(
        rows: newRows,
        stagedInsertedRowIndexes: shiftedInserts,
        stagedDeletedRowIndexes: shiftedDeletes,
        stagedCellEdits: shiftedEdits,
        selectedRowIndexes: <int>{},
        selectionAnchorRowIndex: () => null,
        activeCellEdit: () => activeEdit,
        isShowingStructure: false,
        foreignRowPreview: () => null,
      ),
    );

    // Automatically start editing the first cell
    beginCellEdit(key, newIndex, 0);
  }

  void stageDuplicateForRow(TableTabKey key, int rowIndex) {
    final session = state.session(key);
    if (session == null ||
        !session.isEditable ||
        session.structure == null ||
        !_isValidRow(session, rowIndex)) {
      return;
    }

    List<int> targetSelection;
    if (session.selectedRowIndexes.contains(rowIndex)) {
      targetSelection = session.selectedRowIndexes.toList()..sort();
    } else {
      targetSelection = [rowIndex];
    }

    final numDuplicates = targetSelection.length;

    final newlyDuplicatedRows = <TableDataRow>[];
    for (final idx in targetSelection) {
      final existingRow = session.rows[idx];
      newlyDuplicatedRows.add(
        TableDataRow([
          for (int c = 0; c < existingRow.cells.length; c++)
            session.structure!.columns[c].isPrimaryKey
                ? const TableCellValue.nullValue()
                : existingRow.cells[c],
        ]),
      );
    }

    final newRows = List<TableDataRow>.from(newlyDuplicatedRows)
      ..addAll(session.rows);

    final shiftedInserts = <int>{};
    for (int i = 0; i < numDuplicates; i++) {
      shiftedInserts.add(i);
    }
    for (final i in session.stagedInsertedRowIndexes) {
      shiftedInserts.add(i + numDuplicates);
    }

    final shiftedDeletes = <int>{};
    for (final i in session.stagedDeletedRowIndexes) {
      shiftedDeletes.add(i + numDuplicates);
    }

    final shiftedEdits = <TableCellCoordinate, TableCellEdit>{};
    for (final edit in session.stagedCellEdits.values) {
      final newEditRowIndex = edit.rowIndex + numDuplicates;
      final newCoord = TableCellCoordinate(
        rowIndex: newEditRowIndex,
        columnIndex: edit.columnIndex,
      );
      shiftedEdits[newCoord] = edit.copyWith(rowIndex: newEditRowIndex);
    }

    for (int newIndex = 0; newIndex < numDuplicates; newIndex++) {
      final originalIdx = targetSelection[newIndex];
      final shiftedOriginalIdx = originalIdx + numDuplicates;
      final existingRow = session.rows[originalIdx];

      for (int c = 0; c < session.structure!.columns.length; c++) {
        final oldCoord = TableCellCoordinate(
          rowIndex: shiftedOriginalIdx,
          columnIndex: c,
        );
        final existingEdit = shiftedEdits[oldCoord];
        final cell = existingRow.cells[c];

        final valueStr = existingEdit?.draftText ?? cell.editText;
        final isPrimaryKey = session.structure!.columns[c].isPrimaryKey;

        if (!isPrimaryKey &&
            (valueStr.isNotEmpty ||
                cell.kind != TableCellKind.nullValue ||
                existingEdit != null)) {
          final newCoord = TableCellCoordinate(
            rowIndex: newIndex,
            columnIndex: c,
          );
          shiftedEdits[newCoord] = TableCellEdit(
            rowIndex: newIndex,
            columnIndex: c,
            originalText: '',
            draftText: valueStr,
          );
        }
      }
    }

    final activeEdit = session.activeCellEdit?.copyWith(
      rowIndex: session.activeCellEdit!.rowIndex + numDuplicates,
    );

    _setSession(
      session.copyWith(
        rows: newRows,
        stagedInsertedRowIndexes: shiftedInserts,
        stagedDeletedRowIndexes: shiftedDeletes,
        stagedCellEdits: shiftedEdits,
        selectedRowIndexes: <int>{},
        selectionAnchorRowIndex: () => null,
        activeCellEdit: () => activeEdit,
        isShowingStructure: false,
        foreignRowPreview: () => null,
      ),
    );
  }

  void stageDeleteForRow(TableTabKey key, int rowIndex) {
    final session = state.session(key);
    if (session == null ||
        !session.isEditable ||
        !_isValidRow(session, rowIndex)) {
      return;
    }

    if (session.stagedInsertedRowIndexes.contains(rowIndex)) {
      final newRows = List<TableDataRow>.from(session.rows)..removeAt(rowIndex);
      final newInserts = Set<int>.from(session.stagedInsertedRowIndexes)
        ..remove(rowIndex);

      final shiftedInserts = <int>{};
      for (final i in newInserts) {
        shiftedInserts.add(i > rowIndex ? i - 1 : i);
      }

      final shiftedDeletes = <int>{};
      for (final i in session.stagedDeletedRowIndexes) {
        shiftedDeletes.add(i > rowIndex ? i - 1 : i);
      }

      final shiftedEdits = <TableCellCoordinate, TableCellEdit>{};
      for (final edit in session.stagedCellEdits.values) {
        if (edit.rowIndex == rowIndex) continue;
        final newEditRowIndex = edit.rowIndex > rowIndex
            ? edit.rowIndex - 1
            : edit.rowIndex;
        final newCoord = TableCellCoordinate(
          rowIndex: newEditRowIndex,
          columnIndex: edit.columnIndex,
        );
        shiftedEdits[newCoord] = edit.copyWith(rowIndex: newEditRowIndex);
      }

      final shiftedSelected = <int>{};
      for (final i in session.selectedRowIndexes) {
        if (i == rowIndex) continue;
        shiftedSelected.add(i > rowIndex ? i - 1 : i);
      }

      _setSession(
        session.copyWith(
          rows: newRows,
          stagedInsertedRowIndexes: shiftedInserts,
          stagedDeletedRowIndexes: shiftedDeletes,
          stagedCellEdits: shiftedEdits,
          selectedRowIndexes: shiftedSelected,
          selectionAnchorRowIndex: () => null,
          activeCellEdit: () => null,
        ),
      );
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
    _setSession(_clearTransientState(session, clearError: false));
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

    final insertedIndexes = session.stagedInsertedRowIndexes.toList()..sort();
    final insertedRows = <Map<String, dynamic>>[];
    for (final rowIndex in insertedIndexes) {
      final rowMap = <String, dynamic>{};
      for (int c = 0; c < structure.columns.length; c++) {
        final coord = TableCellCoordinate(rowIndex: rowIndex, columnIndex: c);
        final edit = session.stagedCellEdits[coord];
        if (edit != null) {
          rowMap[structure.columns[c].name] = edit.draftText;
        }
      }
      insertedRows.add(rowMap);
    }

    final deletedIndexes = session.stagedDeletedRowIndexes.toList()..sort();
    final deletedRows = [
      for (final rowIndex in deletedIndexes) session.rows[rowIndex],
    ];

    final cellChanges =
        session.stagedCellEdits.values
            .where(
              (edit) =>
                  !session.stagedDeletedRowIndexes.contains(edit.rowIndex) &&
                  !session.stagedInsertedRowIndexes.contains(edit.rowIndex),
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
        schema: key.schema,
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
        insertedRows: insertedRows,
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
        key.schema,
      );
      if (!_isCurrent(key, generation)) return;
      final total = await repository.countRows(
        connection,
        key.database,
        key.tableName,
        schema: key.schema,
        structure: structure,
        searchQuery: current.searchQuery,
        searchColumn: current.searchColumn,
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
        schema: key.schema,
        structure: structure,
        offset: pageIndex * latest.pageSize,
        limit: latest.pageSize,
        searchQuery: current.searchQuery,
        searchColumn: current.searchColumn,
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
        schema: key.schema,
        structure: structure,
        offset: pageIndex * current.pageSize,
        limit: current.pageSize,
        searchQuery: current.searchQuery,
        searchColumn: current.searchColumn,
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
    List<TableDataRow> finalRows = session.rows;
    if (session.stagedInsertedRowIndexes.isNotEmpty) {
      final validRows = <TableDataRow>[];
      for (int i = 0; i < session.rows.length; i++) {
        if (!session.stagedInsertedRowIndexes.contains(i)) {
          validRows.add(session.rows[i]);
        }
      }
      finalRows = validRows;
    }

    return session.copyWith(
      rows: finalRows,
      selectedRowIndexes: const {},
      selectionAnchorRowIndex: () => null,
      activeCellEdit: () => null,
      stagedCellEdits: const {},
      stagedDeletedRowIndexes: const {},
      stagedInsertedRowIndexes: const {},
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
