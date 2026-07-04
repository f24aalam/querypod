import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_cubit.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_editor_cubit.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_state.dart';
import 'package:querypod/features/connections/presentation/widgets/connection_form.dart';
import 'package:querypod/features/editor/domain/entities/connection_query.dart';
import 'package:querypod/features/editor/domain/repositories/query_repository.dart';
import 'package:querypod/features/editor/presentation/cubit/editor_tabs_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('save marks the editor draft saved on success', (tester) async {
    final cubit = _SpyConnectionCubit(saveResult: true);
    final editorCubit = ConnectionEditorCubit()..load(null, activeWorkspaceId: 'default');
    final tabs = EditorTabsCubit();

    await tester.pumpWidget(
      _ConnectionFormHarness(
        connectionCubit: cubit,
        editorCubit: editorCubit,
        tabsCubit: tabs,
      ),
    );

    editorCubit.updateName('Primary DB');
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(cubit.savedConnections.single.name, 'Primary DB');
    expect(editorCubit.state.isDirty, isFalse);
    expect(editorCubit.state.draft.name, 'Primary DB');
  });

  testWidgets('failed save keeps the draft dirty', (tester) async {
    final cubit = _SpyConnectionCubit(saveResult: false);
    final editorCubit = ConnectionEditorCubit()..load(null, activeWorkspaceId: 'default');

    await tester.pumpWidget(
      _ConnectionFormHarness(
        connectionCubit: cubit,
        editorCubit: editorCubit,
        tabsCubit: EditorTabsCubit(),
      ),
    );

    editorCubit.updateName('Broken DB');
    await tester.pump();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(cubit.savedConnections.single.name, 'Broken DB');
    expect(editorCubit.state.isDirty, isTrue);
    expect(editorCubit.state.draft.name, 'Broken DB');
  });

  testWidgets('test button forwards the current draft to ConnectionCubit.test', (
    tester,
  ) async {
    final cubit = _SpyConnectionCubit();
    final editorCubit = ConnectionEditorCubit()..load(null, activeWorkspaceId: 'default');

    await tester.pumpWidget(
      _ConnectionFormHarness(
        connectionCubit: cubit,
        editorCubit: editorCubit,
        tabsCubit: EditorTabsCubit(),
      ),
    );

    editorCubit.updateName('Smoke Test DB');
    await tester.pump();
    await tester.ensureVisible(find.text('Test'));
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();

    expect(cubit.testedConnections.single.name, 'Smoke Test DB');
  });
}

class _ConnectionFormHarness extends StatelessWidget {
  const _ConnectionFormHarness({
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
          child: const Scaffold(body: ConnectionForm()),
        ),
      ),
    );
  }
}

class _SpyConnectionCubit extends ConnectionCubit {
  _SpyConnectionCubit({
    this.saveResult = true,
  }) : super(
         repository: _FakeConnectionRepository(),
         queryRepository: _FakeQueryRepository(),
       );

  final bool saveResult;
  final List<Connection> savedConnections = [];
  final List<Connection> testedConnections = [];

  @override
  Future<bool> save(Connection connection) async {
    savedConnections.add(connection);
    return saveResult;
  }

  @override
  Future<void> test(Connection connection) async {
    testedConnections.add(connection);
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

class _FakeQueryRepository implements QueryRepository {
  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> deleteByConnection(String connectionId) async {}

  @override
  Future<List<ConnectionQuery>> getAllForConnection(String connectionId) async =>
      [];

  @override
  Future<ConnectionQuery> save(ConnectionQuery query) async => query;
}
