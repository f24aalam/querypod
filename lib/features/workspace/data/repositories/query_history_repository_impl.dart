import 'dart:async';

import 'package:sqflite_common/sqlite_api.dart';

import '../../domain/entities/query_history.dart';
import '../../domain/repositories/query_history_repository.dart';

class QueryHistoryRepositoryImpl implements QueryHistoryRepository {
  static const tableName = 'query_history';

  final Database _database;
  final _controller = StreamController<String>.broadcast();

  // ignore: prefer_initializing_formals
  QueryHistoryRepositoryImpl({required Database database})
    : _database = database;

  @override
  Future<List<QueryHistory>> getAllForConnection(String connectionId) async {
    final rows = await _database.query(
      tableName,
      where: 'connection_id = ?',
      whereArgs: [connectionId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<QueryHistory> save(QueryHistory history) async {
    await _database.insert(tableName, {
      'id': history.id,
      'connection_id': history.connectionId,
      'source_type': history.sourceType,
      'source_id': history.sourceId,
      'sql': history.sql,
      'execution_time_ms': history.executionTimeMs,
      'status': history.status,
      'error_message': history.errorMessage,
      'created_at': history.createdAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _controller.add(history.connectionId);
    return history;
  }

  @override
  Future<void> clearHistory(String connectionId) async {
    await _database.delete(
      tableName,
      where: 'connection_id = ?',
      whereArgs: [connectionId],
    );
    _controller.add(connectionId);
  }

  @override
  Stream<void> watchHistory(String connectionId) {
    return _controller.stream.where((id) => id == connectionId);
  }

  QueryHistory _fromRow(Map<String, Object?> row) {
    return QueryHistory(
      id: row['id']! as String,
      connectionId: row['connection_id']! as String,
      sourceType: row['source_type']! as String,
      sourceId: row['source_id'] as String?,
      sql: row['sql']! as String,
      executionTimeMs: row['execution_time_ms']! as int,
      status: row['status']! as String,
      errorMessage: row['error_message'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    );
  }
}
