import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';

import '../../domain/entities/workspace_query.dart';
import '../../domain/repositories/query_repository.dart';

class QueryRepositoryImpl implements QueryRepository {
  static const databaseName = 'querypod.db';
  static const tableName = 'queries';

  final Database _database;

  QueryRepositoryImpl._(this._database);

  static Future<QueryRepositoryImpl> open({
    required DatabaseFactory databaseFactory,
  }) async {
    final databasesPath = await databaseFactory.getDatabasesPath();
    final database = await databaseFactory.openDatabase(
      p.join(databasesPath, databaseName),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableName (
              id TEXT PRIMARY KEY,
              connection_id TEXT NOT NULL,
              title TEXT NOT NULL,
              sql TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_queries_connection_id ON $tableName(connection_id)',
          );
        },
      ),
    );
    return QueryRepositoryImpl._(database);
  }

  @override
  Future<List<WorkspaceQuery>> getAllForConnection(String connectionId) async {
    final rows = await _database.query(
      tableName,
      where: 'connection_id = ?',
      whereArgs: [connectionId],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<WorkspaceQuery> save(WorkspaceQuery query) async {
    await _database.insert(tableName, {
      'id': query.id,
      'connection_id': query.connectionId,
      'title': query.title,
      'sql': query.sql,
      'created_at': query.createdAt.millisecondsSinceEpoch,
      'updated_at': query.updatedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return query;
  }

  @override
  Future<void> delete(String id) async {
    await _database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteByConnection(String connectionId) async {
    await _database.delete(
      tableName,
      where: 'connection_id = ?',
      whereArgs: [connectionId],
    );
  }

  WorkspaceQuery _fromRow(Map<String, Object?> row) {
    return WorkspaceQuery(
      id: row['id']! as String,
      connectionId: row['connection_id']! as String,
      title: row['title']! as String,
      sql: row['sql']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
    );
  }
}
