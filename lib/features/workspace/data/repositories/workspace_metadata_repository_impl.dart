
import '../../../../core/database/database_driver_factory.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/workspace_database.dart';
import '../../domain/entities/workspace_table.dart';
import '../../domain/entities/table_data.dart';
import '../../domain/repositories/workspace_metadata_repository.dart';

class WorkspaceMetadataRepositoryImpl implements WorkspaceMetadataRepository {
  @override
  Future<List<WorkspaceDatabase>> listDatabases(Connection connection) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.listDatabases(connection);
  }

  @override
  Future<List<WorkspaceTable>> listTables(
    Connection connection,
    String database,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.listTables(connection, database);
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
    String tableName,
    List<TableColumnDefinition> columns,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.createTable(connection, database, tableName, columns);
  }

  @override
  Future<List<TableColumnDefinition>> getTableSchema(
    Connection connection,
    String database,
    String table,
  ) async {
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    return await driver.getTableSchema(connection, database, table);
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
    final driver = DatabaseDriverFactory.getDriver(connection.type);
    await driver.alterTable(connection, database, oldTableName, newTableName, oldColumns, newColumns);
  }
}
