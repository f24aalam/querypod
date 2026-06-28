import '../entities/connection_query.dart';

abstract class QueryRepository {
  Future<List<ConnectionQuery>> getAllForConnection(String connectionId);

  Future<ConnectionQuery> save(ConnectionQuery query);

  Future<void> delete(String id);

  Future<void> deleteByConnection(String connectionId);
}
