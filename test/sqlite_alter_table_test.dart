import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/core/database/drivers/sqlite_driver.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/editor/domain/entities/table_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory temporaryDirectory;
  late String databasePath;
  late Connection connection;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'querypod_sqlite_alter_',
    );
    databasePath = '${temporaryDirectory.path}/database.sqlite';
    connection = Connection(
      id: 'sqlite-test',
      name: 'SQLite test',
      host: '',
      port: 0,
      user: '',
      password: '',
      database: databasePath,
      workspaceId: 'default',
      type: ConnectionType.sqlite,
    );
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(databasePath);
    await temporaryDirectory.delete(recursive: true);
  });

  test('rebuild preserves data and dependent schema through renames', () async {
    final db = await databaseFactoryFfi.openDatabase(databasePath);
    await db.execute('PRAGMA foreign_keys=ON');
    await db.execute('CREATE TABLE parents (id INTEGER PRIMARY KEY)');
    await db.execute('CREATE TABLE audit (value TEXT)');
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT UNIQUE,
        parent_id INTEGER,
        label TEXT,
        FOREIGN KEY (parent_id) REFERENCES parents(id)
      )
    ''');
    await db.execute('CREATE INDEX items_label_idx ON items(label)');
    await db.execute('''
      CREATE TRIGGER items_label_audit
      AFTER UPDATE OF label ON items
      BEGIN
        INSERT INTO audit(value) VALUES (NEW.label);
      END
    ''');
    await db.execute('''
      CREATE TABLE item_children (
        id INTEGER PRIMARY KEY,
        item_code TEXT REFERENCES items(code)
      )
    ''');
    await db.insert('parents', {'id': 1});
    await db.insert('items', {'code': 'A', 'parent_id': 1, 'label': 'Old'});
    await db.close();

    const oldColumns = [
      TableColumnDefinition(
        name: 'id',
        originalName: 'id',
        type: 'INTEGER',
        isPrimaryKey: true,
        isAutoIncrement: true,
      ),
      TableColumnDefinition(name: 'code', originalName: 'code', type: 'TEXT'),
      TableColumnDefinition(
        name: 'parent_id',
        originalName: 'parent_id',
        type: 'INTEGER',
      ),
      TableColumnDefinition(name: 'label', originalName: 'label', type: 'TEXT'),
    ];
    const newColumns = [
      TableColumnDefinition(
        name: 'id',
        originalName: 'id',
        type: 'INTEGER',
        isPrimaryKey: true,
        isAutoIncrement: true,
      ),
      TableColumnDefinition(name: 'sku', originalName: 'code', type: 'TEXT'),
      TableColumnDefinition(
        name: 'parent_id',
        originalName: 'parent_id',
        type: 'INTEGER',
      ),
      TableColumnDefinition(
        name: 'title',
        originalName: 'label',
        type: 'TEXT',
        isNullable: false,
      ),
    ];

    await SQLiteDriver().alterTable(
      connection,
      'main',
      'items',
      'products',
      oldColumns,
      newColumns,
    );

    final check = await databaseFactoryFfi.openDatabase(databasePath);
    await check.execute('PRAGMA foreign_keys=ON');
    expect(await check.query('products'), [
      {'id': 1, 'sku': 'A', 'parent_id': 1, 'title': 'Old'},
    ]);
    final indexSql = await check.rawQuery(
      "SELECT sql FROM sqlite_master WHERE name='items_label_idx'",
    );
    expect(indexSql.single['sql'], contains('title'));
    final triggerSql = await check.rawQuery(
      "SELECT sql FROM sqlite_master WHERE name='items_label_audit'",
    );
    expect(triggerSql.single['sql'], contains('NEW."title"'));
    expect(
      (await check.rawQuery(
        'PRAGMA foreign_key_list(products)',
      )).any((row) => row['table'] == 'parents'),
      isTrue,
    );
    final inboundForeignKeys = await check.rawQuery(
      'PRAGMA foreign_key_list(item_children)',
    );
    expect(inboundForeignKeys.any((row) => row['table'] == 'products'), isTrue);
    expect(inboundForeignKeys.single['to'], 'sku');
    await check.update('products', {'title': 'New'}, where: 'id = 1');
    expect(await check.query('audit'), [
      {'value': 'New'},
    ]);
    expect(
      () => check.insert('products', {
        'sku': 'B',
        'parent_id': 999,
        'title': 'Invalid',
      }),
      throwsA(anything),
    );
    expect(
      () => check.insert('products', {
        'sku': 'A',
        'parent_id': 1,
        'title': 'Duplicate',
      }),
      throwsA(anything),
    );
    await check.close();
  });

  test('failed rebuild rolls back the original table', () async {
    final db = await databaseFactoryFfi.openDatabase(databasePath);
    await db.execute('PRAGMA foreign_keys=ON');
    await db.execute('CREATE TABLE items (id INTEGER PRIMARY KEY)');
    await db.insert('items', {'id': 1});
    await db.close();

    const oldColumns = [
      TableColumnDefinition(
        name: 'id',
        originalName: 'id',
        type: 'INTEGER',
        isPrimaryKey: true,
      ),
    ];
    const newColumns = [
      TableColumnDefinition(
        name: 'id',
        originalName: 'id',
        type: 'INTEGER',
        isPrimaryKey: true,
      ),
      TableColumnDefinition(
        name: 'required_value',
        type: 'TEXT',
        isNullable: false,
      ),
    ];

    await expectLater(
      SQLiteDriver().alterTable(
        connection,
        'main',
        'items',
        'items',
        oldColumns,
        newColumns,
      ),
      throwsA(anything),
    );

    final check = await databaseFactoryFfi.openDatabase(databasePath);
    expect(await check.query('items'), [
      {'id': 1},
    ]);
    expect(
      (await check.rawQuery(
        'PRAGMA table_info(items)',
      )).map((row) => row['name']),
      ['id'],
    );
    await check.close();
  });

  test('native table rename keeps schema and data intact', () async {
    final db = await databaseFactoryFfi.openDatabase(databasePath);
    await db.execute('CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT)');
    await db.insert('items', {'id': 1, 'name': 'One'});
    await db.close();
    const columns = [
      TableColumnDefinition(
        name: 'id',
        originalName: 'id',
        type: 'INTEGER',
        isPrimaryKey: true,
      ),
      TableColumnDefinition(name: 'name', originalName: 'name', type: 'TEXT'),
    ];

    await SQLiteDriver().alterTable(
      connection,
      'main',
      'items',
      'products',
      columns,
      columns,
    );

    final check = await databaseFactoryFfi.openDatabase(databasePath);
    expect(await check.query('products'), [
      {'id': 1, 'name': 'One'},
    ]);
    await check.close();
  });

  test('rejects a primary-key change used by another table', () async {
    final db = await databaseFactoryFfi.openDatabase(databasePath);
    await db.execute('PRAGMA foreign_keys=ON');
    await db.execute(
      'CREATE TABLE items (id INTEGER PRIMARY KEY, code TEXT NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE children (item_id INTEGER REFERENCES items(id))',
    );
    await db.insert('items', {'id': 1, 'code': 'A'});
    await db.close();

    const oldColumns = [
      TableColumnDefinition(
        name: 'id',
        originalName: 'id',
        type: 'INTEGER',
        isPrimaryKey: true,
      ),
      TableColumnDefinition(
        name: 'code',
        originalName: 'code',
        type: 'TEXT',
        isNullable: false,
      ),
    ];
    const newColumns = [
      TableColumnDefinition(name: 'id', originalName: 'id', type: 'INTEGER'),
      TableColumnDefinition(
        name: 'code',
        originalName: 'code',
        type: 'TEXT',
        isPrimaryKey: true,
        isNullable: false,
      ),
    ];

    await expectLater(
      SQLiteDriver().alterTable(
        connection,
        'main',
        'items',
        'items',
        oldColumns,
        newColumns,
      ),
      throwsA(isA<UnsupportedError>()),
    );

    final check = await databaseFactoryFfi.openDatabase(databasePath);
    expect(await check.query('items'), [
      {'id': 1, 'code': 'A'},
    ]);
    await check.close();
  });
}
