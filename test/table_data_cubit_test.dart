import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/workspace/domain/entities/table_data.dart';
import 'package:querypod/features/workspace/domain/repositories/table_data_repository.dart';
import 'package:querypod/features/workspace/presentation/cubit/editor_tabs_state.dart';
import 'package:querypod/features/workspace/presentation/cubit/table_data_cubit.dart';
import 'package:querypod/features/workspace/presentation/cubit/table_data_state.dart';

void main() {
  const connection = Connection(
    id: 'connection',
    name: 'Local',
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: '',
    database: 'app',
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

  test('cell changes remain local until commit is requested', () async {
    final repository = _FakeTableDataRepository(total: 1);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    cubit.beginCellEdit(key, 0, 0);
    cubit.updateCellDraft(key, '42');

    expect(cubit.state.session(key)!.cellEdit!.isDirty, isTrue);
    expect(repository.updates, isEmpty);

    await cubit.commitCellEdit(key);

    expect(
      repository.updates.single,
      isA<_UpdateRequest>()
          .having((request) => request.columnIndex, 'columnIndex', 0)
          .having((request) => request.value, 'value', '42'),
    );
    expect(cubit.state.session(key)!.cellEdit, isNull);
  });

  test('tables without a primary key cannot enter edit mode', () async {
    final repository = _FakeTableDataRepository(
      total: 1,
      structure: TableStructure(
        columns: const [
          TableDataColumn(
            name: 'name',
            databaseType: 'varchar(255)',
            length: 255,
            isPrimaryKey: false,
          ),
        ],
        orderColumn: 'name',
      ),
    );
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    cubit.beginCellEdit(key, 0, 0);

    expect(cubit.state.session(key)!.isEditable, isFalse);
    expect(cubit.state.session(key)!.cellEdit, isNull);
  });

  test('row deletion remains staged until commit', () async {
    final repository = _FakeTableDataRepository(total: 2);
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);

    cubit.stageRowDelete(key, 0);

    expect(cubit.state.session(key)!.rowDelete?.rowIndex, 0);
    expect(repository.deletes, isEmpty);

    await cubit.commitRowDelete(key);

    expect(repository.deletes, hasLength(1));
    expect(cubit.state.session(key)!.rowDelete, isNull);
    expect(cubit.state.session(key)!.totalCount, 1);
  });

  test('failed row deletion stays staged and exposes feedback', () async {
    final repository = _FakeTableDataRepository(total: 1)
      ..deleteError = Exception('foreign key constraint');
    final cubit = TableDataCubit(repository: repository);
    await cubit.openTable(connection, key);
    cubit.stageRowDelete(key, 0);

    await cubit.commitRowDelete(key);

    final session = cubit.state.session(key)!;
    expect(session.rowDelete?.rowIndex, 0);
    expect(session.rowDelete?.isSaving, isFalse);
    expect(session.errorMessage, contains('foreign key constraint'));
    expect(session.feedbackNonce, 1);
  });
}

class _FakeTableDataRepository implements TableDataRepository {
  int total;
  final TableStructure structure;
  int countCalls = 0;
  bool failNextPage = false;
  final List<_PageRequest> requests = [];
  final List<_UpdateRequest> updates = [];
  final List<TableDataRow> deletes = [];
  Object? deleteError;

  _FakeTableDataRepository({required this.total, TableStructure? structure})
    : structure = structure ?? _structure;

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
  ) async => structure;

  @override
  Future<int> countRows(
    Connection connection,
    String database,
    String table,
  ) async {
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
  }) async {
    requests.add(_PageRequest(offset: offset, limit: limit));
    if (failNextPage) {
      failNextPage = false;
      throw Exception('page failure');
    }
    final count = (total - offset).clamp(0, limit);
    return TableRowsPage(
      rows: List.generate(count, _row),
      queryDuration: const Duration(milliseconds: 4),
    );
  }

  @override
  Future<void> updateCell(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required TableDataRow row,
    required int columnIndex,
    required String value,
  }) async {
    updates.add(_UpdateRequest(columnIndex: columnIndex, value: value));
  }

  @override
  Future<void> deleteRow(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required TableDataRow row,
  }) async {
    if (deleteError case final error?) throw error;
    deletes.add(row);
    total--;
  }
}

class _ControlledPageRepository implements TableDataRepository {
  final requests = <_PageRequest, Completer<TableRowsPage>>{};

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
    String table,
  ) async => 120;

  @override
  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required int offset,
    required int limit,
  }) {
    final request = _PageRequest(offset: offset, limit: limit);
    return (requests[request] ??= Completer<TableRowsPage>()).future;
  }

  void completeRequest(int offset, int limit) {
    requests[_PageRequest(offset: offset, limit: limit)]!.complete(
      TableRowsPage(
        rows: List.generate(limit, _row),
        queryDuration: const Duration(milliseconds: 3),
      ),
    );
  }

  @override
  Future<void> updateCell(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required TableDataRow row,
    required int columnIndex,
    required String value,
  }) async {}

  @override
  Future<void> deleteRow(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required TableDataRow row,
  }) async {}
}

final _structure = TableStructure(
  columns: [
    TableDataColumn(
      name: 'id',
      databaseType: 'int',
      length: 11,
      isPrimaryKey: true,
    ),
  ],
  orderColumn: 'id',
);

TableDataRow _row(int index) =>
    TableDataRow([TableCellValue.text(index.toString())]);

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

class _UpdateRequest {
  final int columnIndex;
  final String value;

  const _UpdateRequest({required this.columnIndex, required this.value});
}
