
import '../../../../core/database/database_driver_factory.dart';

import '../../../connections/domain/entities/connection.dart';
import '../../domain/entities/workspace_database.dart';
import '../../domain/entities/workspace_table.dart';
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
}
