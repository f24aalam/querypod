import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../app/database.dart';
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
}) async {
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final database = await openAppDatabase(databaseFactory: databaseFactory);

  getIt.registerLazySingleton<ConnectionRepository>(
    () => ConnectionRepositoryImpl(secureStorage: secureStorage, prefs: prefs),
  );
  getIt.registerLazySingleton<QueryRepository>(
    () => QueryRepositoryImpl(database: database),
  );
  getIt.registerLazySingleton<QueryHistoryRepository>(
    () => QueryHistoryRepositoryImpl(database: database),
  );
  getIt.registerLazySingleton<ConnectionMetadataRepository>(
    () => ConnectionMetadataRepositoryImpl(),
  );
  getIt.registerLazySingleton<WorkspaceRepository>(
    () => WorkspaceRepositoryImpl(prefs),
  );
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
}
