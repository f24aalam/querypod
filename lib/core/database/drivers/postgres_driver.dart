import 'dart:convert';
import 'dart:typed_data';

import 'package:postgres/postgres.dart' as pg;
import 'package:uuid/uuid.dart';

import '../../../features/connections/domain/entities/connection.dart';
import '../../../features/workspace/domain/entities/query_history.dart';
import '../../../features/workspace/domain/entities/query_result.dart';
import '../../../features/workspace/domain/entities/table_data.dart';
import '../../../features/workspace/domain/entities/workspace_database.dart';
import '../../../features/workspace/domain/entities/workspace_table.dart';
import '../database_driver.dart';

class PostgresDriver implements DatabaseDriver {
  @override
  List<String> get supportedOperators => ['=', '!=', '>', '<', '>=', '<=', 'ILIKE', 'NOT ILIKE', 'LIKE', 'NOT LIKE'];

  String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is List<int>) return utf8.decode(value, allowMalformed: true);
    return value.toString();
  }

  Future<pg.Connection> _connect(
    covariant Connection connection, {
    String? database,
  }) async {
    final dbName = (database ?? connection.database);
    final endpoint = pg.Endpoint(
      host: connection.host,
      port: connection.port,
      database: dbName.isEmpty ? 'postgres' : dbName,
      username: connection.user.isEmpty ? null : connection.user,
      password: connection.password.isEmpty ? null : connection.password,
    );

    return await pg.Connection.open(
      endpoint,
      settings: const pg.ConnectionSettings(sslMode: pg.SslMode.disable),
    );
  }

  @override
  Future<void> testConnection(covariant Connection connection) async {
    try {
      final conn = await _connect(connection);
      await conn.execute('SELECT 1');
      await conn.close();
    } catch (e) {
      if (e is pg.ServerException) {
        final base = e.message.isNotEmpty ? e.message : 'PostgreSQL client returned an error';
        throw Exception('Failed to connect: $base');
      }

      final message = e.toString();
      final localhostHint =
          (connection.host == '127.0.0.1' || connection.host == 'localhost') &&
          (message.contains('Connection refused') ||
              message.contains('No route to host') ||
              message.contains('OS Error'));

      if (localhostHint) {
        throw Exception('Failed to connect: $message. If this app is running on a simulator/device, 127.0.0.1 points to the device, not your computer.');
      }

      throw Exception('Failed to connect: $message');
    }
  }

  @override
  Future<List<WorkspaceDatabase>> listDatabases(covariant Connection connection) async {
    final conn = await _connect(connection);
    try {
      final results = await conn.execute(
        'SELECT datname FROM pg_database WHERE datistemplate = false;'
      );
      return results
          .map((row) => WorkspaceDatabase(name: _asString(row[0])))
          .where((db) => db.name.isNotEmpty)
          .toList();
    } finally {
      await conn.close();
    }
  }

  @override
  Future<List<WorkspaceTable>> listTables(
    covariant Connection connection,
    String database,
  ) async {
    final conn = await _connect(connection, database: database);
    try {
      final results = await conn.execute(
        "SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = 'public';"
      );

      return results
          .map((row) {
            final tableName = row[0];
            final tableType =
                _asString(row[1]).toUpperCase() == 'VIEW'
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
    covariant Connection connection,
    String database,
    String table, {
    void Function(QueryHistory)? onHistory,
  }) async {
    final conn = await _connect(connection, database: database);
    try {
      final quotedTable = _quoteIdentifier(table);
      final sql = "SELECT column_name, data_type, character_maximum_length FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '$table' ORDER BY ordinal_position;";
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

      final pkeySql = '''
        SELECT a.attname
        FROM pg_index i
        JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
        WHERE i.indrelid = '$quotedTable'::regclass AND i.indisprimary;
      ''';
      
      final pkeyResults = await conn.execute(pkeySql);
      final primaryKeys = pkeyResults.map((row) => _asString(row[0])).toSet();

      final types = <String, String>{};
      final lengths = <String, int?>{};

      for (final row in schema) {
        final name = _asString(row[0]);
        types[name] = _asString(row[1]);
        lengths[name] = row[2] != null ? int.tryParse(row[2].toString()) : null;
      }

      final columns = schema
          .map(
            (row) {
              final name = _asString(row[0]);
              return TableDataColumn(
                name: name,
                databaseType: types[name] ?? 'text',
                length: lengths[name] ?? 0,
                isPrimaryKey: primaryKeys.contains(name),
              );
            }
          )
          .toList();

      if (columns.isEmpty) {
        throw StateError('The table does not expose any columns');
      }
      final orderColumn = columns
          .firstWhere(
            (column) => column.isPrimaryKey,
            orElse: () => columns.first,
          )
          .name;
      return TableStructure(columns: columns, orderColumn: orderColumn);
    } finally {
      await conn.close();
    }
  }

  @override
  Future<int> countRows(
    covariant Connection connection,
    String database,
    String table, {
    required TableStructure structure,
    String? searchQuery,
    List<TableFilter>? filters,
    void Function(QueryHistory)? onHistory,
  }) async {
    final conn = await _connect(connection, database: database);
    try {
      var sql = 'SELECT COUNT(*) AS total FROM ${_quoteIdentifier(table)}';
      
      final parameters = <String, dynamic>{};
      final whereClauses = <String>[];
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchClauses = structure.columns.map((col) => 'CAST(${_quoteIdentifier(col.name)} AS TEXT) ILIKE @search').join(' OR ');
        whereClauses.add('($searchClauses)');
        parameters['search'] = '%$searchQuery%';
      }
      
      if (filters != null && filters.isNotEmpty) {
        for (int i = 0; i < filters.length; i++) {
          final filter = filters[i];
          whereClauses.add('${_quoteIdentifier(filter.column)} ${filter.operator} @filter$i');
          parameters['filter$i'] = filter.value;
        }
      }
      
      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }
      
      final startMs = DateTime.now().millisecondsSinceEpoch;
      final result = await conn.execute(pg.Sql.named(sql), parameters: parameters);
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

      final value = result.first[0];
      return int.tryParse(_asString(value)) ?? 0;
    } finally {
      await conn.close();
    }
  }

  @override
  Future<TableRowsPage> fetchRows(
    covariant Connection connection,
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
      var sql = 'SELECT * FROM ${_quoteIdentifier(table)}';
      
      final parameters = <String, dynamic>{};
      final whereClauses = <String>[];
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchClauses = structure.columns.map((col) => 'CAST(${_quoteIdentifier(col.name)} AS TEXT) ILIKE @search').join(' OR ');
        whereClauses.add('($searchClauses)');
        parameters['search'] = '%$searchQuery%';
      }
      
      if (filters != null && filters.isNotEmpty) {
        for (int i = 0; i < filters.length; i++) {
          final filter = filters[i];
          whereClauses.add('${_quoteIdentifier(filter.column)} ${filter.operator} @filter$i');
          parameters['filter$i'] = filter.value;
        }
      }
      
      if (whereClauses.isNotEmpty) {
        sql += ' WHERE ${whereClauses.join(' AND ')}';
      }
      
      sql += ' ORDER BY ${_quoteIdentifier(structure.orderColumn)} ASC '
          'LIMIT $limit OFFSET $offset';
      final startMs = DateTime.now().millisecondsSinceEpoch;
      final result = await conn.execute(pg.Sql.named(sql), parameters: parameters);
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

      final rows = result
          .map(
            (row) => TableDataRow([
              for (var index = 0; index < structure.columns.length; index++)
                _cell(row[index], structure.columns[index]),
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
    covariant Connection connection,
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
      await conn.runTx((txn) async {
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
    pg.TxSession txn,
    String database,
    String table,
    TableStructure structure,
    List<int> primaryKeyIndexes,
    TableCellChange change,
    void Function(QueryHistory)? onHistory,
  ) async {
    final column = structure.columns[change.columnIndex];
    final setClause = '${_quoteIdentifier(column.name)} = @p';
    
    final whereClauses = <String>[];
    for (int i = 0; i < primaryKeyIndexes.length; i++) {
        whereClauses.add('${_quoteIdentifier(structure.columns[primaryKeyIndexes[i]].name)} = @pk$i');
    }
    final where = whereClauses.join(' AND ');
    
    final sql =
        'UPDATE ${_quoteIdentifier(table)} '
        'SET $setClause WHERE $where';
        
    final updatedValue =
        change.row.cells[change.columnIndex].kind == TableCellKind.binary
        ? _decodeHex(change.value)
        : change.value;
        
    final parameters = <String, dynamic>{
      'p': updatedValue,
    };
    for (int i = 0; i < primaryKeyIndexes.length; i++) {
      parameters['pk$i'] = change.row.cells[primaryKeyIndexes[i]].rawValue;
    }
    
    final startMs = DateTime.now().millisecondsSinceEpoch;
    await txn.execute(pg.Sql.named(sql), parameters: parameters);
    final execMs = DateTime.now().millisecondsSinceEpoch - startMs;

    onHistory?.call(
      QueryHistory(
        id: const Uuid().v4(),
        connectionId: connectionId,
        sourceType: 'table',
        sourceId: table,
        sql: sql, // Ideally with parameters formatted but this is fine
        executionTimeMs: execMs,
        status: 'success',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _executeDelete(
    String connectionId,
    pg.TxSession txn,
    String database,
    String table,
    TableStructure structure,
    List<int> primaryKeyIndexes,
    TableDataRow row,
    void Function(QueryHistory)? onHistory,
  ) async {
    final whereClauses = <String>[];
    for (int i = 0; i < primaryKeyIndexes.length; i++) {
        whereClauses.add('${_quoteIdentifier(structure.columns[primaryKeyIndexes[i]].name)} = @pk$i');
    }
    final where = whereClauses.join(' AND ');
    
    final sql =
        'DELETE FROM ${_quoteIdentifier(table)} '
        'WHERE $where';
        
    final parameters = <String, dynamic>{};
    for (int i = 0; i < primaryKeyIndexes.length; i++) {
      parameters['pk$i'] = row.cells[primaryKeyIndexes[i]].rawValue;
    }
    
    final startMs = DateTime.now().millisecondsSinceEpoch;
    await txn.execute(pg.Sql.named(sql), parameters: parameters);
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

  String _quoteIdentifier(String value) => '"${value.replaceAll('"', '""')}"';

  TableCellValue _cell(dynamic value, TableDataColumn column) {
    if (value == null) return const TableCellValue.nullValue();
    if (value is List<int> && _isBinaryColumn(column.databaseType)) {
      return TableCellValue.binary(Uint8List.fromList(value));
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
    return type == 'bytea';
  }

  @override
  Future<List<QueryResult>> executeQuery(
    covariant Connection connection,
    String database,
    String sql,
  ) async {
    pg.Connection? conn;
    try {
      conn = await _connect(connection, database: database);

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

          final columns = resultSet.schema.columns
              .map(
                (col) => TableDataColumn(
                  name: col.columnName ?? '?',
                  databaseType: 'unknown', // schema might not have types explicitly exposed simply
                  length: 0,
                  isPrimaryKey: false,
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
                  for (var index = 0; index < columns.length; index++)
                    _cell(row[index], columns[index]),
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
      await conn?.close();
    }
  }
}
