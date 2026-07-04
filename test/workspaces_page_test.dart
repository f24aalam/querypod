import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_cubit.dart';
import 'package:querypod/features/editor/domain/entities/connection_query.dart';
import 'package:querypod/features/editor/domain/repositories/query_repository.dart';
import 'package:querypod/features/workspaces/domain/entities/app_workspace.dart';
import 'package:querypod/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:querypod/features/workspaces/presentation/cubit/workspaces_cubit.dart';
import 'package:querypod/features/workspaces/presentation/cubit/workspaces_state.dart';
import 'package:querypod/features/workspaces/presentation/pages/workspaces_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppWorkspace workspace({
    String id = 'workspace-1',
    String name = 'Workspace 1',
    DateTime? createdAt,
  }) {
    final created = createdAt ?? DateTime(2024, 1, 1);
    return AppWorkspace(
      id: id,
      name: name,
      createdAt: created,
      updatedAt: created,
    );
  }

  testWidgets('page init triggers workspace loading', (tester) async {
    final workspacesCubit = _SpyWorkspacesCubit(WorkspacesLoading());
    final connectionCubit = _TestConnectionCubit();

    await tester.pumpWidget(
      _TestHarness(
        workspacesCubit: workspacesCubit,
        connectionCubit: connectionCubit,
      ),
    );

    expect(workspacesCubit.loadCalls, 1);
  });

  testWidgets('loading state shows a progress indicator', (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        workspacesCubit: _SpyWorkspacesCubit(WorkspacesLoading()),
        connectionCubit: _TestConnectionCubit(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error state renders the error message', (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        workspacesCubit: _SpyWorkspacesCubit(const WorkspacesError('load failed')),
        connectionCubit: _TestConnectionCubit(),
      ),
    );

    expect(find.textContaining('Error: load failed'), findsOneWidget);
  });

  testWidgets('empty state renders the first workspace CTA', (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        workspacesCubit: _SpyWorkspacesCubit(const WorkspacesLoaded([])),
        connectionCubit: _TestConnectionCubit(),
      ),
    );

    expect(find.text('No workspaces yet'), findsOneWidget);
    expect(find.text('Create your first workspace'), findsOneWidget);
  });

  testWidgets('loaded state renders workspace cards', (tester) async {
    await tester.pumpWidget(
      _TestHarness(
        workspacesCubit: _SpyWorkspacesCubit(
          WorkspacesLoaded([
            workspace(name: 'Alpha', createdAt: DateTime(2024, 1, 1)),
            workspace(name: 'Beta', createdAt: DateTime(2024, 2, 1)),
          ]),
        ),
        connectionCubit: _TestConnectionCubit(),
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Created Jan 1, 2024'), findsOneWidget);
    expect(find.text('Created Feb 1, 2024'), findsOneWidget);
  });

  testWidgets('create dialog trims input and ignores blank values', (tester) async {
    final workspacesCubit = _SpyWorkspacesCubit(const WorkspacesLoaded([]));

    await tester.pumpWidget(
      _TestHarness(
        workspacesCubit: workspacesCubit,
        connectionCubit: _TestConnectionCubit(),
      ),
    );

    await tester.tap(find.text('Create Workspace'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), '   ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(workspacesCubit.createdNames, isEmpty);

    await tester.enterText(find.byType(EditableText), '  Team A  ');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(workspacesCubit.createdNames, ['Team A']);
  });

  testWidgets('tapping a workspace sets the active workspace and navigates', (
    tester,
  ) async {
    final target = workspace(id: 'workspace-42', name: 'Workspace A');
    final workspacesCubit = _SpyWorkspacesCubit(WorkspacesLoaded([target]));
    final connectionCubit = _TestConnectionCubit();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WorkspacesPage(),
        ),
        GoRoute(
          path: '/workspace/:id',
          builder: (context, state) =>
              Text('Workspace route ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WorkspacesCubit>.value(value: workspacesCubit),
          BlocProvider<ConnectionCubit>.value(value: connectionCubit),
        ],
        child: _routerApp(router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Workspace A'));
    await tester.pumpAndSettle();

    expect(connectionCubit.workspaceIds, ['workspace-42']);
    expect(find.text('Workspace route workspace-42'), findsOneWidget);
  });
}

class _TestHarness extends StatelessWidget {
  const _TestHarness({
    required this.workspacesCubit,
    required this.connectionCubit,
  });

  final WorkspacesCubit workspacesCubit;
  final ConnectionCubit connectionCubit;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const WorkspacesPage(),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<WorkspacesCubit>.value(value: workspacesCubit),
        BlocProvider<ConnectionCubit>.value(value: connectionCubit),
      ],
      child: _routerApp(router),
    );
  }
}

Widget _routerApp(GoRouter router) {
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => FTheme(
      data: FThemes.zinc.light.desktop,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
  );
}

class _SpyWorkspacesCubit extends WorkspacesCubit {
  _SpyWorkspacesCubit(WorkspacesState initialState)
    : _state = initialState,
      super(repository: _NoopWorkspaceRepository());

  WorkspacesState _state;
  int loadCalls = 0;
  final List<String> createdNames = [];

  @override
  WorkspacesState get state => _state;

  @override
  Stream<WorkspacesState> get stream => const Stream<WorkspacesState>.empty();

  @override
  Future<void> loadWorkspaces() async {
    loadCalls += 1;
  }

  @override
  Future<void> createWorkspace(String name) async {
    createdNames.add(name);
  }

  @override
  Future<void> close() async {}
}

class _TestConnectionCubit extends ConnectionCubit {
  _TestConnectionCubit()
    : super(
        repository: _FakeConnectionRepository(),
        queryRepository: _FakeQueryRepository(),
      );

  final List<String?> workspaceIds = [];

  @override
  Future<void> setWorkspace(String? workspaceId) async {
    workspaceIds.add(workspaceId);
  }
}

class _NoopWorkspaceRepository implements WorkspaceRepository {
  @override
  Future<AppWorkspace> createWorkspace(AppWorkspace workspace) async => workspace;

  @override
  Future<void> deleteWorkspace(String id) async {}

  @override
  Future<AppWorkspace> getWorkspace(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<AppWorkspace>> getWorkspaces() async => [];

  @override
  Future<AppWorkspace> updateWorkspace(AppWorkspace workspace) async => workspace;
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
