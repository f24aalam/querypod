import '../../../connections/domain/entities/connection.dart';
import '../entities/workspace_database.dart';
import '../entities/workspace_table.dart';

abstract class WorkspaceMetadataRepository {
  Future<List<WorkspaceDatabase>> listDatabases(Connection connection);
  Future<List<WorkspaceTable>> listTables(
    Connection connection,
    String database,
  );
  Future<void> createDatabase(
    Connection connection,
    String name, {
    String? charset,
    String? collation,
  });
}
