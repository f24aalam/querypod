import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/domain/entities/connection_database.dart';
import 'package:querypod/features/editor/domain/entities/connection_table.dart';
import 'package:querypod/features/editor/domain/entities/query_result.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';
import 'package:querypod/features/editor/domain/repositories/connection_metadata_repository.dart';
import 'package:querypod/features/editor/domain/repositories/pinned_tables_repository.dart';
import 'package:querypod/features/editor/presentation/cubit/connection_metadata_cubit.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_cubit.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_state.dart';
import 'package:querypod/features/editor/presentation/cubit/table_data_cubit.dart';
import 'package:querypod/features/editor/presentation/widgets/table_destructive_action_dialog.dart';
import 'package:querypod/features/editor/domain/repositories/table_data_repository.dart';

const _dialogConnection = Connection(
  id: 'connection',
  name: 'Local',
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: '',
  database: 'app',
  workspaceId: 'default',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'drop dialog requires typed confirmation in force mode and closes tab',
    (tester) async {
      final metadataCubit = _SpyMetadataCubit();
      final tableCubit = TableDataCubit(repository: _NoopTableDataRepository());
      final tabsCubit = EditorTabsCubit()
        ..pinTable(
          connectionId: 'connection',
          database: 'app',
          table: const ConnectionTable(
            name: 'users',
            type: ConnectionTableType.table,
          ),
        );

      await tester.pumpWidget(
        _DialogHarness(
          metadataCubit: metadataCubit,
          tableCubit: tableCubit,
          tabsCubit: tabsCubit,
          child: const _OpenTableDialog(actionType: DestructiveActionType.drop),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Drop Table'), findsOneWidget);
      await tester.tap(find.text('Force (cascade/ignore foreign keys)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Drop'));
      await tester.pumpAndSettle();
      expect(metadataCubit.dropCalls, isEmpty);

      await tester.enterText(find.byType(EditableText), 'users');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Drop'));
      await tester.pumpAndSettle();

      expect(metadataCubit.dropCalls.single, ('users', true));
      expect(tabsCubit.state.tabs, isEmpty);
      await tableCubit.close();
    },
  );

  testWidgets('truncate dialog refreshes the open table', (tester) async {
    final metadataCubit = _SpyMetadataCubit();
    final tableCubit = _SpyTableDataCubit();
    final tabsCubit = EditorTabsCubit();

    await tester.pumpWidget(
      _DialogHarness(
        metadataCubit: metadataCubit,
        tableCubit: tableCubit,
        tabsCubit: tabsCubit,
        child: const _OpenTableDialog(
          actionType: DestructiveActionType.truncate,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Truncate'));
    await tester.pumpAndSettle();

    expect(metadataCubit.truncateCalls.single, ('users', false));
    expect(tableCubit.refreshedKeys.single.tableName, 'users');
  });

  testWidgets('repository failure keeps dialog open and shows the error', (
    tester,
  ) async {
    final metadataCubit = _SpyMetadataCubit(
      dropError: Exception('constraint failed'),
    );

    await tester.pumpWidget(
      _DialogHarness(
        metadataCubit: metadataCubit,
        tableCubit: _SpyTableDataCubit(),
        tabsCubit: EditorTabsCubit(),
        child: const _OpenTableDialog(actionType: DestructiveActionType.drop),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Drop'));
    await tester.pumpAndSettle();

    expect(find.textContaining('constraint failed'), findsOneWidget);
    expect(find.text('Drop Table'), findsOneWidget);
  });
}

class _DialogHarness extends StatelessWidget {
  const _DialogHarness({
    required this.metadataCubit,
    required this.tableCubit,
    required this.tabsCubit,
    required this.child,
  });

  final ConnectionMetadataCubit metadataCubit;
  final TableDataCubit tableCubit;
  final EditorTabsCubit tabsCubit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectionMetadataCubit>.value(value: metadataCubit),
          BlocProvider<TableDataCubit>.value(value: tableCubit),
          BlocProvider<EditorTabsCubit>.value(value: tabsCubit),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: Scaffold(body: child),
        ),
      ),
    );
  }
}

class _OpenTableDialog extends StatefulWidget {
  const _OpenTableDialog({required this.actionType});

  final DestructiveActionType actionType;

  @override
  State<_OpenTableDialog> createState() => _OpenTableDialogState();
}

class _OpenTableDialogState extends State<_OpenTableDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TableDestructiveActionDialog.show(
        context,
        connection: _dialogConnection,
        database: 'app',
        tableName: 'users',
        actionType: widget.actionType,
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

class _SpyMetadataCubit extends ConnectionMetadataCubit {
  _SpyMetadataCubit({this.dropError})
    : super(
        repository: _NoopConnectionMetadataRepository(),
        pinnedTablesRepository: _NoopPinnedTablesRepository(),
      );

  final Object? dropError;
  final List<(String, bool)> dropCalls = [];
  final List<(String, bool)> truncateCalls = [];

  @override
  Future<void> dropTable(
    Connection connection,
    String database,
    String table, {
    bool cascade = false,
  }) async {
    if (dropError != null) throw dropError!;
    dropCalls.add((table, cascade));
  }

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String table, {
    bool cascade = false,
  }) async {
    truncateCalls.add((table, cascade));
  }
}

class _SpyTableDataCubit extends TableDataCubit {
  _SpyTableDataCubit() : super(repository: _NoopTableDataRepository());

  final List<TableTabKey> refreshedKeys = [];

  @override
  Future<void> refresh(TableTabKey key) async {
    refreshedKeys.add(key);
  }
}

class _NoopConnectionMetadataRepository
    implements ConnectionMetadataRepository {
  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {}

  @override
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {}

  @override
  Future<void> createTable(
    Connection connection,
    String database,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}

  @override
  Future<void> dropTable(
    Connection connection,
    String database,
    String table, {
    bool cascade = false,
  }) async {}

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String table,
  ) async => [];

  @override
  Future<List<ConnectionDatabase>> listDatabases(Connection connection) async =>
      [];

  @override
  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
  ) async => [];

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String table, {
    bool cascade = false,
  }) async {}
}

class _NoopPinnedTablesRepository implements PinnedTablesRepository {
  @override
  Future<List<String>> getPinnedTables({
    required String connectionId,
    required String database,
  }) async => [];

  @override
  Future<void> setPinnedTables({
    required String connectionId,
    required String database,
    required List<String> tableNames,
  }) async {}
}

class _NoopTableDataRepository implements TableDataRepository {
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
  }) async => 0;

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
  }) async => TableRowsPage(rows: const [], queryDuration: Duration.zero);

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
  ) async => TableStructure(columns: const [], orderColumn: 'id');
}
