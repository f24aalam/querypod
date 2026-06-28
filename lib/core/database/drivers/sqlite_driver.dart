import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../../features/connections/domain/entities/connection.dart';
import '../../../features/workspace/domain/entities/query_history.dart';
import '../../../features/workspace/domain/entities/query_result.dart';
import '../../../features/workspace/domain/entities/table_data.dart';
import '../../../features/workspace/domain/entities/workspace_database.dart';
import '../../../features/workspace/domain/entities/workspace_table.dart';
import '../database_driver.dart';

class SQLiteDriver implements DatabaseDriver {
  @override
  List<String> get supportedOperators => [
    '=',
    '!=',
    '>',
    '<',
    '>=',
    '<=',
    'LIKE',
    'NOT LIKE',
  ];

  Future<Database> _connect(Connection connection) async {
    // For SQLite, the 'database' field stores the file path
    final path = connection.database;
    if (path.isEmpty) {
      throw Exception('Database file path is required for SQLite');
    }
    final database = await databaseFactoryFfi.openDatabase(path);
    await database.execute('PRAGMA foreign_keys=ON');
    return database;
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Uint8List) return utf8.decode(value, allowMalformed: true);
    return value.toString();
  }

  @override
  Future<void> testConnection(Connection connection) async {
    final db = await _connect(connection);
    try {
      await db.rawQuery('SELECT 1');
    } finally {
      await db.close();
    }
  }

  @override
  Future<List<WorkspaceDatabase>> listDatabases(Connection connection) async {
    // SQLite doesn't have multiple databases per connection in the same way,
    // so we return a single 'main' database or the file name.
    final name = connection.database.split('/').last;
    return [WorkspaceDatabase(name: name.isNotEmpty ? name : 'main')];
  }

  @override
  Future<List<WorkspaceTable>> listTables(
    Connection connection,
    String database,
  ) async {
    final db = await _connect(connection);
    try {
      final results = await db.rawQuery(
        "SELECT name, type FROM sqlite_master WHERE type='table' OR type='view'",
      );

      return results
          .map((row) {
            final tableName = _asString(row['name']);
            final tableType = _asString(row['type']).toUpperCase() == 'VIEW'
                ? WorkspaceTableType.view
                : WorkspaceTableType.table;

            return WorkspaceTable(name: tableName, type: tableType);
          })
          .where(
            (table) => table.name.isNotEmpty && table.name != 'sqlite_sequence',
          )
          .toList();
    } finally {
      await db.close();
    }
  }

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table, {
    void Function(QueryHistory)? onHistory,
  }) async {
    final db = await _connect(connection);
    try {
      final quotedTable = _quoteIdentifier(table);
      final sql = 'PRAGMA table_info($quotedTable)';
      final startMs = DateTime.now().millisecondsSinceEpoch;
      final schema = await db.rawQuery(sql);
      final execMs = DateTime.now().millisecondsSinceEpoch - startMs;

      onHistory?.call(
        QueryHistory(
          id: const Uuid().v4(),
          connectionId: connection.id,
          sourceType: 'table',
          sourceId: table,
          sql: sql,
          executionTimeMs: execMs,
          status: 'success',
          createdAt: DateTime.now(),
        ),
      );

      final columns = schema.map((row) {
        final name = _asString(row['name']);
        final type = _asString(row['type']);
        final isPk = row['pk'] != 0;
        final isNullable = row['notnull'] == 0;

        return TableDataColumn(
          name: name,
          databaseType: type,
          length: 0, // SQLite doesn't strictly enforce length in PRAGMA
          isPrimaryKey: isPk,
          isNullable: isNullable,
        );
      }).toList();

      final fkSql = 'PRAGMA foreign_key_list($quotedTable)';
      final startFkMs = DateTime.now().millisecondsSinceEpoch;
      final fkSchema = await db.rawQuery(fkSql);
      final execFkMs = DateTime.now().millisecondsSinceEpoch - startFkMs;

      onHistory?.call(
        QueryHistory(
          id: const Uuid().v4(),
          connectionId: connection.id,
          sourceType: 'table',
          sourceId: table,
          sql: fkSql,
          executionTimeMs: execFkMs,
          status: 'success',
          createdAt: DateTime.now(),
        ),
      );

      final fks = <String, TableForeignKey>{};
      for (final row in fkSchema) {
        final fromCol = _asString(row['from']);
        fks[fromCol] = TableForeignKey(
          targetTable: _asString(row['table']),
          targetColumn: _asString(row['to']),
        );
      }

      final columnsWithFks = columns.map((col) {
        return TableDataColumn(
          name: col.name,
          databaseType: col.databaseType,
          length: col.length,
          isPrimaryKey: col.isPrimaryKey,
          isNullable: col.isNullable,
          foreignKey: fks[col.name],
        );
      }).toList();

      if (columnsWithFks.isEmpty) {
        throw StateError('The table does not expose any columns');
      }

      final indexes = <TableIndex>[];
      final indexSql = 'PRAGMA index_list($quotedTable)';
      final indexList = await db.rawQuery(indexSql);

      for (final row in indexList) {
        final indexName = _asString(row['name']);
        final isUnique = row['unique'] == 1;
        final origin = _asString(row['origin']);

        final infoSql = 'PRAGMA index_info(${_quoteIdentifier(indexName)})';
        final infoList = await db.rawQuery(infoSql);

        final indexCols = <String>[];
        for (final infoRow in infoList) {
          final colName = _asString(infoRow['name']);
          if (colName.isNotEmpty) indexCols.add(colName);
        }

        if (indexCols.isNotEmpty) {
          indexes.add(
            TableIndex(
              name: indexName,
              columns: indexCols,
              isUnique: isUnique,
              isPrimaryKey: origin == 'pk',
            ),
          );
        }
      }

      final orderColumn = columnsWithFks
          .firstWhere(
            (column) => column.isPrimaryKey,
            orElse: () => columnsWithFks.first,
          )
          .name;
      return TableStructure(
        columns: columnsWithFks,
        indexes: indexes,
        orderColumn: orderColumn,
      );
    } finally {
      await db.close();
    }
  }

  @override
  Future<int> countRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    String? searchQuery,
    List<TableFilter>? filters,
    void Function(QueryHistory)? onHistory,
  }) async {
    final db = await _connect(connection);
    try {
      var sql = 'SELECT COUNT(*) AS total FROM ${_quoteIdentifier(table)}';
      final queryParams = <Object?>[];
      final whereClauses = <String>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchClauses = structure.columns
            .map((col) => '${_quoteIdentifier(col.name)} LIKE ?')
            .join(' OR ');
        whereClauses.add('($searchClauses)');
        queryParams.addAll(
          List.filled(structure.columns.length, '%$searchQuery%'),
        );
      }

      if (filters != null && filters.isNotEmpty) {
        for (final filter in filters) {
          whereClauses.add(
            '${_quoteIdentifier(filter.column)} ${filter.operator} ?',
          );
          queryParams.add(filter.value);
        }
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }
      final startMs = DateTime.now().millisecondsSinceEpoch;
      final result = await db.rawQuery(sql, queryParams);
      final execMs = DateTime.now().millisecondsSinceEpoch - startMs;

      onHistory?.call(
        QueryHistory(
          id: const Uuid().v4(),
          connectionId: connection.id,
          sourceType: 'table',
          sourceId: table,
          sql: sql,
          executionTimeMs: execMs,
          status: 'success',
          createdAt: DateTime.now(),
        ),
      );

      final value = result.first['total'];
      return int.tryParse(_asString(value)) ?? 0;
    } finally {
      await db.close();
    }
  }

  @override
  Future<TableRowsPage> fetchRows(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required int offset,
    required int limit,
    String? searchQuery,
    List<TableFilter>? filters,
    void Function(QueryHistory)? onHistory,
  }) async {
    final db = await _connect(connection);
    final stopwatch = Stopwatch()..start();
    try {
      var sql = 'SELECT * FROM ${_quoteIdentifier(table)}';

      final queryParams = <Object?>[];
      final whereClauses = <String>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchClauses = structure.columns
            .map((col) => '${_quoteIdentifier(col.name)} LIKE ?')
            .join(' OR ');
        whereClauses.add('($searchClauses)');
        queryParams.addAll(
          List.filled(structure.columns.length, '%$searchQuery%'),
        );
      }

      if (filters != null && filters.isNotEmpty) {
        for (final filter in filters) {
          whereClauses.add(
            '${_quoteIdentifier(filter.column)} ${filter.operator} ?',
          );
          queryParams.add(filter.value);
        }
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }

      sql +=
          ' ORDER BY ${_quoteIdentifier(structure.orderColumn)} ASC '
          'LIMIT $limit OFFSET $offset';
      final startMs = DateTime.now().millisecondsSinceEpoch;
      final result = await db.rawQuery(sql, queryParams);
      final execMs = DateTime.now().millisecondsSinceEpoch - startMs;

      onHistory?.call(
        QueryHistory(
          id: const Uuid().v4(),
          connectionId: connection.id,
          sourceType: 'table',
          sourceId: table,
          sql: sql,
          executionTimeMs: execMs,
          status: 'success',
          createdAt: DateTime.now(),
        ),
      );

      final rows = result.map((row) {
        return TableDataRow([
          for (var col in structure.columns) _cell(row[col.name], col),
        ]);
      }).toList();

      stopwatch.stop();
      return TableRowsPage(rows: rows, queryDuration: stopwatch.elapsed);
    } finally {
      stopwatch.stop();
      await db.close();
    }
  }

  @override
  Future<void> commitChanges(
    Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    required List<TableCellChange> cellChanges,
    required List<TableDataRow> deletedRows,
    required List<Map<String, dynamic>> insertedRows,
    void Function(QueryHistory)? onHistory,
  }) async {
    final primaryKeyIndexes = <int>[
      for (var index = 0; index < structure.columns.length; index++)
        if (structure.columns[index].isPrimaryKey) index,
    ];
    if (primaryKeyIndexes.isEmpty) {
      throw StateError('This table has no primary key and is read-only');
    }

    final db = await _connect(connection);
    try {
      await db.transaction((txn) async {
        for (final change in cellChanges) {
          await _executeUpdate(
            connection.id,
            txn,
            table,
            structure,
            primaryKeyIndexes,
            change,
            onHistory,
          );
        }
        for (final row in deletedRows) {
          await _executeDelete(
            connection.id,
            txn,
            table,
            structure,
            primaryKeyIndexes,
            row,
            onHistory,
          );
        }
        for (final row in insertedRows) {
          await _executeInsert(
            connection.id,
            txn,
            table,
            structure,
            row,
            onHistory,
          );
        }
      });
    } finally {
      await db.close();
    }
  }

  Future<void> _executeInsert(
    String connectionId,
    Transaction txn,
    String table,
    TableStructure structure,
    Map<String, dynamic> insertedRow,
    void Function(QueryHistory)? onHistory,
  ) async {
    final columns = <String>[];
    final placeholders = <String>[];
    final args = <Object?>[];

    for (final entry in insertedRow.entries) {
      final col = structure.columns.firstWhere((c) => c.name == entry.key);
      columns.add(_quoteIdentifier(col.name));
      placeholders.add('?');
      if (_isBinaryColumn(col.databaseType) && entry.value != null && entry.value.toString().isNotEmpty) {
        args.add(_decodeHex(entry.value.toString()));
      } else {
        args.add(entry.value);
      }
    }

    String sql;
    if (columns.isEmpty) {
      sql = 'INSERT INTO ${_quoteIdentifier(table)} DEFAULT VALUES';
    } else {
      sql =
          'INSERT INTO ${_quoteIdentifier(table)} (${columns.join(', ')}) '
          'VALUES (${placeholders.join(', ')})';
    }

    final startMs = DateTime.now().millisecondsSinceEpoch;
    await txn.rawInsert(sql, args);
    final execMs = DateTime.now().millisecondsSinceEpoch - startMs;

    onHistory?.call(
      QueryHistory(
        id: const Uuid().v4(),
        connectionId: connectionId,
        sourceType: 'table',
        sourceId: table,
        sql: sql,
        executionTimeMs: execMs,
        status: 'success',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _executeUpdate(
    String connectionId,
    Transaction txn,
    String table,
    TableStructure structure,
    List<int> primaryKeyIndexes,
    TableCellChange change,
    void Function(QueryHistory)? onHistory,
  ) async {
    final column = structure.columns[change.columnIndex];
    final where = _primaryKeyWhere(structure, primaryKeyIndexes);
    final sql =
        'UPDATE ${_quoteIdentifier(table)} '
        'SET ${_quoteIdentifier(column.name)} = ? WHERE $where';

    final updatedValue =
        change.row.cells[change.columnIndex].kind == TableCellKind.binary
        ? _decodeHex(change.value)
        : change.value;

    final args = [
      updatedValue,
      for (final index in primaryKeyIndexes) change.row.cells[index].rawValue,
    ];

    final startMs = DateTime.now().millisecondsSinceEpoch;
    await txn.rawUpdate(sql, args);
    final execMs = DateTime.now().millisecondsSinceEpoch - startMs;

    onHistory?.call(
      QueryHistory(
        id: const Uuid().v4(),
        connectionId: connectionId,
        sourceType: 'table',
        sourceId: table,
        sql: sql,
        executionTimeMs: execMs,
        status: 'success',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _executeDelete(
    String connectionId,
    Transaction txn,
    String table,
    TableStructure structure,
    List<int> primaryKeyIndexes,
    TableDataRow row,
    void Function(QueryHistory)? onHistory,
  ) async {
    final where = _primaryKeyWhere(structure, primaryKeyIndexes);
    final sql = 'DELETE FROM ${_quoteIdentifier(table)} WHERE $where';
    final args = [
      for (final index in primaryKeyIndexes) row.cells[index].rawValue,
    ];

    final startMs = DateTime.now().millisecondsSinceEpoch;
    await txn.rawDelete(sql, args);
    final execMs = DateTime.now().millisecondsSinceEpoch - startMs;

    onHistory?.call(
      QueryHistory(
        id: const Uuid().v4(),
        connectionId: connectionId,
        sourceType: 'table',
        sourceId: table,
        sql: sql,
        executionTimeMs: execMs,
        status: 'success',
        createdAt: DateTime.now(),
      ),
    );
  }

  String _primaryKeyWhere(
    TableStructure structure,
    List<int> primaryKeyIndexes,
  ) {
    return primaryKeyIndexes
        .map(
          (index) => '${_quoteIdentifier(structure.columns[index].name)} = ?',
        )
        .join(' AND ');
  }

  String _quoteIdentifier(String value) => '"${value.replaceAll('"', '""')}"';

  TableCellValue _cell(dynamic value, TableDataColumn column) {
    if (value == null) return const TableCellValue.nullValue();
    if (value is Uint8List || value is List<int>) {
      final bytes = value is Uint8List
          ? value
          : Uint8List.fromList(value as List<int>);
      if (_isBinaryColumn(column.databaseType)) {
        return TableCellValue.binary(bytes);
      }
      try {
        return TableCellValue.text(utf8.decode(bytes));
      } on FormatException {
        return TableCellValue.binary(bytes);
      }
    }
    return TableCellValue.text(value.toString());
  }

  Uint8List _decodeHex(String value) {
    final normalized = value.trim().replaceFirst(
      RegExp(r'^0x', caseSensitive: false),
      '',
    );
    if (normalized.length.isOdd ||
        !RegExp(r'^[0-9a-fA-F]*$').hasMatch(normalized)) {
      throw const FormatException('Binary values must use hexadecimal text');
    }
    return Uint8List.fromList([
      for (var index = 0; index < normalized.length; index += 2)
        int.parse(normalized.substring(index, index + 2), radix: 16),
    ]);
  }

  bool _isBinaryColumn(String databaseType) {
    final type = databaseType.toLowerCase();
    return type.contains('blob') || type.contains('binary');
  }

  @override
  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
  ) async {
    Database? db;
    try {
      db = await _connect(connection);

      // Split into individual statements. Note: sqflite rawQuery might not support multiple statements in a single string,
      // so splitting by ';' is a simple approximation.
      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final results = <QueryResult>[];

      for (final statement in statements) {
        final stmtWatch = Stopwatch()..start();
        try {
          final isSelect =
              statement.toUpperCase().startsWith('SELECT') ||
              statement.toUpperCase().startsWith('PRAGMA');

          List<Map<String, Object?>> resultSet;
          if (isSelect) {
            resultSet = await db.rawQuery(statement);
          } else {
            final changes = await db.rawUpdate(statement);
            resultSet = [
              {'affected_rows': changes},
            ];
          }
          stmtWatch.stop();

          if (resultSet.isEmpty) {
            results.add(
              QueryResult(
                structure: null,
                rows: const [],
                queryDuration: stmtWatch.elapsed,
              ),
            );
            continue;
          }

          final firstRow = resultSet.first;
          final columns = firstRow.keys
              .map(
                (colName) => TableDataColumn(
                  name: colName,
                  databaseType:
                      'TEXT', // SQLite returns dynamic types, we just assume TEXT for display mostly
                  length: 0,
                  isPrimaryKey: false,
                  isNullable: true,
                ),
              )
              .toList();

          final structure = columns.isNotEmpty
              ? TableStructure(
                  columns: columns,
                  orderColumn: columns.first.name,
                )
              : null;

          final rows = resultSet
              .map(
                (row) => TableDataRow([
                  for (var col in columns) _cell(row[col.name], col),
                ]),
              )
              .toList();

          results.add(
            QueryResult(
              structure: structure,
              rows: rows,
              queryDuration: stmtWatch.elapsed,
            ),
          );
        } catch (e) {
          stmtWatch.stop();
          results.add(
            QueryResult(
              queryDuration: stmtWatch.elapsed,
              errorMessage: e.toString(),
              rows: const [],
            ),
          );
        }
      }

      return results;
    } catch (e) {
      return [QueryResult(errorMessage: e.toString(), rows: const [])];
    } finally {
      await db?.close();
    }
  }

  @override
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {
    throw UnsupportedError(
      'SQLite does not support creating multiple databases',
    );
  }

  @override
  Future<void> createTable(
    Connection connection,
    String database,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {
    final db = await _connect(connection);
    try {
      final columnDefs = _buildSqliteDefinitions(columns);
      final sql =
          'CREATE TABLE "${tableName.replaceAll('"', '""')}" (\n  ${columnDefs.join(',\n  ')}\n)';
      await db.execute(sql);
    } finally {
      await db.close();
    }
  }

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String table,
  ) async {
    final db = await _connect(connection);
    try {
      final quotedTable = _quoteIdentifier(table);
      final sql = 'PRAGMA table_info($quotedTable)';
      final schema = await db.rawQuery(sql);

      final masterSql =
          "SELECT sql FROM sqlite_master WHERE type='table' AND name=?";
      final masterRes = await db.rawQuery(masterSql, [table]);
      final createSql = masterRes.isNotEmpty
          ? masterRes.first['sql'] as String? ?? ''
          : '';

      final columns = schema.map((row) {
        final name = _asString(row['name']);
        final typeRaw = _asString(row['type']);
        final isPk = row['pk'] != 0;
        final isNullable = row['notnull'] == 0;
        final defaultValue = row['dflt_value'] != null
            ? _asString(row['dflt_value'])
            : null;

        bool isAutoIncrement = false;
        if (isPk) {
          final aiRegex = RegExp(
            '${RegExp.escape(name)}[^,]+AUTOINCREMENT',
            caseSensitive: false,
          );
          if (aiRegex.hasMatch(createSql)) {
            isAutoIncrement = true;
          }
        }

        int? length;
        var type = typeRaw;

        final lengthMatch = RegExp(r'\((\d+)\)').firstMatch(typeRaw);
        if (lengthMatch != null) {
          length = int.tryParse(lengthMatch.group(1)!);
          type = typeRaw.replaceAll(lengthMatch.group(0)!, '');
        }

        type = type.split(' ')[0].toUpperCase();

        var cleanDefault = defaultValue;
        if (cleanDefault != null) {
          if (cleanDefault.startsWith("'") && cleanDefault.endsWith("'")) {
            cleanDefault = cleanDefault.substring(1, cleanDefault.length - 1);
          }
        }

        return TableColumnDefinition(
          name: name,
          originalName: name,
          type: type,
          length: length,
          isPrimaryKey: isPk,
          isNullable: isNullable,
          isAutoIncrement: isAutoIncrement,
          defaultValue: cleanDefault,
        );
      }).toList();
      return columns;
    } finally {
      await db.close();
    }
  }

  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {
    final db = await _connect(connection);
    var foreignKeysEnabled = false;
    try {
      _validateSqliteAutoIncrement(newColumns);
      if (_canUseNativeSqliteAlter(oldColumns, newColumns)) {
        await _runNativeSqliteAlter(
          db,
          oldTableName,
          newTableName,
          oldColumns,
          newColumns,
        );
        return;
      }

      final stagedColumns = _stageSqliteColumns(oldColumns, newColumns);
      final schema = await _readSqliteSchema(
        db,
        oldTableName,
        oldColumns,
        stagedColumns,
      );
      final foreignKeyState = await db.rawQuery('PRAGMA foreign_keys');
      foreignKeysEnabled =
          foreignKeyState.isNotEmpty && foreignKeyState.first.values.first == 1;
      if (foreignKeysEnabled) await db.execute('PRAGMA foreign_keys=OFF');

      await db.transaction((transaction) async {
        final temporaryTable =
            '${oldTableName}_tmp_${DateTime.now().microsecondsSinceEpoch}';
        final definitions = _buildSqliteDefinitions(stagedColumns)
          ..addAll(schema.foreignKeys)
          ..addAll(schema.uniqueConstraints);
        var createSql =
            'CREATE TABLE ${_quoteSqlite(temporaryTable)} '
            '(\n  ${definitions.join(',\n  ')}\n)';
        final tableOptions = <String>[
          if (schema.withoutRowId) 'WITHOUT ROWID',
          if (schema.strict) 'STRICT',
        ];
        if (tableOptions.isNotEmpty) {
          createSql += ' ${tableOptions.join(', ')}';
        }
        await transaction.execute(createSql);

        final oldNames = <String>[];
        final newNames = <String>[];
        final oldMap = {for (final column in oldColumns) column.name: column};
        for (final newColumn in stagedColumns) {
          final originalName = newColumn.originalName;
          if (originalName != null && oldMap.containsKey(originalName)) {
            oldNames.add(_quoteSqlite(originalName));
            newNames.add(_quoteSqlite(newColumn.name));
          }
        }
        if (oldNames.isNotEmpty) {
          await transaction.execute(
            'INSERT INTO ${_quoteSqlite(temporaryTable)} '
            '(${newNames.join(', ')}) SELECT ${oldNames.join(', ')} '
            'FROM ${_quoteSqlite(oldTableName)}',
          );
        }

        await transaction.execute('DROP TABLE ${_quoteSqlite(oldTableName)}');
        await transaction.execute(
          'ALTER TABLE ${_quoteSqlite(temporaryTable)} '
          'RENAME TO ${_quoteSqlite(oldTableName)}',
        );
        for (final objectSql in schema.objectSql) {
          await transaction.execute(objectSql);
        }
        await _renameStagedSqliteColumns(
          transaction,
          oldTableName,
          oldColumns,
          newColumns,
        );
        if (oldTableName != newTableName) {
          await transaction.execute(
            'ALTER TABLE ${_quoteSqlite(oldTableName)} '
            'RENAME TO ${_quoteSqlite(newTableName)}',
          );
        }
      });
    } finally {
      try {
        if (foreignKeysEnabled) await db.execute('PRAGMA foreign_keys=ON');
      } finally {
        await db.close();
      }
    }
  }

  List<TableColumnDefinition> _stageSqliteColumns(
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) {
    final oldNames = oldColumns.map((column) => column.name).toSet();
    return newColumns.map((column) {
      final originalName = column.originalName;
      if (originalName == null || !oldNames.contains(originalName)) {
        return column;
      }
      return column.copyWith(name: originalName, originalName: originalName);
    }).toList();
  }

  Future<void> _renameStagedSqliteColumns(
    Transaction transaction,
    String tableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {
    final oldNames = oldColumns.map((column) => column.name).toSet();
    final renames = <String, String>{
      for (final column in newColumns)
        if (column.originalName != null &&
            oldNames.contains(column.originalName) &&
            column.originalName != column.name)
          column.originalName!: column.name,
    };
    if (renames.isEmpty) return;

    final temporaryNames = <String, String>{};
    var counter = 0;
    for (final source in renames.keys) {
      String temporaryName;
      do {
        temporaryName = '__querypod_rename_${counter++}';
      } while (oldNames.contains(temporaryName) ||
          renames.values.contains(temporaryName));
      temporaryNames[source] = temporaryName;
      await transaction.execute(
        'ALTER TABLE ${_quoteSqlite(tableName)} '
        'RENAME COLUMN ${_quoteSqlite(source)} '
        'TO ${_quoteSqlite(temporaryName)}',
      );
    }
    for (final entry in renames.entries) {
      await transaction.execute(
        'ALTER TABLE ${_quoteSqlite(tableName)} '
        'RENAME COLUMN ${_quoteSqlite(temporaryNames[entry.key]!)} '
        'TO ${_quoteSqlite(entry.value)}',
      );
    }
  }

  List<String> _buildSqliteDefinitions(List<TableColumnDefinition> columns) {
    _validateSqliteAutoIncrement(columns);
    final definitions = <String>[];
    final primaryKeys = <String>[];
    final autoIncrementColumn = columns
        .where((column) => column.isAutoIncrement)
        .firstOrNull;

    for (final column in columns) {
      var definition = '${_quoteSqlite(column.name)} ${column.type}';
      if (column.length != null) definition += '(${column.length})';
      if (identical(column, autoIncrementColumn)) {
        definition += ' PRIMARY KEY AUTOINCREMENT';
      } else if (column.isPrimaryKey) {
        primaryKeys.add(_quoteSqlite(column.name));
      }
      if (!column.isNullable && !column.isPrimaryKey) {
        definition += ' NOT NULL';
      }
      if (column.defaultValue != null && column.defaultValue!.isNotEmpty) {
        if (column.defaultValue!.toUpperCase() == 'CURRENT_TIMESTAMP') {
          definition += ' DEFAULT CURRENT_TIMESTAMP';
        } else {
          definition +=
              " DEFAULT '${column.defaultValue!.replaceAll("'", "''")}'";
        }
      }
      definitions.add(definition);
    }
    if (primaryKeys.isNotEmpty && autoIncrementColumn == null) {
      definitions.add('PRIMARY KEY (${primaryKeys.join(', ')})');
    }
    return definitions;
  }

  void _validateSqliteAutoIncrement(List<TableColumnDefinition> columns) {
    final autoIncrementColumns = columns
        .where((column) => column.isAutoIncrement)
        .toList();
    if (autoIncrementColumns.isEmpty) return;
    final column = autoIncrementColumns.singleOrNull;
    final primaryKeyCount = columns
        .where((candidate) => candidate.isPrimaryKey)
        .length;
    if (column == null ||
        !column.isPrimaryKey ||
        primaryKeyCount != 1 ||
        column.type.toUpperCase() != 'INTEGER') {
      throw ArgumentError(
        'SQLite AUTOINCREMENT requires one INTEGER PRIMARY KEY column.',
      );
    }
  }

  bool _canUseNativeSqliteAlter(
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) {
    final oldMap = {for (final column in oldColumns) column.name: column};
    final retained = <String>{};
    final oldNames = oldMap.keys.toSet();
    for (final newColumn in newColumns) {
      final originalName = newColumn.originalName;
      final oldColumn = originalName == null ? null : oldMap[originalName];
      if (oldColumn == null) {
        if (newColumn.isPrimaryKey ||
            newColumn.isAutoIncrement ||
            (!newColumn.isNullable &&
                (newColumn.defaultValue == null ||
                    newColumn.defaultValue!.isEmpty)) ||
            newColumn.defaultValue?.toUpperCase() == 'CURRENT_TIMESTAMP') {
          return false;
        }
        continue;
      }
      retained.add(oldColumn.name);
      if (!_sameSqliteColumnProperties(oldColumn, newColumn)) return false;
      if (newColumn.name != oldColumn.name &&
          oldNames.contains(newColumn.name)) {
        return false;
      }
    }
    return retained.length == oldColumns.length;
  }

  Future<void> _runNativeSqliteAlter(
    Database db,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {
    final oldMap = {for (final column in oldColumns) column.name: column};
    await db.transaction((transaction) async {
      for (final newColumn in newColumns) {
        final originalName = newColumn.originalName;
        final oldColumn = originalName == null ? null : oldMap[originalName];
        if (oldColumn == null) {
          final definition = _buildSqliteDefinitions([newColumn]).single;
          await transaction.execute(
            'ALTER TABLE ${_quoteSqlite(oldTableName)} '
            'ADD COLUMN $definition',
          );
        } else if (newColumn.name != oldColumn.name) {
          await transaction.execute(
            'ALTER TABLE ${_quoteSqlite(oldTableName)} '
            'RENAME COLUMN ${_quoteSqlite(oldColumn.name)} '
            'TO ${_quoteSqlite(newColumn.name)}',
          );
        }
      }
      if (oldTableName != newTableName) {
        await transaction.execute(
          'ALTER TABLE ${_quoteSqlite(oldTableName)} '
          'RENAME TO ${_quoteSqlite(newTableName)}',
        );
      }
    });
  }

  Future<_SqlitePreservedSchema> _readSqliteSchema(
    Database db,
    String tableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {
    final masterRows = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    final tableSql = masterRows.isEmpty
        ? ''
        : _asString(masterRows.first['sql']);
    final renameMap = <String, String>{
      for (final column in newColumns)
        if (column.originalName != null) column.originalName!: column.name,
    };
    final retained = renameMap.keys.toSet();
    final removed = oldColumns
        .map((column) => column.name)
        .where((name) => !retained.contains(name))
        .toSet();
    await _validateInboundSqliteForeignKeys(
      db,
      tableName,
      oldColumns,
      newColumns,
      removed,
    );

    final foreignKeyRows = await db.rawQuery(
      'PRAGMA foreign_key_list(${_quoteSqlite(tableName)})',
    );
    if (foreignKeyRows.isNotEmpty &&
        RegExp(r'\bDEFERRABLE\b', caseSensitive: false).hasMatch(tableSql)) {
      throw UnsupportedError(
        'SQLite cannot safely preserve DEFERRABLE foreign keys during this alteration.',
      );
    }
    final foreignKeyGroups = <int, List<Map<String, Object?>>>{};
    for (final row in foreignKeyRows) {
      (foreignKeyGroups[row['id'] as int] ??= []).add(row);
    }
    final foreignKeys = <String>[];
    for (final rows in foreignKeyGroups.values) {
      rows.sort(
        (left, right) => (left['seq'] as int).compareTo(right['seq'] as int),
      );
      final localColumns = <String>[];
      final targetColumns = <String>[];
      for (final row in rows) {
        final localName = _asString(row['from']);
        if (removed.contains(localName)) {
          throw UnsupportedError(
            'Cannot remove column "$localName" because a foreign key uses it.',
          );
        }
        localColumns.add(_quoteSqlite(renameMap[localName] ?? localName));
        final targetName = _asString(row['to']);
        if (targetName.isNotEmpty) {
          if (_asString(row['table']).toLowerCase() ==
                  tableName.toLowerCase() &&
              removed.contains(targetName)) {
            throw UnsupportedError(
              'Cannot remove column "$targetName" because a self-referencing '
              'foreign key uses it.',
            );
          }
          targetColumns.add(_quoteSqlite(targetName));
        }
      }
      final first = rows.first;
      var definition =
          'FOREIGN KEY (${localColumns.join(', ')}) REFERENCES '
          '${_quoteSqlite(_asString(first['table']))}';
      if (targetColumns.isNotEmpty) {
        definition += ' (${targetColumns.join(', ')})';
      }
      definition += ' ON UPDATE ${_asString(first['on_update'])}';
      definition += ' ON DELETE ${_asString(first['on_delete'])}';
      final match = _asString(first['match']);
      if (match.isNotEmpty && match.toUpperCase() != 'NONE') {
        definition += ' MATCH $match';
      }
      foreignKeys.add(definition);
    }

    final uniqueConstraints = <String>[];
    final indexRows = await db.rawQuery(
      'PRAGMA index_list(${_quoteSqlite(tableName)})',
    );
    for (final index in indexRows) {
      if (_asString(index['origin']) != 'u') continue;
      final indexName = _asString(index['name']);
      final columns = await db.rawQuery(
        'PRAGMA index_info(${_quoteSqlite(indexName)})',
      );
      final names = <String>[];
      for (final column in columns) {
        final name = _asString(column['name']);
        if (name.isEmpty || removed.contains(name)) {
          throw UnsupportedError(
            'Cannot safely preserve unique constraint "$indexName".',
          );
        }
        names.add(_quoteSqlite(renameMap[name] ?? name));
      }
      uniqueConstraints.add('UNIQUE (${names.join(', ')})');
    }

    final objectRows = await db.rawQuery(
      "SELECT type, name, sql FROM sqlite_master "
      "WHERE tbl_name=? AND type IN ('index', 'trigger') AND sql IS NOT NULL",
      [tableName],
    );
    final objectSql = objectRows.map((row) {
      final sql = _asString(row['sql']);
      return _rewriteSqliteIdentifiers(sql, renameMap, removed);
    }).toList();

    return _SqlitePreservedSchema(
      foreignKeys: foreignKeys,
      uniqueConstraints: uniqueConstraints,
      objectSql: objectSql,
      withoutRowId: RegExp(
        r'\bWITHOUT\s+ROWID\b',
        caseSensitive: false,
      ).hasMatch(tableSql),
      strict: RegExp(r'\bSTRICT\s*$', caseSensitive: false).hasMatch(tableSql),
    );
  }

  Future<void> _validateInboundSqliteForeignKeys(
    Database db,
    String tableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
    Set<String> removed,
  ) async {
    final oldPrimaryKey = oldColumns
        .where((column) => column.isPrimaryKey)
        .map((column) => column.name)
        .toList();
    final newPrimaryKey = newColumns
        .where((column) => column.isPrimaryKey)
        .map((column) => column.originalName ?? column.name)
        .toList();
    final primaryKeyChanged =
        oldPrimaryKey.length != newPrimaryKey.length ||
        Iterable.generate(
          oldPrimaryKey.length,
        ).any((index) => oldPrimaryKey[index] != newPrimaryKey[index]);
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    for (final table in tables) {
      final referencingTable = _asString(table['name']);
      if (referencingTable.toLowerCase() == tableName.toLowerCase()) continue;
      final rows = await db.rawQuery(
        'PRAGMA foreign_key_list(${_quoteSqlite(referencingTable)})',
      );
      final groups = <int, List<Map<String, Object?>>>{};
      for (final row in rows) {
        if (_asString(row['table']).toLowerCase() != tableName.toLowerCase()) {
          continue;
        }
        (groups[row['id'] as int] ??= []).add(row);
      }
      for (final entry in groups.entries) {
        entry.value.sort(
          (left, right) => (left['seq'] as int).compareTo(right['seq'] as int),
        );
        final targets = entry.value
            .map((row) => _asString(row['to']))
            .where((name) => name.isNotEmpty)
            .toList();
        final removedTarget = targets.where(removed.contains).firstOrNull;
        if (removedTarget != null) {
          throw UnsupportedError(
            'Cannot remove column "$removedTarget" because table '
            '"$referencingTable" references it.',
          );
        }
        final referencesPrimaryKey =
            targets.isEmpty ||
            (targets.length == oldPrimaryKey.length &&
                Iterable.generate(
                  targets.length,
                ).every((index) => targets[index] == oldPrimaryKey[index]));
        if (primaryKeyChanged && referencesPrimaryKey) {
          throw UnsupportedError(
            'Cannot change this primary key because table '
            '"$referencingTable" references it.',
          );
        }
      }
    }
  }

  @override
  Future<void> dropTable(
    Connection connection,
    String database,
    String table, {
    bool cascade = false,
  }) async {
    final db = await _connect(connection);
    try {
      if (cascade) {
        await db.execute('PRAGMA foreign_keys = OFF');
      }
      await db.execute('DROP TABLE ${_quoteIdentifier(table)}');
    } finally {
      if (cascade) {
        await db.execute('PRAGMA foreign_keys = ON');
      }
      await db.close();
    }
  }

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String table, {
    bool cascade = false,
  }) async {
    final db = await _connect(connection);
    try {
      if (cascade) {
        await db.execute('PRAGMA foreign_keys = OFF');
      }
      // SQLite does not support TRUNCATE TABLE, so we use DELETE FROM
      await db.execute('DELETE FROM ${_quoteIdentifier(table)}');
    } finally {
      if (cascade) {
        await db.execute('PRAGMA foreign_keys = ON');
      }
      await db.close();
    }
  }
}

class _SqlitePreservedSchema {
  final List<String> foreignKeys;
  final List<String> uniqueConstraints;
  final List<String> objectSql;
  final bool withoutRowId;
  final bool strict;

  const _SqlitePreservedSchema({
    required this.foreignKeys,
    required this.uniqueConstraints,
    required this.objectSql,
    required this.withoutRowId,
    required this.strict,
  });
}

String _quoteSqlite(String value) => '"${value.replaceAll('"', '""')}"';

bool _sameSqliteColumnProperties(
  TableColumnDefinition oldColumn,
  TableColumnDefinition newColumn,
) =>
    oldColumn.type == newColumn.type &&
    oldColumn.length == newColumn.length &&
    oldColumn.isPrimaryKey == newColumn.isPrimaryKey &&
    oldColumn.isNullable == newColumn.isNullable &&
    oldColumn.isAutoIncrement == newColumn.isAutoIncrement &&
    oldColumn.defaultValue == newColumn.defaultValue;

String _rewriteSqliteIdentifiers(
  String sql,
  Map<String, String> renameMap,
  Set<String> removed,
) {
  final output = StringBuffer();
  var index = 0;
  while (index < sql.length) {
    final character = sql[index];
    if (character == "'") {
      final end = _copySqlQuoted(sql, index, "'", output);
      index = end;
      continue;
    }
    if (character == '"' || character == '`') {
      final end = _findSqlQuoteEnd(sql, index, character);
      final value = sql
          .substring(index + 1, end - 1)
          .replaceAll('$character$character', character);
      final replacement = _mappedSqliteIdentifier(value, renameMap, removed);
      output.write(character);
      output.write(replacement.replaceAll(character, '$character$character'));
      output.write(character);
      index = end;
      continue;
    }
    if (character == '[') {
      final end = sql.indexOf(']', index + 1);
      if (end == -1) throw const FormatException('Unterminated SQL identifier');
      final value = sql.substring(index + 1, end);
      output.write('[${_mappedSqliteIdentifier(value, renameMap, removed)}]');
      index = end + 1;
      continue;
    }
    if (RegExp(r'[A-Za-z_]').hasMatch(character)) {
      var end = index + 1;
      while (end < sql.length && RegExp(r'[A-Za-z0-9_$]').hasMatch(sql[end])) {
        end++;
      }
      final value = sql.substring(index, end);
      output.write(_mappedSqliteIdentifier(value, renameMap, removed));
      index = end;
      continue;
    }
    output.write(character);
    index++;
  }
  return output.toString();
}

int _copySqlQuoted(String sql, int start, String quote, StringBuffer output) {
  final end = _findSqlQuoteEnd(sql, start, quote);
  output.write(sql.substring(start, end));
  return end;
}

int _findSqlQuoteEnd(String sql, int start, String quote) {
  var index = start + 1;
  while (index < sql.length) {
    if (sql[index] == quote) {
      if (index + 1 < sql.length && sql[index + 1] == quote) {
        index += 2;
        continue;
      }
      return index + 1;
    }
    index++;
  }
  throw const FormatException('Unterminated SQL quoted value');
}

String _mappedSqliteIdentifier(
  String value,
  Map<String, String> renameMap,
  Set<String> removed,
) {
  String? renamed;
  for (final entry in renameMap.entries) {
    if (entry.key.toLowerCase() == value.toLowerCase()) {
      renamed = entry.value;
      break;
    }
  }
  if (renamed != null) return renamed;
  if (removed.any((name) => name.toLowerCase() == value.toLowerCase())) {
    throw UnsupportedError(
      'Cannot remove column "$value" because an index or trigger uses it.',
    );
  }
  return value;
}
