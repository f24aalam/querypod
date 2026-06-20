import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../features/connections/data/repositories/connection_repository_impl.dart';
import '../features/connections/domain/repositories/connection_repository.dart';
import '../features/connections/presentation/cubit/connection_cubit.dart';
import '../features/workspace/data/repositories/query_repository_impl.dart';
import '../features/workspace/data/repositories/workspace_metadata_repository_impl.dart';
import '../features/workspace/data/repositories/table_data_repository_impl.dart';
import '../features/workspace/domain/repositories/query_repository.dart';
import '../features/workspace/domain/repositories/table_data_repository.dart';
import '../features/workspace/domain/repositories/workspace_metadata_repository.dart';
import '../features/workspace/presentation/cubit/query_editor_cubit.dart';
import '../features/workspace/presentation/cubit/workspace_metadata_cubit.dart';
import '../features/workspace/presentation/cubit/table_data_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({
  required DatabaseFactory databaseFactory,
}) async {
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final queryRepository = await QueryRepositoryImpl.open(
    databaseFactory: databaseFactory,
  );

  getIt.registerLazySingleton<ConnectionRepository>(
    () => ConnectionRepositoryImpl(secureStorage: secureStorage, prefs: prefs),
  );
  getIt.registerLazySingleton<QueryRepository>(() => queryRepository);
  getIt.registerLazySingleton<WorkspaceMetadataRepository>(
    () => WorkspaceMetadataRepositoryImpl(),
  );
  getIt.registerLazySingleton<TableDataRepository>(
    () => TableDataRepositoryImpl(),
  );
  getIt.registerFactory(
    () => ConnectionCubit(repository: getIt(), queryRepository: getIt()),
  );
  getIt.registerFactory(() => QueryEditorCubit(repository: getIt()));
  getIt.registerFactory(() => WorkspaceMetadataCubit(repository: getIt()));
  getIt.registerFactory(() => TableDataCubit(repository: getIt()));
}
