import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/core/database/database_driver_factory.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/data/repositories/connection_metadata_repository_impl.dart';
import 'package:querypod/features/editor/data/repositories/table_data_repository_impl.dart';
import 'package:querypod/features/editor/domain/entities/connection_table.dart';
import 'package:querypod/features/editor/domain/entities/query_history.dart';
import 'package:querypod/features/editor/domain/repositories/query_history_repository.dart';

enum TestDatabaseEngine { mysql, postgres }

class DbIntegrationConfig {
  final TestDatabaseEngine engine;
  final String host;
  final int port;
  final String user;
  final String password;
  final String database;

  const DbIntegrationConfig({
    required this.engine,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    required this.database,
  });

  static DbIntegrationConfig requireFor(TestDatabaseEngine engine) {
    final prefix = switch (engine) {
      TestDatabaseEngine.mysql => 'QUERYPOD_MYSQL',
      TestDatabaseEngine.postgres => 'QUERYPOD_PG',
    };

    String? read(String key) {
      const empty = String.fromEnvironment('__empty__');
      final dartDefine = String.fromEnvironment(key, defaultValue: empty);
      if (dartDefine != empty && dartDefine.isNotEmpty) {
        return dartDefine;
      }

      final envValue = Platform.environment[key];
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }

      return null;
    }

    final host = read('${prefix}_HOST');
    final portValue = read('${prefix}_PORT');
    final user = read('${prefix}_USER');
    final password = read('${prefix}_PASSWORD');
    final database = read('${prefix}_DATABASE');

    final missing = <String>[
      if (host == null) '${prefix}_HOST',
      if (portValue == null) '${prefix}_PORT',
      if (user == null) '${prefix}_USER',
      if (password == null) '${prefix}_PASSWORD',
      if (database == null) '${prefix}_DATABASE',
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'Missing DB integration test config for ${engine.name}: '
        '${missing.join(', ')}. Start the dev-db containers and pass these via '
        '--dart-define or environment variables.',
      );
    }

    final port = int.tryParse(portValue!);
    if (port == null) {
      throw StateError(
        'Invalid port for ${engine.name}: ${prefix}_PORT must be an integer, '
        'got "$portValue".',
      );
    }

    return DbIntegrationConfig(
      engine: engine,
      host: host!,
      port: port,
      user: user!,
      password: password!,
      database: database!,
    );
  }

  Connection toConnection() {
    return Connection(
      id: '${engine.name}-integration',
      name: '${engine.name} integration',
      host: host,
      port: port,
      user: user,
      password: password,
      database: database,
      workspaceId: 'integration',
      type: switch (engine) {
        TestDatabaseEngine.mysql => ConnectionType.mysql,
        TestDatabaseEngine.postgres => ConnectionType.postgresql,
      },
      useTls: false,
    );
  }
}

class InMemoryHistoryRepository implements QueryHistoryRepository {
  final saved = <QueryHistory>[];
  final _controller = StreamController<void>.broadcast();

  @override
  Future<void> clearHistory(String connectionId) async {
    saved.removeWhere((history) => history.connectionId == connectionId);
    _controller.add(null);
  }

  @override
  Future<List<QueryHistory>> getAllForConnection(String connectionId) async {
    return saved
        .where((history) => history.connectionId == connectionId)
        .toList();
  }

  @override
  Future<QueryHistory> save(QueryHistory history) async {
    saved.add(history);
    _controller.add(null);
    return history;
  }

  @override
  Stream<void> watchHistory(String connectionId) => _controller.stream;
}

class RepositoryIntegrationHarness {
  final DbIntegrationConfig config;
  final Connection connection;
  final ConnectionMetadataRepositoryImpl metadataRepository;
  final TableDataRepositoryImpl tableRepository;
  final InMemoryHistoryRepository historyRepository;

  RepositoryIntegrationHarness._({
    required this.config,
    required this.connection,
    required this.metadataRepository,
    required this.tableRepository,
    required this.historyRepository,
  });

  factory RepositoryIntegrationHarness(DbIntegrationConfig config) {
    final historyRepository = InMemoryHistoryRepository();
    return RepositoryIntegrationHarness._(
      config: config,
      connection: config.toConnection(),
      metadataRepository: ConnectionMetadataRepositoryImpl(),
      tableRepository: TableDataRepositoryImpl(
        historyRepository: historyRepository,
      ),
      historyRepository: historyRepository,
    );
  }

  Future<void> expectSuccessfulConnection() async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.testConnection(connection);
  }

  Future<void> expectFailedConnectionWithWrongPassword() async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    final wrongPassword = connection.copyWith(
      password: '${connection.password}-wrong',
    );
    await expectLater(
      () => driver.testConnection(wrongPassword),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Failed to connect'),
        ),
      ),
    );
  }

  Future<void> expectDatabaseVisible() async {
    final databases = await metadataRepository.listDatabases(connection);
    expect(
      databases.map((database) => database.name),
      contains(config.database),
    );
  }

  Future<void> expectSeededTablesVisible() async {
    final tables = await metadataRepository.listTables(
      connection,
      config.database,
    );
    final names = tables.map((table) => table.name).toSet();

    expect(
      names,
      containsAll(<String>[
        'users',
        'projects',
        'project_members',
        'activity_logs',
        'large_events',
      ]),
    );

    final view = tables.firstWhere(
      (table) => table.name == 'active_project_overview',
      orElse: () =>
          const ConnectionTable(name: '', type: ConnectionTableType.table),
    );
    expect(view.name, 'active_project_overview');
    expect(view.type, ConnectionTableType.view);
  }

  Future<void> expectProjectColumnsAndRelations() async {
    final structure = await tableRepository.inspectTable(
      connection,
      config.database,
      'projects',
    );

    final columnsByName = {
      for (final column in structure.columns) column.name: column,
    };
    expect(
      columnsByName.keys,
      containsAll(<String>[
        'id',
        'owner_user_id',
        'slug',
        'metadata',
        'created_at',
      ]),
    );
    expect(columnsByName['id']!.isPrimaryKey, isTrue);
    expect(columnsByName['owner_user_id']!.foreignKey, isNotNull);
    expect(columnsByName['owner_user_id']!.foreignKey!.targetTable, 'users');
    expect(columnsByName['owner_user_id']!.foreignKey!.targetColumn, 'id');
  }

  Future<void> expectCompositePrimaryAndForeignKeys() async {
    final structure = await tableRepository.inspectTable(
      connection,
      config.database,
      'project_members',
    );

    final columnsByName = {
      for (final column in structure.columns) column.name: column,
    };

    expect(columnsByName['project_id']!.isPrimaryKey, isTrue);
    expect(columnsByName['user_id']!.isPrimaryKey, isTrue);
    expect(columnsByName['project_id']!.foreignKey, isNotNull);
    expect(columnsByName['project_id']!.foreignKey!.targetTable, 'projects');
    expect(columnsByName['project_id']!.foreignKey!.targetColumn, 'id');
    expect(columnsByName['user_id']!.foreignKey, isNotNull);
    expect(columnsByName['user_id']!.foreignKey!.targetTable, 'users');
    expect(columnsByName['user_id']!.foreignKey!.targetColumn, 'id');
  }

  Future<void> expectSimpleSelect() async {
    final results = await tableRepository.executeQuery(
      connection,
      config.database,
      'SELECT id, email FROM users ORDER BY id LIMIT 2',
    );

    expect(results, hasLength(1));
    final result = results.single;
    expect(result.errorMessage, isNull);
    expect(result.structure, isNotNull);
    expect(result.structure!.columns.map((column) => column.name), [
      'id',
      'email',
    ]);
    expect(result.rows, hasLength(2));
    expect(result.rows.first.cells[1].display, contains('@example.com'));
  }

  Future<void> expectInvalidSqlError() async {
    final results = await tableRepository.executeQuery(
      connection,
      config.database,
      'SELECT FROM definitely_broken',
    );

    expect(results, hasLength(1));
    final result = results.single;
    expect(result.rows, isEmpty);
    expect(result.errorMessage, isNotNull);
    expect(result.errorMessage, isNotEmpty);
  }

  Future<void> expectPaginationOnLargeEvents() async {
    final structure = await tableRepository.inspectTable(
      connection,
      config.database,
      'large_events',
    );

    final total = await tableRepository.countRows(
      connection,
      config.database,
      'large_events',
      structure: structure,
    );
    expect(total, 1000);

    final firstPage = await tableRepository.fetchRows(
      connection,
      config.database,
      'large_events',
      structure: structure,
      offset: 0,
      limit: 25,
    );
    final secondPage = await tableRepository.fetchRows(
      connection,
      config.database,
      'large_events',
      structure: structure,
      offset: 25,
      limit: 25,
    );

    expect(firstPage.rows, hasLength(25));
    expect(secondPage.rows, hasLength(25));

    final firstId = firstPage.rows.first.cells.first.display;
    final secondId = secondPage.rows.first.cells.first.display;
    expect(firstId, isNot(secondId));
  }
}

void defineRepositoryIntegrationSuite(TestDatabaseEngine engine) {
  final config = DbIntegrationConfig.requireFor(engine);
  final harness = RepositoryIntegrationHarness(config);

  group('${engine.name} repository integration', () {
    test('successful connection', harness.expectSuccessfulConnection);
    test(
      'failed connection with wrong password',
      harness.expectFailedConnectionWithWrongPassword,
    );
    test('list schemas/databases', harness.expectDatabaseVisible);
    test('list tables', harness.expectSeededTablesVisible);
    test('list columns', harness.expectProjectColumnsAndRelations);
    test(
      'detect primary keys and foreign keys',
      harness.expectCompositePrimaryAndForeignKeys,
    );
    test('execute simple SELECT queries', harness.expectSimpleSelect);
    test(
      'execute invalid SQL and return a clean error',
      harness.expectInvalidSqlError,
    );
    test(
      'paginate/query limited result sets',
      harness.expectPaginationOnLargeEvents,
    );
  });
}
