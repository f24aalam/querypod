import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/injection.dart';
import 'package:querypod/app/launch_bootstrap.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';

import 'support/persistence_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test(
    'bootstrap connection is selected when selectAfterSave is true',
    () async {
      await configureDependencies(
        database: createTestDatabase(),
        credentialStore: MemoryCredentialStore(),
        launchBootstrap: const LaunchBootstrapConfig(
          profileNamespace: 'select-true',
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
            selectAfterSave: true,
          ),
        ),
      );

      expect(
        await getIt<ConnectionRepository>().getSelectedId(),
        'connection-1',
      );
    },
  );

  test(
    'bootstrap connection is not selected when selectAfterSave is false',
    () async {
      await configureDependencies(
        database: createTestDatabase(),
        credentialStore: MemoryCredentialStore(),
        launchBootstrap: const LaunchBootstrapConfig(
          profileNamespace: 'select-false',
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

      expect(await getIt<ConnectionRepository>().getSelectedId(), isNull);
    },
  );
}
