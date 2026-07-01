import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../app/database.dart';
import '../app/launch_bootstrap.dart';
import '../features/connections/data/repositories/connection_repository_impl.dart';
import '../features/connections/domain/repositories/connection_repository.dart';
import '../features/connections/presentation/cubit/connection_cubit.dart';
import '../features/editor/data/repositories/query_history_repository_impl.dart';
import '../features/editor/data/repositories/query_repository_impl.dart';
import '../features/editor/data/repositories/connection_metadata_repository_impl.dart';
import '../features/editor/data/repositories/table_data_repository_impl.dart';
import '../features/workspaces/data/repositories/workspace_repository_impl.dart';
import '../features/editor/domain/repositories/query_history_repository.dart';
import '../features/workspaces/domain/repositories/workspace_repository.dart';
import '../features/editor/domain/repositories/query_repository.dart';
import '../features/editor/domain/repositories/table_data_repository.dart';
import '../features/editor/domain/repositories/connection_metadata_repository.dart';
import '../features/editor/presentation/cubit/query_editor_cubit.dart';
import '../features/editor/presentation/cubit/connection_metadata_cubit.dart';
import '../features/editor/presentation/cubit/table_data_cubit.dart';
import '../features/workspaces/presentation/cubit/workspaces_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({
  required DatabaseFactory databaseFactory,
  LaunchBootstrapConfig launchBootstrap = const LaunchBootstrapConfig(
    profileNamespace: '',
    preset: null,
    workspace: null,
  ),
}) async {
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final database = await openAppDatabase(databaseFactory: databaseFactory);
  final workspaceRepository = WorkspaceRepositoryImpl(
    prefs,
    keyNamespace: launchBootstrap.profileNamespace,
  );
  final connectionRepository = ConnectionRepositoryImpl(
    secureStorage: secureStorage,
    prefs: prefs,
    keyNamespace: launchBootstrap.profileNamespace,
  );

  getIt.registerLazySingleton<ConnectionRepository>(() => connectionRepository);
  getIt.registerLazySingleton<QueryRepository>(
    () => QueryRepositoryImpl(database: database),
  );
  getIt.registerLazySingleton<QueryHistoryRepository>(
    () => QueryHistoryRepositoryImpl(database: database),
  );
  getIt.registerLazySingleton<ConnectionMetadataRepository>(
    () => ConnectionMetadataRepositoryImpl(),
  );
  getIt.registerLazySingleton<WorkspaceRepository>(() => workspaceRepository);
  getIt.registerLazySingleton<TableDataRepository>(
    () => TableDataRepositoryImpl(historyRepository: getIt()),
  );
  getIt.registerFactory(
    () => ConnectionCubit(repository: getIt(), queryRepository: getIt()),
  );
  getIt.registerFactory(
    () => QueryEditorCubit(
      repository: getIt(),
      historyRepository: getIt(),
      connectionRepository: getIt(),
      tableDataRepository: getIt(),
    ),
  );
  getIt.registerFactory(() => ConnectionMetadataCubit(repository: getIt()));
  getIt.registerFactory(() => TableDataCubit(repository: getIt()));
  getIt.registerFactory(() => WorkspacesCubit(repository: getIt()));

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
