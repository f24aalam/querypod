import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/database_transfer/data/database_tool_repository_impl.dart';
import 'package:querypod/features/database_transfer/data/database_transfer_repository_impl.dart';
import 'package:querypod/features/database_transfer/domain/database_transfer.dart';

import 'support/persistence_test_support.dart';

void main() {
  test('SQLite gzip SQL round trip uses staging and preserves data', () async {
    if (!await _hasSqliteCli()) return;
    final directory = await Directory.systemTemp.createTemp(
      'querypod_transfer_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final appDatabase = createTestDatabase();
    addTearDown(appDatabase.close);

    final source = '${directory.path}/source.sqlite';
    final target = '${directory.path}/target.sqlite';
    final dump = '${directory.path}/backup.sql.gz';
    await _sqlite(
      source,
      [
        'CREATE TABLE projects(id INTEGER PRIMARY KEY, name TEXT NOT NULL);',
        "INSERT INTO projects(name) VALUES ('QueryPod'), ('Workbench');",
      ].join(),
    );
    await _sqlite(target, 'CREATE TABLE obsolete(id INTEGER);');

    final repository = DatabaseTransferRepositoryImpl(
      tools: DatabaseToolRepositoryImpl(database: appDatabase),
    );
    final exportEvents = await repository
        .run(
          DatabaseTransferRequest(
            direction: DatabaseTransferDirection.export,
            connection: _sqliteConnection(source),
            database: 'source.sqlite',
            path: dump,
            format: DatabaseTransferFormat.sqliteSql,
            gzip: true,
          ),
        )
        .toList();
    expect(exportEvents.last, isA<DatabaseTransferCompleted>());
    final compressed = await File(dump).readAsBytes();
    expect(compressed.take(2), [0x1f, 0x8b]);

    final importEvents = await repository
        .run(
          DatabaseTransferRequest(
            direction: DatabaseTransferDirection.import,
            connection: _sqliteConnection(target),
            database: 'target.sqlite',
            path: dump,
            format: DatabaseTransferFormat.sqliteSql,
            restoreMode: DatabaseRestoreMode.clean,
            gzip: true,
          ),
        )
        .toList();
    expect(importEvents.last, isA<DatabaseTransferCompleted>());
    expect(await _sqlite(target, 'SELECT COUNT(*) FROM projects;'), '2');
    expect(
      await _sqlite(
        target,
        "SELECT COUNT(*) FROM sqlite_master WHERE name='obsolete';",
      ),
      '0',
    );
  });

  test('SQLite native export creates a valid backup file', () async {
    if (!await _hasSqliteCli()) return;
    final directory = await Directory.systemTemp.createTemp(
      'querypod_native_backup_test_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final appDatabase = createTestDatabase();
    addTearDown(appDatabase.close);
    final source = '${directory.path}/source.sqlite';
    final backup = '${directory.path}/native backup.sqlite';
    await _sqlite(source, 'CREATE TABLE records(id INTEGER PRIMARY KEY);');

    final repository = DatabaseTransferRepositoryImpl(
      tools: DatabaseToolRepositoryImpl(database: appDatabase),
    );
    final events = await repository
        .run(
          DatabaseTransferRequest(
            direction: DatabaseTransferDirection.export,
            connection: _sqliteConnection(source),
            database: 'source.sqlite',
            path: backup,
            format: DatabaseTransferFormat.sqliteDatabase,
          ),
        )
        .toList();

    expect(events.last, isA<DatabaseTransferCompleted>());
    expect(
      String.fromCharCodes((await File(backup).readAsBytes()).take(16)),
      'SQLite format 3\u0000',
    );
  });
}

Connection _sqliteConnection(String path) => Connection(
  id: 'sqlite',
  name: 'SQLite',
  host: '',
  port: 0,
  user: '',
  password: '',
  database: path,
  workspaceId: 'workspace',
  type: ConnectionType.sqlite,
  useTls: false,
);

Future<bool> _hasSqliteCli() async {
  try {
    return (await Process.run('sqlite3', const ['--version'])).exitCode == 0;
  } catch (_) {
    return false;
  }
}

Future<String> _sqlite(String path, String sql) async {
  final result = await Process.run('sqlite3', [path, sql]);
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  return result.stdout.toString().trim();
}
