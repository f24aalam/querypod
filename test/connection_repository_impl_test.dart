import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/data/repositories/connection_repository_impl.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final storage = <String, String>{};

  Connection connection({
    String id = 'connection-1',
    String name = 'Local DB',
    String host = 'localhost',
    int port = 5432,
    String user = 'postgres',
    String password = 'secret',
    String database = 'app',
    String workspaceId = 'default',
    ConnectionType type = ConnectionType.postgresql,
    bool useTls = false,
  }) {
    return Connection(
      id: id,
      name: name,
      host: host,
      port: port,
      user: user,
      password: password,
      database: database,
      workspaceId: workspaceId,
      type: type,
      useTls: useTls,
    );
  }

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final key = call.arguments['key'] as String?;
          switch (call.method) {
            case 'write':
              storage[key!] = call.arguments['value'] as String;
              return null;
            case 'read':
              return storage[key];
            case 'delete':
              storage.remove(key);
              return null;
            case 'containsKey':
              return storage.containsKey(key);
            case 'readAll':
              return Map<String, String>.from(storage);
          }
          return null;
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  setUp(() async {
    storage.clear();
    SharedPreferences.setMockInitialValues({});
  });

  test('empty storage returns no connections', () async {
    final repository = await _repository();

    expect(await repository.getAll(), isEmpty);
  });

  test('save persists a new connection without serializing the password', () async {
    final repository = await _repository();
    final saved = connection();

    await repository.save(saved);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('querypod_connections');
    final decoded = jsonDecode(raw!) as List<dynamic>;
    expect(decoded, hasLength(1));
    expect(decoded.single['name'], 'Local DB');
    expect(decoded.single.containsKey('password'), isFalse);
    expect(storage['querypod_connection_connection-1'], 'secret');
  });

  test('save updates an existing connection instead of duplicating it', () async {
    final repository = await _repository();
    await repository.save(connection(name: 'Old Name'));

    await repository.save(connection(name: 'New Name'));

    final connections = await repository.getAll();
    expect(connections, hasLength(1));
    expect(connections.single.name, 'New Name');
  });

  test('getAll and getById rehydrate the stored password', () async {
    final repository = await _repository();
    await repository.save(connection(password: 'db-secret'));

    expect((await repository.getAll()).single.password, 'db-secret');
    expect((await repository.getById('connection-1'))!.password, 'db-secret');
  });

  test('delete removes the connection and its stored password', () async {
    final repository = await _repository();
    await repository.save(connection());

    await repository.delete('connection-1');

    expect(await repository.getAll(), isEmpty);
    expect(storage.containsKey('querypod_connection_connection-1'), isFalse);
  });

  test('getById returns null for missing ids', () async {
    final repository = await _repository();

    expect(await repository.getById('missing'), isNull);
  });

  test('selected connection id round-trips and clears', () async {
    final repository = await _repository();

    await repository.setSelectedId('connection-1');
    expect(await repository.getSelectedId(), 'connection-1');

    await repository.setSelectedId(null);
    expect(await repository.getSelectedId(), isNull);
  });

  test('keyNamespace isolates connections selected id and passwords', () async {
    final defaultRepository = await _repository();
    final alphaRepository = await _repository(namespace: 'alpha');
    final betaRepository = await _repository(namespace: 'beta');

    await defaultRepository.save(connection(id: 'default'));
    await defaultRepository.setSelectedId('default');
    await alphaRepository.save(connection(id: 'alpha', password: 'alpha-secret'));
    await alphaRepository.setSelectedId('alpha');

    expect((await defaultRepository.getAll()).single.id, 'default');
    expect(await defaultRepository.getSelectedId(), 'default');
    expect((await alphaRepository.getAll()).single.id, 'alpha');
    expect((await alphaRepository.getById('alpha'))!.password, 'alpha-secret');
    expect(await alphaRepository.getSelectedId(), 'alpha');
    expect(await betaRepository.getAll(), isEmpty);
    expect(await betaRepository.getSelectedId(), isNull);
  });
}

Future<ConnectionRepositoryImpl> _repository({String namespace = ''}) async {
  final prefs = await SharedPreferences.getInstance();
  return ConnectionRepositoryImpl(
    secureStorage: const FlutterSecureStorage(),
    prefs: prefs,
    keyNamespace: namespace,
  );
}
