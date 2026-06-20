import 'dart:convert';
import 'dart:typed_data';

import 'package:mysql_client_plus/mysql_client_plus.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/workspace_database.dart';
import '../../domain/entities/workspace_table.dart';
import '../../domain/repositories/workspace_metadata_repository.dart';

class WorkspaceMetadataRepositoryImpl implements WorkspaceMetadataRepository {
  String _asString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Uint8List) return utf8.decode(value);
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
}
