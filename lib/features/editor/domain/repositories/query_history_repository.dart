import '../entities/query_history.dart';

abstract class QueryHistoryRepository {
  Future<List<QueryHistory>> getAllForConnection(String connectionId);
  Future<QueryHistory> save(QueryHistory history);
  Future<void> clearHistory(String connectionId);
  Stream<void> watchHistory(String connectionId);
}
