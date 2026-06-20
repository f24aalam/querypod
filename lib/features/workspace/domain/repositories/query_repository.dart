import '../entities/workspace_query.dart';

abstract class QueryRepository {
  Future<List<WorkspaceQuery>> getAllForConnection(String connectionId);

  Future<WorkspaceQuery> save(WorkspaceQuery query);

  Future<void> delete(String id);

  Future<void> deleteByConnection(String connectionId);
}
