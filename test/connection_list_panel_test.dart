import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_cubit.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_editor_cubit.dart';
import 'package:querypod/features/connections/presentation/widgets/connection_list_panel.dart';
import 'package:querypod/features/editor/domain/entities/connection_query.dart';
import 'package:querypod/features/editor/domain/repositories/query_repository.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Connection connection({
    required String id,
    required String name,
    String host = 'localhost',
    String workspaceId = 'default',
  }) {
    return Connection(
      id: id,
      name: name,
      host: host,
      port: 5432,
      user: 'postgres',
      password: '',
      database: 'app',
      workspaceId: workspaceId,
      type: ConnectionType.postgresql,
      useTls: false,
    );
  }

  testWidgets('search box filters the rendered connection list', (
    tester,
  ) async {
    final repository = _MemoryConnectionRepository(
      connections: [
        connection(id: 'alpha', name: 'Alpha DB', host: 'db-alpha'),
        connection(id: 'beta', name: 'Beta DB', host: 'db-beta'),
      ],
    );
    final connectionCubit = ConnectionCubit(
      repository: repository,
      queryRepository: _FakeQueryRepository(),
    );
    await connectionCubit.load();

    await tester.pumpWidget(
      _ConnectionListHarness(
        connectionCubit: connectionCubit,
        editorCubit: ConnectionEditorCubit(),
        tabsCubit: EditorTabsCubit(),
      ),
    );

    expect(find.text('Alpha DB'), findsOneWidget);
    expect(find.text('Beta DB'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'beta');
    await tester.pumpAndSettle();

    expect(find.text('Alpha DB'), findsNothing);
    expect(find.text('Beta DB'), findsOneWidget);
    await connectionCubit.close();
  });

  testWidgets(
    'new connection action shows discard confirmation for dirty edits',
    (tester) async {
      final existing = connection(id: 'alpha', name: 'Alpha DB');
      final repository = _MemoryConnectionRepository(connections: [existing]);
      final connectionCubit = ConnectionCubit(
        repository: repository,
        queryRepository: _FakeQueryRepository(),
      );
      final editorCubit = ConnectionEditorCubit()
        ..load(existing, activeWorkspaceId: 'default')
        ..updateName('Changed');
      await connectionCubit.load();

      await tester.pumpWidget(
        _ConnectionListHarness(
          connectionCubit: connectionCubit,
          editorCubit: editorCubit,
          tabsCubit: EditorTabsCubit(),
        ),
      );

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(editorCubit.state.draft.sourceConnectionId, 'alpha');
      expect(editorCubit.state.isDirty, isTrue);

      await tester.tap(find.text('New'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(editorCubit.state.isNew, isTrue);
      expect(editorCubit.state.isDirty, isFalse);
      expect(connectionCubit.state.selectedId, isNull);
      await connectionCubit.close();
    },
  );

  testWidgets('new connection action uses the active workspace', (
    tester,
  ) async {
    final connectionCubit = ConnectionCubit(
      repository: _MemoryConnectionRepository(),
      queryRepository: _FakeQueryRepository(),
    );
    await connectionCubit.setWorkspace('workspace-a');
    final editorCubit = ConnectionEditorCubit();

    await tester.pumpWidget(
      _ConnectionListHarness(
        connectionCubit: connectionCubit,
        editorCubit: editorCubit,
        tabsCubit: EditorTabsCubit(),
      ),
    );

    await tester.tap(find.text('New'));
    await tester.pumpAndSettle();

    expect(editorCubit.state.draft.workspaceId, 'workspace-a');
    expect(editorCubit.state.isNew, isTrue);
    await connectionCubit.close();
  });
}

class _ConnectionListHarness extends StatelessWidget {
  const _ConnectionListHarness({
    required this.connectionCubit,
    required this.editorCubit,
    required this.tabsCubit,
  });

  final ConnectionCubit connectionCubit;
  final ConnectionEditorCubit editorCubit;
  final EditorTabsCubit tabsCubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectionCubit>.value(value: connectionCubit),
          BlocProvider<ConnectionEditorCubit>.value(value: editorCubit),
          BlocProvider<EditorTabsCubit>.value(value: tabsCubit),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const Scaffold(body: ConnectionListPanel()),
        ),
      ),
    );
  }
}

class _MemoryConnectionRepository implements ConnectionRepository {
  _MemoryConnectionRepository({List<Connection>? connections})
    : _connections = [...?connections];

  final List<Connection> _connections;
  String? selectedId;

  @override
  Future<void> delete(String id) async {
    _connections.removeWhere((connection) => connection.id == id);
  }

  @override
  Future<List<Connection>> getAll() async =>
      List<Connection>.from(_connections);

  @override
  Future<Connection?> getById(String id) async {
    return _connections.where((connection) => connection.id == id).firstOrNull;
  }

  @override
  Future<String?> getSelectedId() async => selectedId;

  @override
  Future<Connection> save(Connection connection) async {
    _connections.removeWhere((existing) => existing.id == connection.id);
    _connections.add(connection);
    return connection;
  }

  @override
  Future<void> setSelectedId(String? id) async {
    selectedId = id;
  }
}

class _FakeQueryRepository implements QueryRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteByConnection(String connectionId) async {}

  @override
  Future<List<ConnectionQuery>> getAllForConnection(
    String connectionId,
  ) async => [];

  @override
  Future<ConnectionQuery> save(ConnectionQuery query) async => query;
}
