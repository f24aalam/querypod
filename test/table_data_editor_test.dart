import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';
import 'package:querypod/features/editor/domain/repositories/table_data_repository.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_state.dart';
import 'package:querypod/features/editor/presentation/cubit/table_data_cubit.dart';
import 'package:querypod/features/editor/presentation/widgets/table_data_editor.dart';
import 'package:querypod/features/editor/domain/entities/query_result.dart';

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
  final tab = EditorTab(
    key: key,
    type: EditorTabType.table,
    title: 'users',
    connectionId: 'connection',
    database: 'app',
  );

  testWidgets('table editor shows and closes structure view', (tester) async {
    final cubit = TableDataCubit(repository: _EditorRepository());
    await cubit.openTable(connection, key);
    cubit.showTableStructure(key);

    await tester.pumpWidget(_TableEditorHarness(cubit: cubit, tab: tab));
    await tester.pumpAndSettle();

    expect(find.text('Table Structure'), findsOneWidget);
    expect(find.byTooltip('Close table structure'), findsOneWidget);

    await tester.tap(find.byTooltip('Close table structure'));
    await tester.pumpAndSettle();

    expect(find.text('Table Structure'), findsNothing);
    expect(cubit.state.session(key)!.isShowingStructure, isFalse);
    await cubit.close();
  });

  testWidgets('table editor shows and dismisses foreign row preview', (
    tester,
  ) async {
    final cubit = TableDataCubit(repository: _EditorRepository());
    await cubit.openTable(connection, key);
    await cubit.previewForeignRow(
      key,
      const TableForeignKey(targetTable: 'profiles', targetColumn: 'id'),
      '1',
    );

    await tester.pumpWidget(_TableEditorHarness(cubit: cubit, tab: tab));
    await tester.pumpAndSettle();

    expect(find.text('profiles'), findsOneWidget);
    expect(find.text('Builder'), findsOneWidget);

    await tester.tap(find.byTooltip('Close preview'));
    await tester.pumpAndSettle();

    expect(cubit.state.session(key)!.foreignRowPreview, isNull);
    await cubit.close();
  });
}

class _TableEditorHarness extends StatelessWidget {
  const _TableEditorHarness({required this.cubit, required this.tab});

  final TableDataCubit cubit;
  final EditorTab tab;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BlocProvider<TableDataCubit>.value(
        value: cubit,
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: Scaffold(body: TableDataEditor(tab: tab)),
        ),
      ),
    );
  }
}

class _EditorRepository implements TableDataRepository {
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

  @override
  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
  }) async => 1;

  @override
  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
  ) async => [const QueryResult()];

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
      return TableRowsPage(
        rows: [
          TableDataRow([
            TableCellValue.text('1'),
            TableCellValue.text('Builder'),
          ]),
        ],
        queryDuration: const Duration(milliseconds: 1),
      );
    }
    return TableRowsPage(
      rows: [
        TableDataRow([TableCellValue.text('1'), TableCellValue.text('1')]),
      ],
      queryDuration: const Duration(milliseconds: 1),
    );
  }

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
  ) async {
    if (table == 'profiles') {
      return TableStructure(
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
      );
    }
    return TableStructure(
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
          foreignKey: TableForeignKey(
            targetTable: 'profiles',
            targetColumn: 'id',
          ),
        ),
      ],
      indexes: const [
        TableIndex(
          name: 'PRIMARY',
          columns: ['id'],
          isUnique: true,
          isPrimaryKey: true,
        ),
      ],
      orderColumn: 'id',
    );
  }
}
