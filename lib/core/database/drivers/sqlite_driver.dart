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
  List<String> get supportedOperators => ['=', '!=', '>', '<', '>=', '<=', 'LIKE', 'NOT LIKE'];

  Future<Database> _connect(Connection connection) async {
    // For SQLite, the 'database' field stores the file path
    final path = connection.database;
    if (path.isEmpty) {
      throw Exception('Database file path is required for SQLite');
    }
    return await databaseFactoryFfi.openDatabase(path);
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
            final tableType =
                _asString(row['type']).toUpperCase() == 'VIEW'
                ? WorkspaceTableType.view
                : WorkspaceTableType.table;

            return WorkspaceTable(name: tableName, type: tableType);
          })
          .where((table) => table.name.isNotEmpty && table.name != 'sqlite_sequence')
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
          indexes.add(TableIndex(
            name: indexName,
            columns: indexCols,
            isUnique: isUnique,
            isPrimaryKey: origin == 'pk',
          ));
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
        final searchClauses = structure.columns.map((col) => '${_quoteIdentifier(col.name)} LIKE ?').join(' OR ');
        whereClauses.add('($searchClauses)');
        queryParams.addAll(List.filled(structure.columns.length, '%$searchQuery%'));
      }
      
      if (filters != null && filters.isNotEmpty) {
        for (final filter in filters) {
          whereClauses.add('${_quoteIdentifier(filter.column)} ${filter.operator} ?');
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
        final searchClauses = structure.columns.map((col) => '${_quoteIdentifier(col.name)} LIKE ?').join(' OR ');
        whereClauses.add('($searchClauses)');
        queryParams.addAll(List.filled(structure.columns.length, '%$searchQuery%'));
      }
      
      if (filters != null && filters.isNotEmpty) {
        for (final filter in filters) {
          whereClauses.add('${_quoteIdentifier(filter.column)} ${filter.operator} ?');
          queryParams.add(filter.value);
        }
      }
      
      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }
      
      sql += ' ORDER BY ${_quoteIdentifier(structure.orderColumn)} ASC '
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
          for (var col in structure.columns) _cell(row[col.name], col)
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
      });
    } finally {
      await db.close();
    }
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
        .map((index) => '${_quoteIdentifier(structure.columns[index].name)} = ?')
        .join(' AND ');
  }

  String _quoteIdentifier(String value) => '"${value.replaceAll('"', '""')}"';

  TableCellValue _cell(dynamic value, TableDataColumn column) {
    if (value == null) return const TableCellValue.nullValue();
    if (value is Uint8List || value is List<int>) {
      final bytes = value is Uint8List ? value : Uint8List.fromList(value as List<int>);
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
          final isSelect = statement.toUpperCase().startsWith('SELECT') || statement.toUpperCase().startsWith('PRAGMA');
          
          List<Map<String, Object?>> resultSet;
          if (isSelect) {
            resultSet = await db.rawQuery(statement);
          } else {
            final changes = await db.rawUpdate(statement);
            resultSet = [{'affected_rows': changes}];
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
                  databaseType: 'TEXT', // SQLite returns dynamic types, we just assume TEXT for display mostly
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
    throw UnsupportedError('SQLite does not support creating multiple databases');
  }
}
