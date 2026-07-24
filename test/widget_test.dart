import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
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
import 'package:querypod/features/editor/presentation/cubit/table_data_state.dart';
import 'package:querypod/features/editor/presentation/pages/connection_page.dart';
import 'package:querypod/features/editor/presentation/widgets/table_data_editor.dart';

import 'support/persistence_test_support.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  setUp(() async {
    await getIt.reset();
    await configureDependencies(
      database: createTestDatabase(),
      credentialStore: MemoryCredentialStore(),
    );
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

  testWidgets('table search shows a loading line below the tab strip', (
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

    repository.searchDelay = const Duration(milliseconds: 100);
    unawaited(tableData.setSearch(key, query: 'needle'));
    await tester.pump();

    expect(
      tableData.state.session(key)!.status,
      TableDataStatus.initialLoading,
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      find.byKey(const ValueKey('active-table-loading-line')),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('active-table-loading-line')),
      findsNothing,
    );
  });

  testWidgets('table row context menu copies one row', (tester) async {
    final context = await _openWidgetTable(tester);

    await tester.longPress(find.text('Alice'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Copy as'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pump(const Duration(milliseconds: 100));

    final data = await Clipboard.getData('text/plain');
    expect(
      data?.text,
      'id name settings\n'
      r'1 Alice "{\"theme\":\"dark\",\"notifications\":true}"',
    );
    expect(find.text('Copied to clipboard'), findsOneWidget);
    expect(context.read<TableDataCubit>().state.sessions, isNotEmpty);
  });

  testWidgets('table header context menu pins and unpins a column', (
    tester,
  ) async {
    final context = await _openWidgetTable(tester);
    const key = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'users',
    );

    await tester.longPress(find.text('name'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Pin column'), findsOneWidget);

    await tester.tap(find.text('Pin column'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      context.read<TableDataCubit>().state.session(key)!.pinnedColumnIndexes,
      [1],
    );

    await tester.longPress(find.text('id').last);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Pin column'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      context.read<TableDataCubit>().state.session(key)!.pinnedColumnIndexes,
      [1, 0],
    );

    await tester.longPress(find.text('id').last);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Move to'), findsOneWidget);

    await tester.tap(find.text('Move to'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Left'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      context.read<TableDataCubit>().state.session(key)!.pinnedColumnIndexes,
      [0, 1],
    );

    await tester.longPress(find.text('name'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Unpin column'), findsOneWidget);

    await tester.tap(find.text('Unpin column'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      context.read<TableDataCubit>().state.session(key)!.pinnedColumnIndexes,
      [0],
    );
  });

  testWidgets('table header drag resizes a column', (tester) async {
    final context = await _openWidgetTable(tester);
    const key = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'users',
    );

    final nameHeader = find.text('name');
    final nameRect = tester.getRect(nameHeader);
    final handleStart = Offset(
      nameRect.left - 10 + 220 - 2,
      nameRect.center.dy,
    );

    await tester.dragFrom(handleStart, const Offset(50, 0));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      context
          .read<TableDataCubit>()
          .state
          .session(key)!
          .columnWidthOverrides[1],
      greaterThan(220),
    );
  });

  testWidgets('table row keyboard copy copies selected rows', (tester) async {
    final context = await _openWidgetTable(tester);
    final tableData = context.read<TableDataCubit>();
    const key = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'users',
    );
    await tester.tap(find.text('Alice'));
    await tester.pump();
    tableData.selectSingleRow(key, 0);
    tableData.toggleRowSelection(key, 1);
    await tester.pump();

    await _pressCopyShortcut(tester);

    final data = await Clipboard.getData('text/plain');
    expect(
      data?.text,
      'id name settings\n'
      r'1 Alice "{\"theme\":\"dark\",\"notifications\":true}"'
      '\n'
      r'2 "Bob Smith" "{\"theme\":\"light\"}"',
    );
    expect(find.text('Copied to clipboard'), findsOneWidget);
  });

  testWidgets('table row keyboard copy keeps clipboard without selection', (
    tester,
  ) async {
    final context = await _openWidgetTable(tester);
    const key = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'users',
    );
    await tester.tap(find.text('Alice'));
    await tester.pump();
    context.read<TableDataCubit>().clearSelection(key);
    await tester.pump();
    await Clipboard.setData(const ClipboardData(text: 'unchanged'));

    await _pressCopyShortcut(tester);

    final data = await Clipboard.getData('text/plain');
    expect(data?.text, 'unchanged');
    expect(find.text('Copied to clipboard'), findsNothing);
  });

  testWidgets('table row context menu copy as CSV copies one row', (
    tester,
  ) async {
    await _openWidgetTable(tester);

    await _copyRowAs(tester, rowText: 'Alice', format: 'CSV');

    final data = await Clipboard.getData('text/plain');
    expect(
      data?.text,
      'id,name,settings\n'
      '1,Alice,"{""theme"":""dark"",""notifications"":true}"',
    );
  });

  testWidgets('table row context menu copy as SQL copies one row', (
    tester,
  ) async {
    await _openWidgetTable(tester);

    await _copyRowAs(tester, rowText: 'Alice', format: 'SQL');

    final data = await Clipboard.getData('text/plain');
    expect(
      data?.text,
      'INSERT INTO "users" ("id", "name", "settings") VALUES\n'
      '(\'1\', \'Alice\', \'{"theme":"dark","notifications":true}\');',
    );
  });

  testWidgets('table row context menu copy as JSON copies one row', (
    tester,
  ) async {
    await _openWidgetTable(tester);

    await _copyRowAs(tester, rowText: 'Alice', format: 'JSON');

    final data = await Clipboard.getData('text/plain');
    expect(
      data?.text,
      '[\n'
      '  {\n'
      '    "id": "1",\n'
      '    "name": "Alice",\n'
      '    "settings": {\n'
      '      "theme": "dark",\n'
      '      "notifications": true\n'
      '    }\n'
      '  }\n'
      ']',
    );
  });

  testWidgets('table row copy formatter copies selected rows', (tester) async {
    final context = await _openWidgetTable(tester);
    final tableData = context.read<TableDataCubit>();
    const key = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'users',
    );
    tableData.selectSingleRow(key, 0);
    tableData.toggleRowSelection(key, 1);

    expect(
      formatCopiedTableRows(tableData.state.session(key)!, 1),
      'id name settings\n'
      r'1 Alice "{\"theme\":\"dark\",\"notifications\":true}"'
      '\n'
      r'2 "Bob Smith" "{\"theme\":\"light\"}"',
    );
  });

  testWidgets('table row copy as formatters export selected rows', (
    tester,
  ) async {
    final context = await _openWidgetTable(tester);
    final tableData = context.read<TableDataCubit>();
    const key = TableTabKey(
      connectionId: 'connection',
      database: 'app',
      tableName: 'users',
    );
    tableData.selectSingleRow(key, 0);
    tableData.toggleRowSelection(key, 1);
    final session = tableData.state.session(key)!;

    expect(
      formatCopiedTableRowsAsCsv(session, 1),
      'id,name,settings\n'
      '1,Alice,"{""theme"":""dark"",""notifications"":true}"\n'
      '2,"Bob Smith","{""theme"":""light""}"',
    );
    expect(
      formatCopiedTableRowsAsSql(session, 1, tableName: 'users'),
      'INSERT INTO "users" ("id", "name", "settings") VALUES\n'
      '(\'1\', \'Alice\', \'{"theme":"dark","notifications":true}\'),\n'
      '(\'2\', \'Bob Smith\', \'{"theme":"light"}\');',
    );
    expect(
      formatCopiedTableRowsAsJson(session, 1),
      '[\n'
      '  {\n'
      '    "id": "1",\n'
      '    "name": "Alice",\n'
      '    "settings": {\n'
      '      "theme": "dark",\n'
      '      "notifications": true\n'
      '    }\n'
      '  },\n'
      '  {\n'
      '    "id": "2",\n'
      '    "name": "Bob Smith",\n'
      '    "settings": {\n'
      '      "theme": "light"\n'
      '    }\n'
      '  }\n'
      ']',
    );
  });

  test('table row copy as JSON structures JSON-like strings', () {
    final session = TableDataSession(
      key: const TableTabKey(
        connectionId: 'connection',
        database: 'app',
        tableName: 'places',
      ),
      structure: TableStructure(
        orderColumn: 'name',
        columns: const [
          TableDataColumn(
            name: 'name',
            databaseType: 'text',
            length: -1,
            isPrimaryKey: false,
            isNullable: false,
          ),
          TableDataColumn(
            name: 'tags',
            databaseType: 'text',
            length: -1,
            isPrimaryKey: false,
            isNullable: false,
          ),
          TableDataColumn(
            name: 'address',
            databaseType: 'jsonb',
            length: -1,
            isPrimaryKey: false,
            isNullable: false,
          ),
          TableDataColumn(
            name: 'way_nodes',
            databaseType: 'jsonb',
            length: -1,
            isPrimaryKey: false,
            isNullable: false,
          ),
          TableDataColumn(
            name: 'geom',
            databaseType: 'bytea',
            length: -1,
            isPrimaryKey: false,
            isNullable: true,
          ),
        ],
      ),
      rows: [
        TableDataRow([
          const TableCellValue.text('Juma Masjid'),
          const TableCellValue.text(
            '{amenity: place_of_worship, religion: muslim}',
          ),
          const TableCellValue.text('{}'),
          const TableCellValue.text('[]'),
          const TableCellValue.text("Instance of 'UndecodedBytes'"),
        ]),
      ],
      status: TableDataStatus.ready,
    );

    expect(
      formatCopiedTableRowsAsJson(session, 0),
      '[\n'
      '  {\n'
      '    "name": "Juma Masjid",\n'
      '    "tags": {\n'
      '      "amenity": "place_of_worship",\n'
      '      "religion": "muslim"\n'
      '    },\n'
      '    "address": {},\n'
      '    "way_nodes": [],\n'
      '    "geom": "Instance of \'UndecodedBytes\'"\n'
      '  }\n'
      ']',
    );
  });
}

Future<void> _pressCopyShortcut(WidgetTester tester) async {
  final modifier = Platform.isMacOS
      ? LogicalKeyboardKey.metaLeft
      : LogicalKeyboardKey.controlLeft;
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _copyRowAs(
  WidgetTester tester, {
  required String rowText,
  required String format,
}) async {
  await tester.longPress(find.text(rowText));
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(find.text('Copy as'));
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(find.text(format));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<BuildContext> _openWidgetTable(WidgetTester tester) async {
  var clipboardText = '';
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          final data = call.arguments as Map<Object?, Object?>;
          clipboardText = data['text'] as String? ?? '';
          return null;
        case 'Clipboard.getData':
          return <String, dynamic>{'text': clipboardText};
      }
      return null;
    },
  );

  await getIt.unregister<TableDataCubit>();
  await getIt.unregister<TableDataRepository>();
  final repository = _WidgetTableRepository();
  getIt.registerLazySingleton<TableDataRepository>(() => repository);
  getIt.registerFactory(
    () => TableDataCubit(repository: getIt<TableDataRepository>()),
  );

  await Clipboard.setData(const ClipboardData(text: ''));
  await tester.pumpWidget(const App(initialLocation: '/workspace/default'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return context;
}

class _WidgetTableRepository implements TableDataRepository {
  String? updatedValue;
  bool deleted = false;
  Duration searchDelay = Duration.zero;

  @override
  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
    String? schema,
  ) async {
    return [const QueryResult()];
  }

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
    String? schema,
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
    String? schema,
    required TableStructure structure,
    String? searchQuery,
    String? searchColumn,
    List<TableFilter>? filters,
  }) async {
    if (searchQuery != null &&
        searchQuery.isNotEmpty &&
        searchDelay > Duration.zero) {
      await Future<void>.delayed(searchDelay);
    }
    return 2;
  }

  @override
  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    String? schema,
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
        TableCellValue.text('Bob Smith'),
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
    String? schema,
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
