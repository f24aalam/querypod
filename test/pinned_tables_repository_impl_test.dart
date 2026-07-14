import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/editor/data/repositories/pinned_tables_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('empty storage returns no pinned tables', () async {
    final repository = await _repository();

    expect(
      await repository.getPinnedTables(
        connectionId: 'connection',
        database: 'app',
      ),
      isEmpty,
    );
  });

  test('pinned tables round-trip in saved order', () async {
    final repository = await _repository();

    await repository.setPinnedTables(
      connectionId: 'connection',
      database: 'app',
      tableNames: const ['orders', 'users'],
    );

    expect(
      await repository.getPinnedTables(
        connectionId: 'connection',
        database: 'app',
      ),
      ['orders', 'users'],
    );
  });

  test('pins are scoped by connection and database', () async {
    final repository = await _repository();

    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'app',
      tableNames: const ['users'],
    );
    await repository.setPinnedTables(
      connectionId: 'first',
      database: 'analytics',
      tableNames: const ['events'],
    );
    await repository.setPinnedTables(
      connectionId: 'second',
      database: 'app',
      tableNames: const ['orders'],
    );

    expect(
      await repository.getPinnedTables(connectionId: 'first', database: 'app'),
      ['users'],
    );
    expect(
      await repository.getPinnedTables(
        connectionId: 'first',
        database: 'analytics',
      ),
      ['events'],
    );
    expect(
      await repository.getPinnedTables(connectionId: 'second', database: 'app'),
      ['orders'],
    );
  });

  test('empty pin list removes stored database pins', () async {
    final repository = await _repository();

    await repository.setPinnedTables(
      connectionId: 'connection',
      database: 'app',
      tableNames: const ['users'],
    );
    await repository.setPinnedTables(
      connectionId: 'connection',
      database: 'app',
      tableNames: const [],
    );

    expect(
      await repository.getPinnedTables(
        connectionId: 'connection',
        database: 'app',
      ),
      isEmpty,
    );
  });

  test('keyNamespace isolates pinned table storage', () async {
    final defaultRepository = await _repository();
    final alphaRepository = await _repository(namespace: 'alpha');

    await defaultRepository.setPinnedTables(
      connectionId: 'connection',
      database: 'app',
      tableNames: const ['users'],
    );
    await alphaRepository.setPinnedTables(
      connectionId: 'connection',
      database: 'app',
      tableNames: const ['orders'],
    );

    expect(
      await defaultRepository.getPinnedTables(
        connectionId: 'connection',
        database: 'app',
      ),
      ['users'],
    );
    expect(
      await alphaRepository.getPinnedTables(
        connectionId: 'connection',
        database: 'app',
      ),
      ['orders'],
    );
  });
}

Future<PinnedTablesRepositoryImpl> _repository({String namespace = ''}) async {
  final prefs = await SharedPreferences.getInstance();
  return PinnedTablesRepositoryImpl(prefs, keyNamespace: namespace);
}
