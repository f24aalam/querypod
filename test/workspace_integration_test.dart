import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/app.dart';
import 'package:querypod/app/injection.dart';
import 'package:querypod/app/launch_bootstrap.dart';
import 'package:querypod/app/theme_cubit.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';
import 'package:querypod/features/connections/presentation/cubit/connection_cubit.dart';
import 'package:querypod/features/editor/presentation/pages/connection_page.dart';
import 'package:querypod/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:querypod/features/workspaces/presentation/pages/workspaces_page.dart';

import 'support/persistence_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    await _configureTestDependencies();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('app route activation sets the active workspace id', (
    tester,
  ) async {
    await tester.pumpWidget(
      const App(initialLocation: '/workspace/router-target'),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ConnectionPage));
    expect(
      context.read<ConnectionCubit>().state.activeWorkspaceId,
      'router-target',
    );
  });

  testWidgets('theme changes keep the active workspace route', (tester) async {
    await tester.pumpWidget(
      const App(initialLocation: '/workspace/router-target'),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ConnectionPage));
    context.read<ThemeCubit>().setScheme(AppColorScheme.green);
    await tester.pumpAndSettle();

    expect(find.byType(ConnectionPage), findsOneWidget);
    expect(find.byType(WorkspacesPage), findsNothing);
    expect(
      context.read<ConnectionCubit>().state.activeWorkspaceId,
      'router-target',
    );
  });

  test(
    'bootstrap initialLocation resolves to workspace route when present',
    () {
      const config = LaunchBootstrapConfig(
        profileNamespace: '',
        preset: null,
        workspace: BootstrapWorkspacePreset(id: 'team-a', name: 'Team A'),
      );

      expect(config.initialLocation, '/workspace/team-a');
      expect(
        const LaunchBootstrapConfig(
          profileNamespace: '',
          preset: null,
          workspace: null,
        ).initialLocation,
        '/',
      );
    },
  );

  test(
    'configureDependencies does not duplicate a bootstrap workspace',
    () async {
      await getIt.reset();
      final database = createTestDatabase();
      await seedWorkspace(database, id: 'team-a');
      await configureDependencies(
        database: database,
        credentialStore: MemoryCredentialStore(),
        launchBootstrap: const LaunchBootstrapConfig(
          profileNamespace: 'bootstrap-once',
          preset: null,
          workspace: BootstrapWorkspacePreset(id: 'team-a', name: 'Team A'),
        ),
      );

      final workspaces = await getIt<WorkspaceRepository>().getWorkspaces();
      expect(workspaces.map((item) => item.id).toList(), ['team-a']);
    },
  );

  test('bootstrap connection is assigned to the bootstrap workspace', () async {
    await getIt.reset();
    await configureDependencies(
      database: createTestDatabase(),
      credentialStore: MemoryCredentialStore(),
      launchBootstrap: const LaunchBootstrapConfig(
        profileNamespace: 'bootstrap-connection',
        workspace: BootstrapWorkspacePreset(id: 'team-a', name: 'Team A'),
        preset: BootstrapConnectionPreset(
          id: 'connection-1',
          name: 'Local DB',
          host: 'localhost',
          port: 5432,
          user: 'postgres',
          password: '',
          database: 'app',
          type: ConnectionType.postgresql,
          useTls: false,
          selectAfterSave: false,
        ),
      ),
    );

    final connections = await getIt<ConnectionRepository>().getAll();
    expect(connections.single.workspaceId, 'team-a');
  });

  test(
    'setWorkspace reloads connections filtered to the active workspace',
    () async {
      final repository = _WorkspaceAwareConnectionRepository();
      final cubit = ConnectionCubit(repository: repository);

      try {
        await repository.save(
          _connection(id: 'a-1', workspaceId: 'workspace-a'),
        );
        await repository.save(
          _connection(id: 'b-1', workspaceId: 'workspace-b'),
        );
        await repository.save(
          _connection(id: 'b-2', workspaceId: 'workspace-b'),
        );
        await repository.setSelectedId('a-1');

        await cubit.setWorkspace('workspace-b');

        expect(cubit.state.activeWorkspaceId, 'workspace-b');
        expect(cubit.state.connections.map((item) => item.id).toList(), [
          'b-1',
          'b-2',
        ]);
        expect(cubit.state.selectedId, isNull);
        expect(repository.selectedId, isNull);
      } finally {
        await cubit.close();
      }
    },
  );
}

Future<void> _configureTestDependencies({
  LaunchBootstrapConfig launchBootstrap = const LaunchBootstrapConfig(
    profileNamespace: '',
    preset: null,
    workspace: null,
  ),
}) {
  return configureDependencies(
    database: createTestDatabase(),
    credentialStore: MemoryCredentialStore(),
    launchBootstrap: launchBootstrap,
  );
}

Connection _connection({required String id, required String workspaceId}) {
  return Connection(
    id: id,
    name: id,
    host: 'localhost',
    port: 5432,
    user: 'postgres',
    password: '',
    database: 'app',
    workspaceId: workspaceId,
  );
}

class _WorkspaceAwareConnectionRepository implements ConnectionRepository {
  final List<Connection> _connections = [];
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
