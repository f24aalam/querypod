import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:querypod/app/app.dart';
import 'package:querypod/app/injection.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_editor_cubit.dart';
import 'package:querypod/features/connections/presentation/widgets/connection_form.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/workspace/domain/entities/table_data.dart';
import 'package:querypod/features/workspace/domain/entities/workspace_table.dart';
import 'package:querypod/features/workspace/domain/repositories/table_data_repository.dart';
import 'package:querypod/features/workspace/presentation/cubit/editor_tabs_cubit.dart';
import 'package:querypod/features/workspace/presentation/cubit/editor_tabs_state.dart';
import 'package:querypod/features/workspace/presentation/cubit/table_data_cubit.dart';
import 'package:querypod/features/workspace/presentation/pages/workspace_page.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(App), findsOneWidget);
  });

  testWidgets('only the active editor is mounted', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(WorkspacePage));
    final tabs = context.read<EditorTabsCubit>();

    tabs.openConnectionEditor();
    expect(tabs.state.activeTab, isNotNull);
    await tester.pumpAndSettle();
    expect(find.byType(ConnectionForm), findsOneWidget);

    tabs.pinTable(
      connectionId: 'connection',
      database: 'app',
      table: const WorkspaceTable(
        name: 'users',
        type: WorkspaceTableType.table,
      ),
    );
    expect(tabs.state.activeTab?.title, 'users');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byType(ConnectionForm), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('opening an overflowed tab scrolls it into view', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(WorkspacePage));
    final tabs = context.read<EditorTabsCubit>();

    for (var i = 0; i < 8; i++) {
      tabs.pinTable(
        connectionId: 'connection',
        database: 'app',
        table: WorkspaceTable(name: 'table_$i', type: WorkspaceTableType.table),
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

  testWidgets('connection draft survives tab switches and guards closing', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(WorkspacePage));
    final tabs = context.read<EditorTabsCubit>();

    tabs.openConnectionEditor();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(FTextField).first, 'Unsaved draft');
    await tester.pump();
    expect(context.read<ConnectionEditorCubit>().state.isDirty, isTrue);

    tabs.pinTable(
      connectionId: 'connection',
      database: 'app',
      table: const WorkspaceTable(
        name: 'users',
        type: WorkspaceTableType.table,
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
    getIt.registerLazySingleton<TableDataRepository>(
      () => _WidgetTableRepository(),
    );
    getIt.registerFactory(
      () => TableDataCubit(repository: getIt<TableDataRepository>()),
    );

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(WorkspacePage));
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
    );

    tabs.pinTable(
      connectionId: key.connectionId,
      database: key.database,
      table: const WorkspaceTable(
        name: 'users',
        type: WorkspaceTableType.table,
      ),
    );
    await tableData.openTable(connection, key);
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('1–2 of 2 records'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Rows per page'), findsOneWidget);

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

class _WidgetTableRepository implements TableDataRepository {
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
      ),
      TableDataColumn(
        name: 'name',
        databaseType: 'varchar(255)',
        length: 255,
        isPrimaryKey: false,
      ),
    ],
    orderColumn: 'id',
  );

  @override
  Future<int> countRows(
    Connection connection,
    String database,
    String table,
  ) async => 2;

  @override
  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required int offset,
    required int limit,
  }) async => TableRowsPage(
    rows: [
      TableDataRow(const [
        TableCellValue.text('1'),
        TableCellValue.text('Alice'),
      ]),
      TableDataRow(const [
        TableCellValue.text('2'),
        TableCellValue.text('Bob'),
      ]),
    ],
    queryDuration: const Duration(milliseconds: 5),
  );
}
