import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/injection.dart';
import 'package:querypod/app/launch_bootstrap.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/connections/domain/repositories/connection_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async {
            return switch (call.method) {
              'read' => null,
              'write' => null,
              'delete' => null,
              'containsKey' => false,
              'readAll' => <String, String>{},
              _ => null,
            };
          },
        );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  test('bootstrap connection is selected when selectAfterSave is true', () async {
    await configureDependencies(
      databaseFactory: databaseFactoryFfi,
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

    expect(await getIt<ConnectionRepository>().getSelectedId(), 'connection-1');
  });

  test('bootstrap connection is not selected when selectAfterSave is false', () async {
    await configureDependencies(
      databaseFactory: databaseFactoryFfi,
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
  });
}
