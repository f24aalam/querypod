import 'package:get_it/get_it.dart';

import '../app/database.dart';
import '../app/launch_bootstrap.dart';
import '../features/connections/data/repositories/connection_repository_impl.dart';
import '../features/connections/data/services/connection_credential_store.dart';
import '../features/connections/domain/repositories/connection_repository.dart';
import '../features/connections/presentation/cubit/connection_cubit.dart';
import '../features/database_transfer/data/database_tool_repository_impl.dart';
import '../features/database_transfer/data/database_transfer_repository_impl.dart';
import '../features/database_transfer/domain/database_tool_repository.dart';
import '../features/database_transfer/domain/database_transfer_repository.dart';
import '../features/database_transfer/presentation/cubit/database_transfer_cubit.dart';
import '../features/editor/data/repositories/query_history_repository_impl.dart';
import '../features/editor/data/repositories/query_repository_impl.dart';
import '../features/editor/data/repositories/connection_metadata_repository_impl.dart';
import '../features/editor/data/repositories/pinned_tables_repository_impl.dart';
import '../features/editor/data/repositories/table_data_repository_impl.dart';
import '../features/workspaces/data/repositories/workspace_repository_impl.dart';
import '../features/editor/domain/repositories/query_history_repository.dart';
import '../features/workspaces/domain/repositories/workspace_repository.dart';
import '../features/editor/domain/repositories/query_repository.dart';
import '../features/editor/domain/repositories/table_data_repository.dart';
import '../features/editor/domain/repositories/connection_metadata_repository.dart';
import '../features/editor/domain/repositories/pinned_tables_repository.dart';
import '../features/editor/presentation/cubit/query_editor_cubit.dart';
import '../features/editor/presentation/cubit/connection_metadata_cubit.dart';
import '../features/editor/presentation/cubit/table_data_cubit.dart';
import '../features/workspaces/presentation/cubit/workspaces_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({
  QueryPodDatabase? database,
  ConnectionCredentialStore? credentialStore,
  LaunchBootstrapConfig launchBootstrap = const LaunchBootstrapConfig(
    profileNamespace: '',
    preset: null,
    workspace: null,
  ),
}) async {
  final appDatabase =
      database ??
      QueryPodDatabase(profileNamespace: launchBootstrap.profileNamespace);
  final credentials =
      credentialStore ??
      SecureConnectionCredentialStore(
        keyNamespace: launchBootstrap.profileNamespace,
      );
  final workspaceRepository = WorkspaceRepositoryImpl(
    database: appDatabase,
    credentialStore: credentials,
  );
  final connectionRepository = ConnectionRepositoryImpl(
    database: appDatabase,
    credentialStore: credentials,
  );
  final pinnedTablesRepository = PinnedTablesRepositoryImpl(
    database: appDatabase,
  );
  final databaseToolRepository = DatabaseToolRepositoryImpl(
    database: appDatabase,
  );

  getIt.registerSingleton<QueryPodDatabase>(
    appDatabase,
    dispose: (database) => database.close(),
  );
  getIt.registerSingleton<ConnectionCredentialStore>(credentials);
  getIt.registerLazySingleton<ConnectionRepository>(() => connectionRepository);
  getIt.registerLazySingleton<DatabaseToolRepository>(
    () => databaseToolRepository,
  );
  getIt.registerLazySingleton<DatabaseTransferRepository>(
    () => DatabaseTransferRepositoryImpl(tools: databaseToolRepository),
  );
  getIt.registerLazySingleton<QueryRepository>(
    () => QueryRepositoryImpl(database: appDatabase),
  );
  getIt.registerLazySingleton<QueryHistoryRepository>(
    () => QueryHistoryRepositoryImpl(database: appDatabase),
  );
  getIt.registerLazySingleton<ConnectionMetadataRepository>(
    () => ConnectionMetadataRepositoryImpl(),
  );
  getIt.registerLazySingleton<PinnedTablesRepository>(
    () => pinnedTablesRepository,
  );
  getIt.registerLazySingleton<WorkspaceRepository>(() => workspaceRepository);
  getIt.registerLazySingleton<TableDataRepository>(
    () => TableDataRepositoryImpl(historyRepository: getIt()),
  );
  getIt.registerFactory(() => ConnectionCubit(repository: getIt()));
  getIt.registerFactory(
    () => QueryEditorCubit(
      repository: getIt(),
      historyRepository: getIt(),
      connectionRepository: getIt(),
      tableDataRepository: getIt(),
    ),
  );
  getIt.registerFactory(
    () => ConnectionMetadataCubit(
      repository: getIt(),
      pinnedTablesRepository: getIt(),
    ),
  );
  getIt.registerFactory(() => TableDataCubit(repository: getIt()));
  getIt.registerFactory(() => WorkspacesCubit(repository: getIt()));
  getIt.registerFactory(() => DatabaseTransferCubit(repository: getIt()));

  final workspacePreset = launchBootstrap.workspace;
  if (workspacePreset != null) {
    final workspaces = await workspaceRepository.getWorkspaces();
    final existing = workspaces
        .where((workspace) => workspace.id == workspacePreset.id)
        .firstOrNull;
    if (existing == null) {
      await workspaceRepository.createWorkspace(workspacePreset.toWorkspace());
    }
  }

  final preset = launchBootstrap.preset;
  if (preset != null) {
    final connection = preset.toConnection(
      workspaceId: workspacePreset?.id ?? 'default',
    );
    await connectionRepository.save(connection);
    if (preset.selectAfterSave) {
      await connectionRepository.setSelectedId(connection.id);
    }
  }
}
