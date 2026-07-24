import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_cubit.dart';
import 'package:querypod/features/editor/domain/entities/connection_database.dart';
import 'package:querypod/features/editor/domain/entities/connection_schema.dart';
import 'package:querypod/features/editor/domain/entities/connection_table.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';
import 'package:querypod/features/editor/domain/repositories/connection_metadata_repository.dart';
import 'package:querypod/features/editor/domain/repositories/pinned_tables_repository.dart';
import 'package:querypod/features/editor/presentation/cubit/connection_metadata_cubit.dart';
import 'package:querypod/features/editor/presentation/cubit/connection_metadata_state.dart';
import 'package:querypod/features/editor/presentation/widgets/table_list_panel.dart';

const _tableListConnection = Connection(
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

  testWidgets('table list panel forwards search input to metadata cubit', (
    tester,
  ) async {
    final metadataCubit = _SpyConnectionMetadataCubit(
      const ConnectionMetadataState(
        databases: [ConnectionDatabase(name: 'app')],
        selectedDatabase: 'app',
        tables: [
          ConnectionTable(name: 'users', type: ConnectionTableType.table),
        ],
        filteredTables: [
          ConnectionTable(name: 'users', type: ConnectionTableType.table),
        ],
      ),
    );

    await tester.pumpWidget(
      _TableListHarness(
        connectionCubit: _TestConnectionCubit(),
        metadataCubit: metadataCubit,
      ),
    );

    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Search tables...',
    );
    await tester.enterText(searchField, 'orders');
    await tester.pumpAndSettle();

    expect(metadataCubit.searchQueries, ['orders']);
  });

  testWidgets('table list panel forwards context menu pin to metadata cubit', (
    tester,
  ) async {
    final metadataCubit = _SpyConnectionMetadataCubit(
      const ConnectionMetadataState(
        connectionId: 'connection',
        databases: [ConnectionDatabase(name: 'app')],
        selectedDatabase: 'app',
        tables: [
          ConnectionTable(name: 'users', type: ConnectionTableType.table),
        ],
        filteredTables: [
          ConnectionTable(name: 'users', type: ConnectionTableType.table),
        ],
      ),
    );

    await tester.pumpWidget(
      _TableListHarness(
        connectionCubit: _TestConnectionCubit(),
        metadataCubit: metadataCubit,
      ),
    );

    await tester.longPress(find.text('users'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Pin'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(metadataCubit.toggledPins, ['users']);
  });
}

class _TableListHarness extends StatelessWidget {
  const _TableListHarness({
    required this.connectionCubit,
    required this.metadataCubit,
  });

  final ConnectionCubit connectionCubit;
  final ConnectionMetadataCubit metadataCubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectionCubit>.value(value: connectionCubit),
          BlocProvider<ConnectionMetadataCubit>.value(value: metadataCubit),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const Scaffold(body: TableListPanel()),
        ),
      ),
    );
  }
}

class _SpyConnectionMetadataCubit extends ConnectionMetadataCubit {
  _SpyConnectionMetadataCubit(ConnectionMetadataState initialState)
    : _state = initialState,
      super(
        repository: _NoopConnectionMetadataRepository(),
        pinnedTablesRepository: _NoopPinnedTablesRepository(),
      );

  final ConnectionMetadataState _state;
  final List<String> searchQueries = [];
  final List<String> toggledPins = [];

  @override
  ConnectionMetadataState get state => _state;

  @override
  Stream<ConnectionMetadataState> get stream =>
      const Stream<ConnectionMetadataState>.empty();

  @override
  void search(String query) {
    searchQueries.add(query);
  }

  @override
  Future<void> toggleTablePin(ConnectionTable table) async {
    toggledPins.add(table.name);
  }
}

class _NoopConnectionMetadataRepository
    implements ConnectionMetadataRepository {
  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String? schema,
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
    String? schema,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {}

  @override
  Future<void> dropTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    bool cascade = false,
  }) async {}

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String? schema,
    String table,
  ) async => [];

  @override
  Future<List<ConnectionSchema>> listSchemas(
    Connection connection,
    String database,
  ) async => const [ConnectionSchema(name: 'public')];

  @override
  Future<String?> getSelectedSchema({
    required String connectionId,
    required String database,
  }) async => null;

  @override
  Future<void> setSelectedSchema({
    required String connectionId,
    required String database,
    required String? schema,
  }) async {}

  @override
  Future<List<ConnectionDatabase>> listDatabases(Connection connection) async =>
      [];

  @override
  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
    String? schema,
  ) async => [];

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    bool cascade = false,
  }) async {}

  @override
  Future<void> createSchema(
    Connection connection,
    String database,
    String name,
  ) async {}
}

class _NoopPinnedTablesRepository implements PinnedTablesRepository {
  @override
  Future<List<String>> getPinnedTables({
    required String connectionId,
    required String database,
    String? schema,
  }) async => [];

  @override
  Future<void> setPinnedTables({
    required String connectionId,
    required String database,
    String? schema,
    required List<String> tableNames,
  }) async {}
}

class _TestConnectionCubit extends ConnectionCubit {
  _TestConnectionCubit() : super(repository: _FakeConnectionRepository()) {
    emit(state.copyWith(activeConnection: () => _tableListConnection));
  }
}

class _FakeConnectionRepository implements ConnectionRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Connection>> getAll() async => [];

  @override
  Future<Connection?> getById(String id) async => null;

  @override
  Future<String?> getSelectedId() async => null;

  @override
  Future<Connection> save(Connection connection) async => connection;

  @override
  Future<void> setSelectedId(String? id) async {}
}
