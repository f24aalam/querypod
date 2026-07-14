import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/domain/entities/query_result.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';
import 'package:querypod/features/editor/domain/repositories/table_data_repository.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_state.dart';
import 'package:querypod/features/editor/presentation/cubit/table_data_cubit.dart';
import 'package:querypod/features/editor/presentation/cubit/table_data_state.dart';

void main() {
  const connection = Connection(
    id: 'connection',
    name: 'Local',
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: '',
    database: 'app',
    workspaceId: 'default',
  );
  const key = TableTabKey(
    connectionId: 'connection',
    database: 'app',
    tableName: 'users',
  );

  test('initial open loads structure, count, and first page', () async {
    final repository = _FakeTableDataRepository(total: 123);
    final cubit = TableDataCubit(repository: repository);

    await cubit.openTable(connection, key);

    final session = cubit.state.session(key)!;
    expect(session.status, TableDataStatus.ready);
    expect(session.pageSize, 50);
    expect(session.rows, hasLength(50));
    expect(session.rangeStart, 1);
    expect(session.rangeEnd, 50);
    expect(session.totalCount, 123);
    expect(repository.countCalls, 1);
    expect(repository.requests.single.offset, 0);
  });

  test('next and previous pages reuse the exact count', () async {
    final repository = _FakeTableDataRepository(total: 123);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    await cubit.nextPage(key);
    expect(cubit.state.session(key)!.pageIndex, 1);
    expect(cubit.state.session(key)!.rangeStart, 51);
    expect(repository.requests.last.offset, 50);

    await cubit.previousPage(key);
    expect(cubit.state.session(key)!.pageIndex, 0);
    expect(repository.countCalls, 1);
  });

  test('page size resets to the first page and reuses count', () async {
    final repository = _FakeTableDataRepository(total: 123);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);
    await cubit.nextPage(key);

    await cubit.setPageSize(key, 25);

    final session = cubit.state.session(key)!;
    expect(session.pageIndex, 0);
    expect(session.pageSize, 25);
    expect(session.rows, hasLength(25));
    expect(repository.requests.last, const _PageRequest(offset: 0, limit: 25));
    expect(repository.countCalls, 1);
  });

  test('final page exposes the partial range and disables next', () async {
    final repository = _FakeTableDataRepository(total: 123);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);
    await cubit.nextPage(key);
    await cubit.nextPage(key);

    final session = cubit.state.session(key)!;
    expect(session.rangeStart, 101);
    expect(session.rangeEnd, 123);
    expect(session.rows, hasLength(23));
    expect(session.canGoNext, isFalse);
  });

  test('page errors retain previous rows and expose retry state', () async {
    final repository = _FakeTableDataRepository(total: 123);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);
    repository.failNextPage = true;

    await cubit.nextPage(key);

    final session = cubit.state.session(key)!;
    expect(session.status, TableDataStatus.error);
    expect(session.rows, hasLength(50));
    expect(session.pageIndex, 0);
    expect(session.errorMessage, contains('page failure'));
  });

  test('refresh recalculates count and clamps an invalid page', () async {
    final repository = _FakeTableDataRepository(total: 123);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);
    await cubit.nextPage(key);
    await cubit.nextPage(key);
    repository.total = 40;

    await cubit.refresh(key);

    final session = cubit.state.session(key)!;
    expect(session.totalCount, 40);
    expect(session.pageIndex, 0);
    expect(session.rows, hasLength(40));
    expect(repository.countCalls, 2);
  });

  test('stale page response cannot replace a newer page size', () async {
    final repository = _ControlledPageRepository();
    final cubit = TableDataCubit(repository: repository);
    final opening = cubit.openTable(connection, key);
    await Future<void>.delayed(Duration.zero);
    repository.completeRequest(0, 50);
    await opening;

    final oldPage = cubit.nextPage(key);
    await Future<void>.delayed(Duration.zero);
    final newSize = cubit.setPageSize(key, 25);
    await Future<void>.delayed(Duration.zero);
    repository.completeRequest(0, 25);
    await newSize;
    repository.completeRequest(50, 50);
    await oldPage;

    final session = cubit.state.session(key)!;
    expect(session.pageSize, 25);
    expect(session.pageIndex, 0);
    expect(session.rows, hasLength(25));
  });

  test('ctrl toggle and shift range selection stay on current page', () async {
    final repository = _FakeTableDataRepository(total: 10);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    cubit.activateCell(key, 1, 0);
    cubit.activateCell(key, 3, 0, toggleSelection: true);
    cubit.activateCell(key, 5, 0, extendSelection: true);

    final session = cubit.state.session(key)!;
    expect(session.selectedRowIndexes, {3, 4, 5});
    expect(session.selectionAnchorRowIndex, 3);
  });

  test(
    'multiple cell changes remain local until commit is requested',
    () async {
      final repository = _FakeTableDataRepository(
        total: 3,
        structure: _multiColumn,
      );
      final cubit = TableDataCubit(repository: repository);
      await cubit.openTable(connection, key);

      cubit.beginCellEdit(key, 0, 1);
      cubit.updateCellDraft(key, 'Alicia');
      cubit.beginCellEdit(key, 1, 1);
      cubit.updateCellDraft(key, 'Bobby');

      final session = cubit.state.session(key)!;
      expect(session.stagedCellEdits, hasLength(2));
      expect(repository.commitRequests, isEmpty);

      await cubit.commitPendingChanges(key);

      expect(repository.commitRequests, hasLength(1));
      expect(
        repository.commitRequests.single.cellChanges
            .map((change) => change.value)
            .toList(),
        ['Alicia', 'Bobby'],
      );
      expect(cubit.state.session(key)!.hasPendingChanges, isFalse);
    },
  );

  test(
    'tables without a primary key cannot enter edit or delete mode',
    () async {
      final repository = _FakeTableDataRepository(
        total: 1,
        structure: TableStructure(
          columns: const [
            TableDataColumn(
              name: 'name',
              databaseType: 'varchar(255)',
              length: 255,
              isPrimaryKey: false,
              isNullable: true,
            ),
          ],
          orderColumn: 'name',
        ),
      );
      final cubit = TableDataCubit(repository: repository);
      await cubit.openTable(connection, key);

      cubit.beginCellEdit(key, 0, 0);
      cubit.stageDeleteForRow(key, 0);

      expect(cubit.state.session(key)!.isEditable, isFalse);
      expect(cubit.state.session(key)!.activeCellEdit, isNull);
      expect(cubit.state.session(key)!.stagedDeletedRowIndexes, isEmpty);
    },
  );

  test('right click delete stages the whole current selection', () async {
    final repository = _FakeTableDataRepository(total: 3);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    cubit.selectSingleRow(key, 0);
    cubit.toggleRowSelection(key, 1);
    cubit.stageDeleteForRow(key, 1);

    final session = cubit.state.session(key)!;
    expect(session.selectedRowIndexes, {0, 1});
    expect(session.stagedDeletedRowIndexes, {0, 1});
    expect(repository.commitRequests, isEmpty);
  });

  test('mixed edits and deletes commit in one batch transaction', () async {
    final repository = _FakeTableDataRepository(
      total: 3,
      structure: _multiColumn,
    );
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    cubit.beginCellEdit(key, 0, 1);
    cubit.updateCellDraft(key, 'Alicia');
    cubit.selectSingleRow(key, 1);
    cubit.toggleRowSelection(key, 2);
    cubit.stageDeleteForRow(key, 2);

    await cubit.commitPendingChanges(key);

    final request = repository.commitRequests.single;
    expect(request.cellChanges, hasLength(1));
    expect(request.deletedRows, hasLength(2));
  });

  test(
    'failed batch commit keeps all staged changes and exposes feedback',
    () async {
      final repository = _FakeTableDataRepository(
        total: 2,
        structure: _multiColumn,
      )..commitError = Exception('foreign key constraint');
      final cubit = TableDataCubit(repository: repository);
      await cubit.openTable(connection, key);

      cubit.beginCellEdit(key, 0, 1);
      cubit.updateCellDraft(key, 'Alicia');
      cubit.stageDeleteForRow(key, 1);

      await cubit.commitPendingChanges(key);

      final session = cubit.state.session(key)!;
      expect(session.hasPendingChanges, isTrue);
      expect(session.isCommittingChanges, isFalse);
      expect(session.errorMessage, contains('foreign key constraint'));
      expect(session.feedbackNonce, 1);
    },
  );

  test('page change clears selection and staged changes', () async {
    final repository = _FakeTableDataRepository(
      total: 100,
      structure: _multiColumn,
    );
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    cubit.beginCellEdit(key, 0, 1);
    cubit.updateCellDraft(key, 'Alicia');
    cubit.selectSingleRow(key, 0);
    cubit.toggleRowSelection(key, 1);

    await cubit.nextPage(key);

    final session = cubit.state.session(key)!;
    expect(session.selectedRowIndexes, isEmpty);
    expect(session.stagedCellEdits, isEmpty);
    expect(session.stagedDeletedRowIndexes, isEmpty);
  });

  test('opening the same table twice reuses the existing session', () async {
    final repository = _FakeTableDataRepository(total: 10);
    final cubit = TableDataCubit(repository: repository);

    await cubit.openTable(connection, key);
    await cubit.openTable(connection, key);

    expect(repository.countCalls, 1);
    expect(repository.requests, hasLength(1));
  });

  test('search resets pagination and avoids unchanged reloads', () async {
    final repository = _FakeTableDataRepository(total: 30);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);
    await cubit.nextPage(key);

    await cubit.setSearch(key, query: 'alice');

    var session = cubit.state.session(key)!;
    expect(session.searchQuery, 'alice');
    expect(session.searchColumn, isNull);
    expect(session.pageIndex, 0);
    expect(repository.countCalls, 2);

    await cubit.setSearch(key, query: 'alice');
    expect(repository.countCalls, 2);
    
    await cubit.setSearch(key, query: 'alice', column: 'name');
    session = cubit.state.session(key)!;
    expect(session.searchQuery, 'alice');
    expect(session.searchColumn, 'name');
    expect(session.pageIndex, 0);
    expect(repository.countCalls, 3);
  });

  test('filters reset pagination and avoid unchanged reloads', () async {
    final repository = _FakeTableDataRepository(total: 30);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);
    await cubit.nextPage(key);

    const filters = [TableFilter(column: 'name', operator: '=', value: 'Alice')];
    await cubit.setFilters(key, filters);

    final session = cubit.state.session(key)!;
    expect(session.filters, filters);
    expect(session.pageIndex, 0);
    expect(repository.countCalls, 2);

    await cubit.setFilters(key, filters);
    expect(repository.countCalls, 2);
  });

  test('showing and hiding table structure clears transient state', () async {
    final repository = _FakeTableDataRepository(total: 10, structure: _multiColumn);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);
    cubit.selectSingleRow(key, 0);
    cubit.beginCellEdit(key, 0, 1);

    cubit.showTableStructure(key);
    final shown = cubit.state.session(key)!;
    expect(shown.isShowingStructure, isTrue);
    expect(shown.selectedRowIndexes, isEmpty);
    expect(shown.activeCellEdit, isNull);

    cubit.hideTableStructure(key);
    expect(cubit.state.session(key)!.isShowingStructure, isFalse);
  });

  test('foreign row preview stores result clears on close and surfaces errors', () async {
    final repository = _FakeTableDataRepository(
      total: 1,
      structure: TableStructure(
        columns: const [
          TableDataColumn(
            name: 'id',
            databaseType: 'int',
            length: 11,
            isPrimaryKey: true,
            isNullable: false,
          ),
          TableDataColumn(
            name: 'profile_id',
            databaseType: 'int',
            length: 11,
            isPrimaryKey: false,
            isNullable: true,
            foreignKey: TableForeignKey(targetTable: 'profiles', targetColumn: 'id'),
          ),
        ],
        orderColumn: 'id',
      ),
      foreignPreviewStructure: TableStructure(
        columns: const [
          TableDataColumn(
            name: 'id',
            databaseType: 'int',
            length: 11,
            isPrimaryKey: true,
            isNullable: false,
          ),
          TableDataColumn(
            name: 'bio',
            databaseType: 'text',
            length: 0,
            isPrimaryKey: false,
            isNullable: true,
          ),
        ],
        orderColumn: 'id',
      ),
      foreignPreviewRows: [
        TableDataRow([TableCellValue.text('1'), TableCellValue.text('Builder')]),
      ],
    );
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    await cubit.previewForeignRow(
      key,
      const TableForeignKey(targetTable: 'profiles', targetColumn: 'id'),
      '1',
    );

    final previewed = cubit.state.session(key)!;
    expect(previewed.foreignRowPreview, isNotNull);
    expect(previewed.foreignRowPreview!.tableName, 'profiles');

    cubit.clearForeignRowPreview(key);
    expect(cubit.state.session(key)!.foreignRowPreview, isNull);

    repository.foreignPreviewError = Exception('preview failed');
    await cubit.previewForeignRow(
      key,
      const TableForeignKey(targetTable: 'profiles', targetColumn: 'id'),
      '1',
    );
    expect(cubit.state.session(key)!.errorMessage, contains('preview failed'));
  });

  test('supported operators fall back before a connection is opened', () {
    final cubit = TableDataCubit(repository: _FakeTableDataRepository(total: 1));

    expect(cubit.supportedOperators(key), ['=', '!=', '>', '<', 'LIKE']);
  });

  test('closeSession and clear remove cached table sessions', () async {
    final repository = _FakeTableDataRepository(total: 10);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    cubit.closeSession(key);
    expect(cubit.state.session(key), isNull);

    await cubit.openTable(connection, key);
    cubit.clear();
    expect(cubit.state.sessions, isEmpty);
  });
}

class _FakeTableDataRepository implements TableDataRepository {
  int total;
  final TableStructure structure;
  final TableStructure? foreignPreviewStructure;
  final List<TableDataRow>? foreignPreviewRows;
  int countCalls = 0;
  bool failNextPage = false;
  final List<_PageRequest> requests = [];
  final List<_CommitRequest> commitRequests = [];
  Object? commitError;
  Object? foreignPreviewError;

  _FakeTableDataRepository({
    required this.total,
    TableStructure? structure,
    this.foreignPreviewStructure,
    this.foreignPreviewRows,
  }) : structure = structure ?? _structure;

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
  ) async {
    if (table == 'profiles' && foreignPreviewStructure != null) {
      return foreignPreviewStructure!;
    }
    return structure;
  }

  @override
  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
  ) async {
    return [const QueryResult()];
  }

  @override
  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
  }) async {
    countCalls++;
    return total;
  }

  @override
  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required int offset,
    required int limit,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
  }) async {
    if (table == 'profiles') {
      if (foreignPreviewError case final error?) throw error;
      return TableRowsPage(
        rows: foreignPreviewRows ?? const [],
        queryDuration: const Duration(milliseconds: 2),
      );
    }
    requests.add(_PageRequest(offset: offset, limit: limit));
    if (failNextPage) {
      failNextPage = false;
      throw Exception('page failure');
    }
    final count = (total - offset).clamp(0, limit);
    return TableRowsPage(
      rows: List.generate(count, (index) => _row(offset + index, structure)),
      queryDuration: const Duration(milliseconds: 4),
    );
  }

  @override
  Future<void> commitChanges(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required List<TableCellChange> cellChanges,
    required List<TableDataRow> deletedRows,
    required List<Map<String, dynamic>> insertedRows,
  }) async {
    if (commitError case final error?) throw error;
    commitRequests.add(
      _CommitRequest(cellChanges: cellChanges, deletedRows: deletedRows),
    );
    total -= deletedRows.length;
  }
}

class _ControlledPageRepository implements TableDataRepository {
  final requests = <_PageRequest, Completer<TableRowsPage>>{};

  @override
  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
  ) async {
    return [const QueryResult()];
  }

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
  ) async => _structure;

  @override
  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
  }) async => 120;

  @override
  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required int offset,
    required int limit,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
  }) {
    final request = _PageRequest(offset: offset, limit: limit);
    return (requests[request] ??= Completer<TableRowsPage>()).future;
  }

  void completeRequest(int offset, int limit) {
    requests[_PageRequest(offset: offset, limit: limit)]!.complete(
      TableRowsPage(
        rows: List.generate(limit, (index) => _row(offset + index, _structure)),
        queryDuration: const Duration(milliseconds: 3),
      ),
    );
  }

  @override
  Future<void> commitChanges(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required List<TableCellChange> cellChanges,
    required List<TableDataRow> deletedRows,
    required List<Map<String, dynamic>> insertedRows,
  }) async {}
}

final _structure = TableStructure(
  columns: [
    TableDataColumn(
      name: 'id',
      databaseType: 'int',
      length: 11,
      isPrimaryKey: true,
      isNullable: false,
    ),
  ],
  orderColumn: 'id',
);

final _multiColumn = TableStructure(
  columns: [
    TableDataColumn(
      name: 'id',
      databaseType: 'int',
      length: 11,
      isPrimaryKey: true,
      isNullable: false,
    ),
    TableDataColumn(
      name: 'name',
      databaseType: 'varchar(255)',
      length: 255,
      isPrimaryKey: false,
      isNullable: true,
    ),
  ],
  orderColumn: 'id',
);

TableDataRow _row(int index, TableStructure structure) => TableDataRow([
  TableCellValue.text(index.toString()),
  for (final column in structure.columns.skip(1))
    TableCellValue.text('${column.name} $index'),
]);

class _PageRequest {
  final int offset;
  final int limit;

  const _PageRequest({required this.offset, required this.limit});

  @override
  bool operator ==(Object other) =>
      other is _PageRequest && offset == other.offset && limit == other.limit;

  @override
  int get hashCode => Object.hash(offset, limit);
}

class _CommitRequest {
  final List<TableCellChange> cellChanges;
  final List<TableDataRow> deletedRows;

  const _CommitRequest({required this.cellChanges, required this.deletedRows});
}
