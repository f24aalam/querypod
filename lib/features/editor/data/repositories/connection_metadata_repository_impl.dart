import 'package:drift/drift.dart';

import '../../../../app/database.dart';
import '../../../../core/database/database_driver_factory.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/connection_database.dart';
import '../../domain/entities/connection_schema.dart';
import '../../domain/entities/connection_table.dart';
import '../../domain/entities/table_data.dart';
import '../../domain/repositories/connection_metadata_repository.dart';

class ConnectionMetadataRepositoryImpl implements ConnectionMetadataRepository {
  final QueryPodDatabase _database;

  ConnectionMetadataRepositoryImpl({required QueryPodDatabase database})
    // ignore: prefer_initializing_formals
    : _database = database;

  @override
  Future<List<ConnectionDatabase>> listDatabases(Connection connection) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.listDatabases(connection);
  }

  @override
  Future<List<ConnectionTable>> listTables(
    Connection connection,
    String database,
    String? schema,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.listTables(connection, database, schema);
  }

  @override
  Future<List<ConnectionSchema>> listSchemas(
    Connection connection,
    String database,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.listSchemas(connection, database);
  }

  @override
  Future<String?> getSelectedSchema({
    required String connectionId,
    required String database,
  }) async {
    final query = _database.select(_database.selectedSchemas)
      ..where(
        (row) =>
            row.connectionId.equals(connectionId) &
            row.database.equals(database),
      );
    final row = await query.getSingleOrNull();
    return row?.pgSchema;
  }

  @override
  Future<void> setSelectedSchema({
    required String connectionId,
    required String database,
    required String? schema,
  }) async {
    if (schema == null || schema.trim().isEmpty) {
      await (_database.delete(_database.selectedSchemas)..where(
            (row) =>
                row.connectionId.equals(connectionId) &
                row.database.equals(database),
          ))
          .go();
      return;
    }

    await _database
        .into(_database.selectedSchemas)
        .insertOnConflictUpdate(
          SelectedSchemasCompanion.insert(
            connectionId: connectionId,
            database: database,
            pgSchema: schema.trim(),
          ),
        );
  }

  @override
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  }) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.createDatabase(
      connection,
      name,
      charset: charset,
      collation: collation,
    );
  }

  @override
  Future<void> createTable(
    Connection connection,
    String database,
    String? schema,
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.createTable(connection, database, schema, tableName, columns);
  }

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String? schema,
    String table,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.getTableSchema(connection, database, schema, table);
  }

  @override
  Future<void> createSchema(
    Connection connection,
    String database,
    String name,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.createSchema(connection, database, name);
  }

  @override
  Future<void> alterTable(
    Connection connection,
    String database,
    String? schema,
    String oldTableName,
    String newTableName,
    List<TableColumnDefinition> oldColumns,
    List<TableColumnDefinition> newColumns,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.alterTable(
      connection,
      database,
      schema,
      oldTableName,
      newTableName,
      oldColumns,
      newColumns,
    );
  }

  @override
  Future<void> dropTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    bool cascade = false,
  }) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.dropTable(
      connection,
      database,
      table,
      schema: schema,
      cascade: cascade,
    );
  }

  @override
  Future<void> truncateTable(
    Connection connection,
    String database,
    String table, {
    String? schema,
    bool cascade = false,
  }) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.truncateTable(
      connection,
      database,
      table,
      schema: schema,
      cascade: cascade,
    );
  }
}
