import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/connections/data/repositories/connection_repository_impl.dart';
import '../features/connections/domain/repositories/connection_repository.dart';
import '../features/connections/presentation/cubit/connection_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  getIt.registerLazySingleton<ConnectionRepository>(
    () => ConnectionRepositoryImpl(secureStorage: secureStorage, prefs: prefs),
  );
  getIt.registerFactory(() => ConnectionCubit(repository: getIt()));
}
