// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';

import '../../../../app/database.dart';
import '../../domain/entities/query_history.dart';
import '../../domain/repositories/query_history_repository.dart';

class QueryHistoryRepositoryImpl implements QueryHistoryRepository {
  final QueryPodDatabase _database;

  QueryHistoryRepositoryImpl({required QueryPodDatabase database})
    : _database = database;

  @override
  Future<List<QueryHistory>> getAllForConnection(String connectionId) async {
    final query = _historyQuery(connectionId)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    final rows = await query.get();
    return rows.map(_toEntity).toList(growable: false);
  }

  @override
  Future<QueryHistory> save(QueryHistory history) async {
    await _database
        .into(_database.queryHistoryEntries)
        .insertOnConflictUpdate(
          QueryHistoryEntriesCompanion.insert(
            id: history.id,
            connectionId: history.connectionId,
            sourceType: history.sourceType,
            sourceId: Value(history.sourceId),
            sql: history.sql,
            executionTimeMs: history.executionTimeMs,
            status: history.status,
            errorMessage: Value(history.errorMessage),
            createdAt: history.createdAt,
          ),
        );
    return history;
  }

  @override
  Future<void> clearHistory(String connectionId) async {
    await (_database.delete(
      _database.queryHistoryEntries,
    )..where((row) => row.connectionId.equals(connectionId))).go();
  }

  @override
  Stream<void> watchHistory(String connectionId) {
    return _historyQuery(connectionId).watch().skip(1).map<void>((_) {});
  }

  SimpleSelectStatement<$QueryHistoryEntriesTable, QueryHistoryRow>
  _historyQuery(String connectionId) {
    return _database.select(_database.queryHistoryEntries)
      ..where((row) => row.connectionId.equals(connectionId));
  }

  QueryHistory _toEntity(QueryHistoryRow row) => QueryHistory(
    id: row.id,
    connectionId: row.connectionId,
    sourceType: row.sourceType,
    sourceId: row.sourceId,
    sql: row.sql,
    executionTimeMs: row.executionTimeMs,
    status: row.status,
    errorMessage: row.errorMessage,
    createdAt: row.createdAt,
  );
}
