import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/data/repositories/table_data_repository_impl.dart';
import 'package:querypod/features/editor/domain/entities/query_history.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';
import 'package:querypod/features/editor/domain/repositories/query_history_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late String databasePath;
  late Connection connection;
  late _FakeQueryHistoryRepository historyRepository;
  late TableDataRepositoryImpl repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('querypod_table_repo_');
    databasePath = '${tempDir.path}/table_repo.sqlite';
    final db = await databaseFactoryFfi.openDatabase(databasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await db.execute('CREATE TABLE profiles (id INTEGER PRIMARY KEY, bio TEXT)');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT,
        profile_id INTEGER REFERENCES profiles(id)
      )
    ''');
    await db.insert('profiles', {'id': 1, 'bio': 'Builder'});
    await db.insert('users', {'id': 1, 'name': 'Alice', 'profile_id': 1});
    await db.insert('users', {'id': 2, 'name': 'Bob', 'profile_id': 1});
    await db.close();

    connection = Connection(
      id: 'sqlite-connection',
      name: 'SQLite',
      host: '',
      port: 0,
      user: '',
      password: '',
      database: databasePath,
      workspaceId: 'default',
      type: ConnectionType.sqlite,
      useTls: false,
    );
    historyRepository = _FakeQueryHistoryRepository();
    repository = TableDataRepositoryImpl(historyRepository: historyRepository);
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(databasePath);
    await tempDir.delete(recursive: true);
  });

  test('inspectTable returns schema and records query history', () async {
    final structure = await repository.inspectTable(connection, 'main', 'users');

    expect(structure.columns.map((column) => column.name).toList(), [
      'id',
      'name',
      'profile_id',
    ]);
    expect(
      structure.columns.firstWhere((column) => column.name == 'profile_id').foreignKey,
      isNotNull,
    );
    expect(historyRepository.saved, isNotEmpty);
    expect(historyRepository.saved.first.connectionId, 'sqlite-connection');
  });

  test('countRows and fetchRows honor search and filters', () async {
    final structure = await repository.inspectTable(connection, 'main', 'users');

    expect(
      await repository.countRows(
        connection,
        'main',
        'users',
        structure: structure,
      ),
      2,
    );
    expect(
      await repository.countRows(
        connection,
        'main',
        'users',
        structure: structure,
        searchQuery: 'Ali',
      ),
      1,
    );
    expect(
      await repository.countRows(
        connection,
        'main',
        'users',
        structure: structure,
        filters: const [TableFilter(column: 'name', operator: '=', value: 'Bob')],
      ),
      1,
    );
    expect(
      await repository.countRows(
        connection,
        'main',
        'users',
        structure: structure,
        searchQuery: '1',
        searchColumn: 'profile_id',
      ),
      2,
    );
    expect(
      await repository.countRows(
        connection,
        'main',
        'users',
        structure: structure,
        searchQuery: 'Ali',
        searchColumn: 'id',
      ),
      0,
    );

    final page = await repository.fetchRows(
      connection,
      'main',
      'users',
      structure: structure,
      offset: 1,
      limit: 1,
    );
    expect(page.rows, hasLength(1));
    expect(page.rows.single.cells[1].display, 'Bob');
  });

  test('commitChanges applies edits deletes and inserts', () async {
    final structure = await repository.inspectTable(connection, 'main', 'users');
    final originalPage = await repository.fetchRows(
      connection,
      'main',
      'users',
      structure: structure,
      offset: 0,
      limit: 10,
    );

    await repository.commitChanges(
      connection,
      'main',
      'users',
      structure: structure,
      cellChanges: [
        TableCellChange(
          row: originalPage.rows.first,
          columnIndex: 1,
          value: 'Alicia',
        ),
      ],
      deletedRows: [originalPage.rows[1]],
      insertedRows: const [
        {'name': 'Cara', 'profile_id': '1'},
      ],
    );

    final updatedPage = await repository.fetchRows(
      connection,
      'main',
      'users',
      structure: structure,
      offset: 0,
      limit: 10,
    );
    expect(updatedPage.rows, hasLength(2));
    expect(updatedPage.rows.first.cells[1].display, 'Alicia');
    expect(
      updatedPage.rows.map((row) => row.cells[1].display).toList(),
      contains('Cara'),
    );
  });

  test('executeQuery delegates through the SQLite driver', () async {
    final results = await repository.executeQuery(
      connection,
      'main',
      'SELECT name FROM users ORDER BY id',
    );

    expect(results, hasLength(1));
    expect(results.single.rows, hasLength(2));
    expect(results.single.rows.first.cells.first.display, 'Alice');
  });
}

class _FakeQueryHistoryRepository implements QueryHistoryRepository {
  final List<QueryHistory> saved = [];

  @override
  Future<void> clearHistory(String connectionId) async {}

  @override
  Future<List<QueryHistory>> getAllForConnection(String connectionId) async => [];

  @override
  Future<QueryHistory> save(QueryHistory history) async {
    saved.add(history);
    return history;
  }

  @override
  Stream<void> watchHistory(String connectionId) => const Stream<void>.empty();
}
