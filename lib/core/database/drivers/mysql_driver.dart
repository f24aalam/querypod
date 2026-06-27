import 'dart:convert';
import 'dart:typed_data';

import 'package:mysql_client_plus/exception.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../features/connections/domain/entities/connection.dart';
import '../../../features/workspace/domain/entities/query_history.dart';
import '../../../features/workspace/domain/entities/query_result.dart';
import '../../../features/workspace/domain/entities/table_data.dart';
import '../../../features/workspace/domain/entities/workspace_database.dart';
import '../../../features/workspace/domain/entities/workspace_table.dart';
import '../database_driver.dart';
import 'alter_table_sql.dart';

class MySQLDriver implements DatabaseDriver {
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

  String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Uint8List) return utf8.decode(value, allowMalformed: true);
    return value.toString();
  }

  Future<MySQLConnection> _connect(
    Connection connection, {
    String? database,
  }) async {
    final conn = await MySQLConnection.createConnection(
      host: connection.host,
      port: connection.port,
      userName: connection.user,
      password: connection.password,
      databaseName: (database ?? connection.database).isEmpty
          ? null
          : (database ?? connection.database),
      secure: false,
    );
    await conn.connect();
    return conn;
  }

  @override
  Future<void> testConnection(Connection connection) async {
    try {
      final conn = await _connect(connection);
      await conn.execute('SELECT 1');
      await conn.close();
    } catch (e) {
      if (e is MySQLException) {
        final base = e.message.isNotEmpty
            ? e.message
            : 'MySQL client returned an error';
        throw Exception('Failed to connect: $base');
      }

      final message = e.toString();
      final localhostHint =
          (connection.host == '127.0.0.1' || connection.host == 'localhost') &&
          (message.contains('Connection refused') ||
              message.contains('No route to host') ||
              message.contains('OS Error'));

      if (localhostHint) {
        throw Exception(
          'Failed to connect: $message. If this app is running on a simulator/device, 127.0.0.1 points to the device, not your computer.',
        );
      }

      throw Exception('Failed to connect: $message');
    }
  }

  @override
  Future<List<WorkspaceDatabase>> listDatabases(Connection connection) async {
    final conn = await _connect(connection);
    try {
      final results = await conn.execute('SHOW DATABASES');
      return results.rows
          .map(
            (row) =>
                WorkspaceDatabase(name: _asString(row.colByName('Database'))),
          )
          .where((db) => db.name.isNotEmpty)
          .toList();
    } finally {
      await conn.close();
    }
  }

  @override
  Future<List<WorkspaceTable>> listTables(
    Connection connection,
    String database,
  ) async {
    final conn = await _connect(connection, database: database);
    try {
      final results = await conn.execute('SHOW FULL TABLES FROM `$database`');

      return results.rows
          .map((row) {
            final values = row.assoc();
            final tableName = values.entries
                .firstWhere(
                  (entry) => entry.key.startsWith('Tables_in_'),
                  orElse: () => const MapEntry('', null),
                )
                .value;
            final tableType =
                _asString(row.colByName('Table_type')).toUpperCase() == 'VIEW'
                ? WorkspaceTableType.view
                : WorkspaceTableType.table;

            return WorkspaceTable(name: _asString(tableName), type: tableType);
          })
          .where((table) => table.name.isNotEmpty)
          .toList();
    } finally {
      await conn.close();
    }
  }

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table, {
    void Function(QueryHistory)? onHistory,
  }) async {
    final conn = await _connect(connection, database: database);
    try {
      final quotedDatabase = _quoteIdentifier(database);
      final quotedTable = _quoteIdentifier(table);
      final sql = 'SHOW COLUMNS FROM $quotedDatabase.$quotedTable';
      final startMs = DateTime.now().millisecondsSinceEpoch;
      final schema = await conn.execute(sql);
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

      final primaryKeys = <String>{};
      final types = <String, String>{};
      final nullables = <String>{};

      for (final row in schema.rows) {
        final name = _asString(row.colByName('Field'));
        types[name] = _asString(row.colByName('Type'));
        if (_asString(row.colByName('Key')).toUpperCase() == 'PRI') {
          primaryKeys.add(name);
        }
        if (_asString(row.colByName('Null')).toUpperCase() == 'YES') {
          nullables.add(name);
        }
      }

      final fkSql = '''
        SELECT
          COLUMN_NAME,
          REFERENCED_TABLE_NAME,
          REFERENCED_COLUMN_NAME
        FROM
          INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE
          TABLE_SCHEMA = :db
          AND TABLE_NAME = :table
          AND REFERENCED_TABLE_NAME IS NOT NULL
      ''';
      final startFkMs = DateTime.now().millisecondsSinceEpoch;
      final fkSchema = await conn.execute(fkSql, {
        'db': database,
        'table': table,
      });
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
      for (final row in fkSchema.rows) {
        final colName = _asString(row.colByName('COLUMN_NAME'));
        fks[colName] = TableForeignKey(
          targetTable: _asString(row.colByName('REFERENCED_TABLE_NAME')),
          targetColumn: _asString(row.colByName('REFERENCED_COLUMN_NAME')),
        );
      }

      final sampleSql = 'SELECT * FROM $quotedDatabase.$quotedTable LIMIT 0';
      final startSampleMs = DateTime.now().millisecondsSinceEpoch;
      final sample = await conn.execute(sampleSql);
      final execSampleMs =
          DateTime.now().millisecondsSinceEpoch - startSampleMs;

      onHistory?.call(
        QueryHistory(
          id: const Uuid().v4(),
          connectionId: connection.id,
          sourceType: 'table',
          sourceId: table,
          sql: sampleSql,
          executionTimeMs: execSampleMs,
          status: 'success',
          createdAt: DateTime.now(),
        ),
      );

      final columns = sample.cols
          .map(
            (column) => TableDataColumn(
              name: column.name,
              databaseType: types[column.name] ?? column.type.intVal.toString(),
              length: column.length,
              isPrimaryKey: primaryKeys.contains(column.name),
              isNullable: nullables.contains(column.name),
              foreignKey: fks[column.name],
            ),
          )
          .toList();

      final idxSql = '''
        SELECT INDEX_NAME, NON_UNIQUE, COLUMN_NAME 
        FROM INFORMATION_SCHEMA.STATISTICS 
        WHERE TABLE_SCHEMA = :db AND TABLE_NAME = :table
        ORDER BY SEQ_IN_INDEX;
      ''';
      final startIdxMs = DateTime.now().millisecondsSinceEpoch;
      final idxSchema = await conn.execute(idxSql, {
        'db': database,
        'table': table,
      });
      final execIdxMs = DateTime.now().millisecondsSinceEpoch - startIdxMs;

      onHistory?.call(
        QueryHistory(
          id: const Uuid().v4(),
          connectionId: connection.id,
          sourceType: 'table',
          sourceId: table,
          sql: idxSql,
          executionTimeMs: execIdxMs,
          status: 'success',
          createdAt: DateTime.now(),
        ),
      );

      final indexesMap = <String, TableIndex>{};
      for (final row in idxSchema.rows) {
        final indexName = _asString(row.colByName('INDEX_NAME'));
        final isUnique = _asString(row.colByName('NON_UNIQUE')) == '0';
        final colName = _asString(row.colByName('COLUMN_NAME'));

        if (indexesMap.containsKey(indexName)) {
          indexesMap[indexName]!.columns.add(colName);
        } else {
          indexesMap[indexName] = TableIndex(
            name: indexName,
            columns: [colName],
            isUnique: isUnique,
            isPrimaryKey: indexName.toUpperCase() == 'PRIMARY',
          );
        }
      }
      final indexes = indexesMap.values.toList();

      if (columns.isEmpty) {
        throw StateError('The table does not expose any columns');
      }
      final orderColumn = columns
          .firstWhere(
            (column) => column.isPrimaryKey,
            orElse: () => columns.first,
          )
          .name;
      return TableStructure(
        columns: columns,
        indexes: indexes,
        orderColumn: orderColumn,
      );
    } finally {
      await conn.close();
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
    final conn = await _connect(connection, database: database);
    try {
      var sql =
          'SELECT COUNT(*) AS total FROM '
          '${_quoteIdentifier(database)}.${_quoteIdentifier(table)}';

      final queryParams = <String, dynamic>{};
      final whereClauses = <String>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchClauses = <String>[];
        for (int i = 0; i < structure.columns.length; i++) {
          searchClauses.add(
            '${_quoteIdentifier(structure.columns[i].name)} LIKE :search$i',
          );
          queryParams['search$i'] = '%$searchQuery%';
        }
        whereClauses.add('(${searchClauses.join(' OR ')})');
      }

      if (filters != null && filters.isNotEmpty) {
        for (int i = 0; i < filters.length; i++) {
          final filter = filters[i];
          whereClauses.add(
            '${_quoteIdentifier(filter.column)} ${filter.operator} :filter$i',
          );
          queryParams['filter$i'] = filter.value;
        }
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }
      final startMs = DateTime.now().millisecondsSinceEpoch;
      final result = await conn.execute(sql, queryParams);
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

      final value = result.rows.first.colByName('total');
      return int.tryParse(_asString(value)) ?? 0;
    } finally {
      await conn.close();
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
    final conn = await _connect(connection, database: database);
    final stopwatch = Stopwatch()..start();
    try {
      var sql =
          'SELECT * FROM ${_quoteIdentifier(database)}.${_quoteIdentifier(table)}';

      final queryParams = <String, dynamic>{};
      final whereClauses = <String>[];

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchClauses = <String>[];
        for (int i = 0; i < structure.columns.length; i++) {
          searchClauses.add(
            '${_quoteIdentifier(structure.columns[i].name)} LIKE :search$i',
          );
          queryParams['search$i'] = '%$searchQuery%';
        }
        whereClauses.add('(${searchClauses.join(' OR ')})');
      }

      if (filters != null && filters.isNotEmpty) {
        for (int i = 0; i < filters.length; i++) {
          final filter = filters[i];
          whereClauses.add(
            '${_quoteIdentifier(filter.column)} ${filter.operator} :filter$i',
          );
          queryParams['filter$i'] = filter.value;
        }
      }

      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }

      sql +=
          ' ORDER BY ${_quoteIdentifier(structure.orderColumn)} ASC '
          'LIMIT $limit OFFSET $offset';

      final startMs = DateTime.now().millisecondsSinceEpoch;
      final result = await conn.execute(sql, queryParams);
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

      final rows = result.rows
          .map(
            (row) => TableDataRow([
              for (var index = 0; index < structure.columns.length; index++)
                _cell(row.colAt(index), structure.columns[index]),
            ]),
          )
          .toList();
      stopwatch.stop();
      return TableRowsPage(rows: rows, queryDuration: stopwatch.elapsed);
    } finally {
      stopwatch.stop();
      await conn.close();
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
    void Function(QueryHistory)? onHistory,
  }) async {
    final primaryKeyIndexes = <int>[
      for (var index = 0; index < structure.columns.length; index++)
        if (structure.columns[index].isPrimaryKey) index,
    ];
    if (primaryKeyIndexes.isEmpty) {
      throw StateError('This table has no primary key and is read-only');
    }

    final conn = await _connect(connection, database: database);
    try {
      await conn.transactional((txn) async {
        for (final change in cellChanges) {
          await _executeUpdate(
            connection.id,
            txn,
            database,
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
            database,
            table,
            structure,
            primaryKeyIndexes,
            row,
            onHistory,
          );
        }
      });
    } finally {
      await conn.close();
    }
  }

  Future<void> _executeUpdate(
    String connectionId,
    MySQLConnection conn,
    String database,
    String table,
    TableStructure structure,
    List<int> primaryKeyIndexes,
    TableCellChange change,
    void Function(QueryHistory)? onHistory,
  ) async {
    final column = structure.columns[change.columnIndex];
    final where = _primaryKeyWhere(structure, primaryKeyIndexes);
    final sql =
        'UPDATE ${_quoteIdentifier(database)}.${_quoteIdentifier(table)} '
        'SET ${_quoteIdentifier(column.name)} = ? WHERE $where LIMIT 1';
    final statement = await conn.prepare(sql);
    try {
      final updatedValue =
          change.row.cells[change.columnIndex].kind == TableCellKind.binary
          ? _decodeHex(change.value)
          : change.value;
      final startMs = DateTime.now().millisecondsSinceEpoch;
      await statement.execute([
        updatedValue,
        for (final index in primaryKeyIndexes) change.row.cells[index].rawValue,
      ]);
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
    } finally {
      await statement.deallocate();
    }
  }

  Future<void> _executeDelete(
    String connectionId,
    MySQLConnection conn,
    String database,
    String table,
    TableStructure structure,
    List<int> primaryKeyIndexes,
    TableDataRow row,
    void Function(QueryHistory)? onHistory,
  ) async {
    final where = _primaryKeyWhere(structure, primaryKeyIndexes);
    final sql =
        'DELETE FROM ${_quoteIdentifier(database)}.${_quoteIdentifier(table)} '
        'WHERE $where LIMIT 1';
    final statement = await conn.prepare(sql);
    try {
      final startMs = DateTime.now().millisecondsSinceEpoch;
      await statement.execute([
        for (final index in primaryKeyIndexes) row.cells[index].rawValue,
      ]);
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
    } finally {
      await statement.deallocate();
    }
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

  String _quoteIdentifier(String value) => '`${value.replaceAll('`', '``')}`';

  TableCellValue _cell(dynamic value, TableDataColumn column) {
    if (value == null) return const TableCellValue.nullValue();
    if (value is Uint8List) {
      if (_isBinaryColumn(column.databaseType)) {
        return TableCellValue.binary(value);
      }
      try {
        return TableCellValue.text(utf8.decode(value));
      } on FormatException {
        return TableCellValue.binary(value);
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
    return type.contains('binary') ||
        type.contains('blob') ||
        type.contains('geometry');
  }

  @override
  Future<List<QueryResult>> executeQuery(
    Connection connection,
    String database,
    String sql,
  ) async {
    MySQLConnection? conn;
    try {
      conn = await _connect(connection, database: database);

      // Split into individual statements and execute one at a time.
      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final results = <QueryResult>[];

      for (final statement in statements) {
        final stmtWatch = Stopwatch()..start();
        try {
          final resultSet = await conn.execute(statement);
          stmtWatch.stop();

          final columns = resultSet.cols
              .map(
                (col) => TableDataColumn(
                  name: col.name,
                  databaseType: col.type.intVal.toString(),
                  length: col.length,
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

          final rows = resultSet.rows
              .map(
                (row) => TableDataRow([
                  for (var index = 0; index < columns.length; index++)
                    _cell(row.colAt(index), columns[index]),
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
      // Connection-level failure (e.g. bad credentials).
      return [QueryResult(errorMessage: e.toString(), rows: const [])];
    } finally {
      await conn?.close();
    }
  }

  @override
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {
    final conn = await _connect(connection, database: '');
    try {
      var sql = 'CREATE DATABASE `${name.replaceAll('`', '``')}`';
      if (charset != null && charset.isNotEmpty) {
        sql += ' CHARACTER SET $charset';
      }
      if (collation != null && collation.isNotEmpty) {
        sql += ' COLLATE $collation';
      }
      await conn.execute(sql);
    } finally {
      await conn.close();
    }
  }

  @override
  Future<void> createTable(
    Connection connection,
    String database,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {
    final conn = await _connect(connection, database: database);
    try {
      final columnDefs = <String>[];
      final primaryKeys = <String>[];

      for (final col in columns) {
        var def = '`${col.name.replaceAll('`', '``')}` ${col.type}';

        if (col.length != null) {
          def += '(${col.length})';
        }

        if (!col.isNullable) {
          def += ' NOT NULL';
        }

        if (col.isAutoIncrement) {
          def += ' AUTO_INCREMENT';
        }

        if (col.defaultValue != null && col.defaultValue!.isNotEmpty) {
          // A bit simplistic for string defaults vs numeric defaults
          // Ideally we would inspect the type, but standard SQL usually needs quotes for strings
          // For simplicity, assuming default values are appropriately formatted by the user
          // Or we quote them. Let's just pass it as is, or maybe wrap in single quotes if it's not a function like CURRENT_TIMESTAMP
          if (col.defaultValue!.toUpperCase() == 'CURRENT_TIMESTAMP') {
            def += ' DEFAULT CURRENT_TIMESTAMP';
          } else {
            def += " DEFAULT '${col.defaultValue!.replaceAll("'", "''")}'";
          }
        }

        if (col.isPrimaryKey) {
          primaryKeys.add('`${col.name.replaceAll('`', '``')}`');
        }

        columnDefs.add(def);
      }

      if (primaryKeys.isNotEmpty) {
        columnDefs.add('PRIMARY KEY (${primaryKeys.join(', ')})');
      }

      final sql =
          'CREATE TABLE `${tableName.replaceAll('`', '``')}` (\n  ${columnDefs.join(',\n  ')}\n)';
      await conn.execute(sql);
    } finally {
      await conn.close();
    }
  }

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String table,
  ) async {
    final conn = await _connect(connection, database: database);
    try {
      final quotedDatabase = _quoteIdentifier(database);
      final quotedTable = _quoteIdentifier(table);
      final schema = await conn.execute(
        'SHOW COLUMNS FROM $quotedDatabase.$quotedTable',
      );

      final columns = <TableColumnDefinition>[];
      for (final row in schema.rows) {
        final name = _asString(row.colByName('Field'));
        var typeRaw = _asString(row.colByName('Type'));
        final isNullable =
            _asString(row.colByName('Null')).toUpperCase() == 'YES';
        final isPk = _asString(row.colByName('Key')).toUpperCase() == 'PRI';
        final defaultValue = _asString(row.colByName('Default'));
        final extra = _asString(row.colByName('Extra')).toUpperCase();

        final isAutoIncrement = extra.contains('AUTO_INCREMENT');

        int? length;
        var type = typeRaw;

        final lengthMatch = RegExp(r'\((\d+)\)').firstMatch(typeRaw);
        if (lengthMatch != null) {
          length = int.tryParse(lengthMatch.group(1)!);
          type = typeRaw.replaceAll(lengthMatch.group(0)!, '');
        }

        type = type.split(' ')[0].toUpperCase();

        columns.add(
          TableColumnDefinition(
            name: name,
            originalName: name,
            type: type,
            length: length,
            isPrimaryKey: isPk,
            isNullable: isNullable,
            isAutoIncrement: isAutoIncrement,
            defaultValue: defaultValue.isNotEmpty ? defaultValue : null,
          ),
        );
      }
      return columns;
    } finally {
      await conn.close();
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
    final conn = await _connect(connection, database: database);
    try {
      final statements = buildMySqlAlterStatements(
        oldTableName: oldTableName,
        newTableName: newTableName,
        oldColumns: oldColumns,
        newColumns: newColumns,
      );
      for (final statement in statements) {
        await conn.execute(statement);
      }
    } finally {
      await conn.close();
    }
  }
}
