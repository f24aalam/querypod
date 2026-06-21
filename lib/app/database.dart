import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';

Future<Database> openAppDatabase({
  required DatabaseFactory databaseFactory,
}) async {
  final databasesPath = await databaseFactory.getDatabasesPath();
  return await databaseFactory.openDatabase(
    p.join(databasesPath, 'querypod.db'),
    options: OpenDatabaseOptions(
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE queries (
            id TEXT PRIMARY KEY,
            connection_id TEXT NOT NULL,
            title TEXT NOT NULL,
            sql TEXT NOT NULL,
            database TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_queries_connection_id ON queries(connection_id)',
        );

        await db.execute('''
          CREATE TABLE query_history (
            id TEXT PRIMARY KEY,
            connection_id TEXT NOT NULL,
            source_type TEXT NOT NULL,
            source_id TEXT,
            sql TEXT NOT NULL,
            execution_time_ms INTEGER NOT NULL,
            status TEXT NOT NULL,
            error_message TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_query_history_connection_id ON query_history(connection_id)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE queries ADD COLUMN database TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE query_history (
              id TEXT PRIMARY KEY,
              connection_id TEXT NOT NULL,
              source_type TEXT NOT NULL,
              source_id TEXT,
              sql TEXT NOT NULL,
              execution_time_ms INTEGER NOT NULL,
              status TEXT NOT NULL,
              error_message TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_query_history_connection_id ON query_history(connection_id)',
          );
        }
      },
    ),
  );
}
