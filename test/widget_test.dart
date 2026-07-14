import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:querypod/app/app.dart';
import 'package:querypod/app/injection.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_editor_cubit.dart';
import 'package:querypod/features/connections/presentation/widgets/connection_form.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/domain/entities/query_result.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';
import 'package:querypod/features/editor/domain/entities/connection_table.dart';
import 'package:querypod/features/editor/domain/repositories/table_data_repository.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_cubit.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_state.dart';
import 'package:querypod/features/editor/presentation/cubit/table_data_cubit.dart';
import 'package:querypod/features/editor/presentation/pages/connection_page.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await _deleteQueryDatabase();
    await configureDependencies(databaseFactory: databaseFactoryFfi);
  });

  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(App), findsOneWidget);
  });

  testWidgets('only the active editor is mounted', (tester) async {
    await tester.pumpWidget(const App(initialLocation: '/workspace/default'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ConnectionPage));
    final tabs = context.read<EditorTabsCubit>();

    tabs.openConnectionEditor();
    expect(tabs.state.activeTab, isNotNull);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionForm), findsOneWidget);

    tabs.pinTable(
      connectionId: 'connection',
      database: 'app',
      table: const ConnectionTable(
        name: 'users',
        type: ConnectionTableType.table,
      ),
    );
    expect(tabs.state.activeTab?.title, 'users');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(ConnectionForm), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('opening an overflowed tab scrolls it into view', (tester) async {
    await tester.pumpWidget(const App(initialLocation: '/workspace/default'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ConnectionPage));
    final tabs = context.read<EditorTabsCubit>();

    for (var i = 0; i < 8; i++) {
      tabs.pinTable(
        connectionId: 'connection',
        database: 'app',
        table: ConnectionTable(
          name: 'table_$i',
          type: ConnectionTableType.table,
        ),
      );
    }
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    const activeKey = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'table_7',
    );
    final tabRect = tester.getRect(
      find.byKey(
        const ValueKey<(String, EditorTabKey)>(('tab-strip', activeKey)),
      ),
    );
    final logicalWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;

    expect(tabRect.left, greaterThanOrEqualTo(0));
    expect(tabRect.right, lessThanOrEqualTo(logicalWidth));
  });

  testWidgets('tab body activates from blank area tap', (tester) async {
    await tester.pumpWidget(const App(initialLocation: '/workspace/default'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ConnectionPage));
    final tabs = context.read<EditorTabsCubit>();

    tabs.openConnectionEditor();
    await tester.pump();
    tabs.pinTable(
      connectionId: 'connection',
      database: 'app',
      table: const ConnectionTable(
        name: 'users',
        type: ConnectionTableType.table,
      ),
    );
    await tester.pump();

    const tableKey = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'users',
    );
    final tableTab = find.byKey(
      const ValueKey<(String, EditorTabKey)>(('tab-strip', tableKey)),
    );
    expect(tableTab, findsOneWidget);
    final rect = tester.getRect(tableTab);

    await tester.tapAt(Offset(rect.left + 8, rect.center.dy));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tabs.state.activeTabKey, tableKey);
  });

  testWidgets('connection draft survives tab switches and guards closing', (
    tester,
  ) async {
    await tester.pumpWidget(const App(initialLocation: '/workspace/default'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ConnectionPage));
    final tabs = context.read<EditorTabsCubit>();

    tabs.openConnectionEditor();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(FTextField).first, 'Unsaved draft');
    await tester.pump();
    expect(context.read<ConnectionEditorCubit>().state.isDirty, isTrue);

    tabs.pinTable(
      connectionId: 'connection',
      database: 'app',
      table: const ConnectionTable(
        name: 'users',
        type: ConnectionTableType.table,
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    tabs.activate(EditorTabsCubit.connectionEditorKey);
    await tester.pumpAndSettle();

    expect(find.text('Unsaved draft'), findsOneWidget);
    expect(context.read<ConnectionEditorCubit>().state.isDirty, isTrue);

    final connectionTab = find.byKey(
      const ValueKey<(String, EditorTabKey)>((
        'tab-strip',
        EditorTabsCubit.connectionEditorKey,
      )),
    );
    final connectionClose = find.descendant(
      of: connectionTab,
      matching: find.byType(IconButton),
    );

    await tester.tap(connectionClose);
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      tabs.state.tabs.any(
        (tab) => tab.key == EditorTabsCubit.connectionEditorKey,
      ),
      isTrue,
    );

    await tester.tap(connectionClose);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      tabs.state.tabs.any(
        (tab) => tab.key == EditorTabsCubit.connectionEditorKey,
      ),
      isFalse,
    );
  });

  testWidgets('table editor renders rows and pagination controls', (
    tester,
  ) async {
    await getIt.unregister<TableDataCubit>();
    await getIt.unregister<TableDataRepository>();
    final repository = _WidgetTableRepository();
    getIt.registerLazySingleton<TableDataRepository>(() => repository);
    getIt.registerFactory(
      () => TableDataCubit(repository: getIt<TableDataRepository>()),
    );

    await tester.pumpWidget(const App(initialLocation: '/workspace/default'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ConnectionPage));
    final tabs = context.read<EditorTabsCubit>();
    final tableData = context.read<TableDataCubit>();
    const key = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'users',
    );
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

    tabs.pinTable(
      connectionId: key.connectionId,
      database: key.database,
      table: const ConnectionTable(
        name: 'users',
        type: ConnectionTableType.table,
      ),
    );
    await tableData.openTable(connection, key);
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('1–2 of 2 records'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Rows per page'), findsOneWidget);

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();
    expect(find.text('Row 1'), findsOneWidget);
    expect(find.byTooltip('Close row details'), findsOneWidget);
    expect(find.text('varchar(255)'), findsOneWidget);
    expect(find.text('{"theme":"dark","notifications":true}'), findsWidgets);

    await tester.tap(find.byTooltip('Close row details'));
    await tester.pumpAndSettle();
    expect(find.text('Row 1'), findsNothing);

    final aliceCell = find.text('Alice');
    final alicePosition = tester.getCenter(aliceCell);
    await tester.tapAt(alicePosition);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(alicePosition);
    await tester.pumpAndSettle();
    expect(find.text('Commit'), findsNothing);
    expect(find.text('Cancel'), findsNothing);

    await tester.enterText(
      find.byKey(
        const ValueKey<(String, int, int)>(('table-cell-editor', 0, 1)),
      ),
      'Alicia',
    );
    await tester.pump();
    expect(find.text('Commit'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(repository.updatedValue, isNull);

    await context.read<TableDataCubit>().commitPendingChanges(key);
    await tester.pumpAndSettle();
    expect(repository.updatedValue, 'Alicia');
    expect(find.text('Commit'), findsNothing);

    final tableTab = find.byKey(
      const ValueKey<(String, EditorTabKey)>(('tab-strip', key)),
    );
    await tester.tap(
      find.descendant(of: tableTab, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();
    expect(tableData.state.session(key), isNull);
  });
}

Future<void> _deleteQueryDatabase() async {
  final databasesPath = await databaseFactoryFfi.getDatabasesPath();
  await databaseFactoryFfi.deleteDatabase(p.join(databasesPath, 'querypod.db'));
}

class _WidgetTableRepository implements TableDataRepository {
  String? updatedValue;
  bool deleted = false;

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
  ) async => TableStructure(
    columns: const [
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
      TableDataColumn(
        name: 'settings',
        databaseType: 'json',
        length: 1024,
        isPrimaryKey: false,
        isNullable: true,
      ),
    ],
    orderColumn: 'id',
  );

  @override
  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
  }) async => 2;

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
  }) async => TableRowsPage(
    rows: [
      TableDataRow(const [
        TableCellValue.text('1'),
        TableCellValue.text('Alice'),
        TableCellValue.text('{"theme":"dark","notifications":true}'),
      ]),
      TableDataRow(const [
        TableCellValue.text('2'),
        TableCellValue.text('Bob'),
        TableCellValue.text('{"theme":"light"}'),
      ]),
    ],
    queryDuration: const Duration(milliseconds: 5),
  );

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
    if (cellChanges.isNotEmpty) {
      updatedValue = cellChanges.first.value;
    }
    deleted = deletedRows.isNotEmpty;
  }
}
