import 'dart:convert';
import 'dart:typed_data';

import 'package:mysql_client_plus/mysql_client_plus.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/table_data.dart';
import '../../domain/repositories/table_data_repository.dart';

class TableDataRepositoryImpl implements TableDataRepository {
  Future<MySQLConnection> _connect(
    Connection connection,
    String database,
  ) async {
    final conn = await MySQLConnection.createConnection(
      host: connection.host,
      port: connection.port,
      userName: connection.user,
      password: connection.password,
      databaseName: database,
      secure: false,
    );
    await conn.connect();
    return conn;
  }

  @override
  Future<TableStructure> inspectTable(
    Connection connection,
    String database,
    String table,
  ) async {
    final conn = await _connect(connection, database);
    try {
      final quotedDatabase = _quoteIdentifier(database);
      final quotedTable = _quoteIdentifier(table);
      final schema = await conn.execute(
        'SHOW COLUMNS FROM $quotedDatabase.$quotedTable',
      );
      final primaryKeys = <String>{};
      final types = <String, String>{};

      for (final row in schema.rows) {
        final name = _asString(row.colByName('Field'));
        types[name] = _asString(row.colByName('Type'));
        if (_asString(row.colByName('Key')).toUpperCase() == 'PRI') {
          primaryKeys.add(name);
        }
      }

      final sample = await conn.execute(
        'SELECT * FROM $quotedDatabase.$quotedTable LIMIT 0',
      );
      final columns = sample.cols
          .map(
            (column) => TableDataColumn(
              name: column.name,
              databaseType: types[column.name] ?? column.type.intVal.toString(),
              length: column.length,
              isPrimaryKey: primaryKeys.contains(column.name),
            ),
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
    Connection connection,
    String database,
    String table,
  ) async {
    final conn = await _connect(connection, database);
    try {
      final result = await conn.execute(
        'SELECT COUNT(*) AS total FROM '
        '${_quoteIdentifier(database)}.${_quoteIdentifier(table)}',
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
  }) async {
    final conn = await _connect(connection, database);
    final stopwatch = Stopwatch()..start();
    try {
      final result = await conn.execute(
        'SELECT * FROM ${_quoteIdentifier(database)}.${_quoteIdentifier(table)} '
        'ORDER BY ${_quoteIdentifier(structure.orderColumn)} ASC '
        'LIMIT $limit OFFSET $offset',
      );
      final rows = result.rows
          .map(
            (row) => TableDataRow([
              for (var index = 0; index < structure.columns.length; index++)
                _cell(row.colAt(index)),
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

  String _quoteIdentifier(String value) => '`${value.replaceAll('`', '``')}`';

  String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Uint8List) return utf8.decode(value, allowMalformed: true);
    return value.toString();
  }

  TableCellValue _cell(dynamic value) {
    if (value == null) return const TableCellValue.nullValue();
    if (value is Uint8List) return TableCellValue.binary(value.length);
    return TableCellValue.text(value.toString());
  }
}
