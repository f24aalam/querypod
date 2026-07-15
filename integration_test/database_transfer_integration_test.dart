import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/database_transfer/data/database_tool_repository_impl.dart';
import 'package:querypod/features/database_transfer/data/database_transfer_repository_impl.dart';
import 'package:querypod/features/database_transfer/domain/database_transfer.dart';

import '../test/support/persistence_test_support.dart';

void main() {
  final enabled =
      Platform.environment['QUERYPOD_TRANSFER_INTEGRATION'] == 'true';

  test('MySQL SQL gzip clean restore round trip', () async {
    if (!enabled) return;
    final directory = await Directory.systemTemp.createTemp(
      'querypod_mysql_transfer_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final appDatabase = createTestDatabase();
    addTearDown(appDatabase.close);
    const database = 'querypod_transfer_mysql';
    final connection = _mysqlConnection(database);
    await _mysql(
      'DROP DATABASE IF EXISTS `$database`; CREATE DATABASE `$database`; '
      'CREATE TABLE `$database`.records(id INT PRIMARY KEY, name VARCHAR(50)); '
      "INSERT INTO `$database`.records VALUES (1, 'original');",
    );
    addTearDown(() => _mysql('DROP DATABASE IF EXISTS `$database`;'));

    final repository = DatabaseTransferRepositoryImpl(
      tools: DatabaseToolRepositoryImpl(database: appDatabase),
    );
    final dump = '${directory.path}/mysql.sql.gz';
    final exportEvents = await repository
        .run(
          DatabaseTransferRequest(
            direction: DatabaseTransferDirection.export,
            connection: connection,
            database: database,
            path: dump,
            format: DatabaseTransferFormat.mysqlSql,
            gzip: true,
          ),
        )
        .toList();
    _expectCompleted(exportEvents);
    await _mysql('DROP TABLE `$database`.records;');

    final importEvents = await repository
        .run(
          DatabaseTransferRequest(
            direction: DatabaseTransferDirection.import,
            connection: connection,
            database: database,
            path: dump,
            format: DatabaseTransferFormat.mysqlSql,
            restoreMode: DatabaseRestoreMode.clean,
            gzip: true,
          ),
        )
        .toList();
    _expectCompleted(importEvents);
    expect(
      await _mysql('SELECT name FROM `$database`.records WHERE id=1;'),
      'original',
    );
  });

  test('PostgreSQL custom archive clean restore round trip', () async {
    if (!enabled) return;
    final directory = await Directory.systemTemp.createTemp(
      'querypod_postgres_transfer_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final appDatabase = createTestDatabase();
    addTearDown(appDatabase.close);
    const database = 'querypod_transfer_postgres';
    final connection = _postgresConnection(database);
    await _postgres(
      'postgres',
      'DROP DATABASE IF EXISTS $database WITH (FORCE);',
    );
    await _postgres('postgres', 'CREATE DATABASE $database;');
    await _postgres(
      database,
      "CREATE TABLE records(id INTEGER PRIMARY KEY, name TEXT); INSERT INTO records VALUES (1, 'original');",
    );
    addTearDown(
      () => _postgres(
        'postgres',
        'DROP DATABASE IF EXISTS $database WITH (FORCE);',
      ),
    );

    final repository = DatabaseTransferRepositoryImpl(
      tools: DatabaseToolRepositoryImpl(database: appDatabase),
    );
    final dump = '${directory.path}/postgres.dump';
    final exportEvents = await repository
        .run(
          DatabaseTransferRequest(
            direction: DatabaseTransferDirection.export,
            connection: connection,
            database: database,
            path: dump,
            format: DatabaseTransferFormat.postgresCustom,
          ),
        )
        .toList();
    _expectCompleted(exportEvents);
    await _postgres(database, 'DROP TABLE records;');

    final importEvents = await repository
        .run(
          DatabaseTransferRequest(
            direction: DatabaseTransferDirection.import,
            connection: connection,
            database: database,
            path: dump,
            format: DatabaseTransferFormat.postgresCustom,
            restoreMode: DatabaseRestoreMode.clean,
          ),
        )
        .toList();
    _expectCompleted(importEvents);
    expect(
      await _postgres(database, 'SELECT name FROM records WHERE id=1;'),
      'original',
    );
  });
}

void _expectCompleted(List<DatabaseTransferEvent> events) {
  if (events.last is DatabaseTransferFailed) {
    fail(
      '${(events.last as DatabaseTransferFailed).message}\n'
      '${events.whereType<DatabaseTransferLog>().map((event) => event.message).join('\n')}',
    );
  }
  expect(events.last, isA<DatabaseTransferCompleted>());
}

Connection _mysqlConnection(String database) => Connection(
  id: 'mysql',
  name: 'MySQL transfer',
  host: '127.0.0.1',
  port: 13306,
  user: 'root',
  password: 'rootpass',
  database: database,
  workspaceId: 'integration',
  type: ConnectionType.mysql,
  useTls: false,
);

Connection _postgresConnection(String database) => Connection(
  id: 'postgres',
  name: 'PostgreSQL transfer',
  host: '127.0.0.1',
  port: 15432,
  user: 'querypod',
  password: 'querypod',
  database: database,
  workspaceId: 'integration',
  type: ConnectionType.postgresql,
  useTls: false,
);

Future<String> _mysql(String sql) async {
  final result = await Process.run(
    'mysql',
    ['-h127.0.0.1', '-P13306', '-uroot', '-N', '-e', sql],
    environment: const {'MYSQL_PWD': 'rootpass'},
    includeParentEnvironment: true,
  );
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  return result.stdout.toString().trim();
}

Future<String> _postgres(String database, String sql) async {
  final result = await Process.run(
    'psql',
    [
      '-h127.0.0.1',
      '-p15432',
      '-Uquerypod',
      '-d$database',
      '-At',
      '-vON_ERROR_STOP=1',
      '-c$sql',
    ],
    environment: const {'PGPASSWORD': 'querypod'},
    includeParentEnvironment: true,
  );
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  return result.stdout.toString().trim();
}
