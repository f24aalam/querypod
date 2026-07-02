import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Creates the querypod_lab fixture schema in a SQLite database.
///
/// This mirrors the MySQL/Postgres init SQL but adapted for SQLite syntax:
/// - INTEGER PRIMARY KEY AUTOINCREMENT instead of BIGINT AUTO_INCREMENT
/// - TEXT instead of JSON/JSONB
/// - TEXT instead of VARCHAR/DATETIME/DATE/TIMESTAMP
Future<void> createSqliteFixtureSchema(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');

  // -- base schema (10-base-schema.sql equivalent) --

  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE,
      display_name TEXT NOT NULL,
      profile_json TEXT,
      timezone TEXT NOT NULL DEFAULT 'UTC',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE projects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_user_id INTEGER NOT NULL REFERENCES users(id),
      slug TEXT NOT NULL UNIQUE,
      title TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'active',
      launched_on TEXT,
      metadata TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE project_members (
      project_id INTEGER NOT NULL REFERENCES projects(id),
      user_id INTEGER NOT NULL REFERENCES users(id),
      role_name TEXT NOT NULL,
      joined_at TEXT NOT NULL,
      PRIMARY KEY (project_id, user_id)
    )
  ''');

  await db.execute('''
    CREATE TABLE activity_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id INTEGER NOT NULL REFERENCES projects(id),
      actor_user_id INTEGER REFERENCES users(id),
      action_name TEXT NOT NULL,
      payload TEXT,
      happened_at TEXT NOT NULL
    )
  ''');

  // -- edge schema (20-edge-schema.sql equivalent) --

  await db.execute('''
    CREATE TABLE "order" (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      "group" TEXT NOT NULL,
      notes TEXT,
      inserted_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE json_documents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      doc_key TEXT NOT NULL UNIQUE,
      payload TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE temporal_edges (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      label_name TEXT NOT NULL,
      due_date TEXT,
      happened_at TEXT,
      created_ts TEXT,
      updated_ts TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE org_nodes (
      id INTEGER PRIMARY KEY,
      parent_id INTEGER REFERENCES org_nodes(id),
      node_name TEXT NOT NULL,
      depth_level INTEGER NOT NULL DEFAULT 0
    )
  ''');

  await db.execute('''
    CREATE TABLE large_events (
      id INTEGER PRIMARY KEY,
      category_name TEXT NOT NULL,
      event_name TEXT NOT NULL,
      event_meta TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');

  // -- indexes and view (90-views-and-indexes.sql equivalent) --

  await db.execute(
    'CREATE INDEX idx_projects_status ON projects (status)',
  );
  await db.execute(
    'CREATE INDEX idx_activity_logs_happened_at ON activity_logs (happened_at)',
  );
  await db.execute(
    'CREATE INDEX idx_temporal_edges_due_date ON temporal_edges (due_date)',
  );
  await db.execute(
    'CREATE INDEX idx_large_events_category_created '
    'ON large_events (category_name, created_at)',
  );

  await db.execute('''
    CREATE VIEW active_project_overview AS
    SELECT
      p.id,
      p.slug,
      p.title,
      p.status,
      u.display_name AS owner_name,
      COUNT(pm.user_id) AS member_count
    FROM projects p
    JOIN users u ON u.id = p.owner_user_id
    LEFT JOIN project_members pm ON pm.project_id = p.id
    GROUP BY p.id, p.slug, p.title, p.status, u.display_name
  ''');
}

/// Seeds the querypod_lab fixture data in a SQLite database.
///
/// Data matches the MySQL/Postgres seed inserts exactly.
Future<void> seedSqliteFixtureData(Database db) async {
  // -- users --
  await db.execute('''
    INSERT INTO users (email, display_name, profile_json, timezone, created_at, updated_at) VALUES
      ('ada@example.com', 'Ada Lovelace', '{"theme":"solarized","editor":"vim"}', 'UTC', '2024-01-10 09:00:00', '2024-01-10 09:00:00'),
      ('grace@example.com', 'Grace Hopper', '{"theme":"light","editor":"emacs"}', 'America/New_York', '2024-01-11 10:30:00', '2024-01-11 10:30:00'),
      ('linus@example.com', 'Linus Torvalds', NULL, 'Europe/Helsinki', '2024-01-12 08:15:00', '2024-01-12 08:15:00')
  ''');

  // -- projects --
  await db.execute('''
    INSERT INTO projects (owner_user_id, slug, title, status, launched_on, metadata, created_at, updated_at) VALUES
      (1, 'querypod-core', 'QueryPod Core', 'active', '2024-02-01', '{"language":"dart","dbs":["mysql","postgres"]}', '2024-02-01 09:00:00', '2024-02-01 09:00:00'),
      (2, 'driver-lab', 'Driver Lab', 'paused', NULL, '{"language":"sql","focus":"metadata"}', '2024-02-03 12:00:00', '2024-02-03 12:00:00')
  ''');

  // -- project_members --
  await db.execute('''
    INSERT INTO project_members (project_id, user_id, role_name, joined_at) VALUES
      (1, 1, 'owner', '2024-02-01 09:00:00'),
      (1, 2, 'editor', '2024-02-01 09:30:00'),
      (2, 2, 'owner', '2024-02-03 12:00:00'),
      (2, 3, 'reviewer', '2024-02-03 12:30:00')
  ''');

  // -- activity_logs --
  await db.execute('''
    INSERT INTO activity_logs (project_id, actor_user_id, action_name, payload, happened_at) VALUES
      (1, 1, 'project_created', '{"source":"seed"}', '2024-02-01 09:01:00'),
      (1, 2, 'member_joined', '{"role":"editor"}', '2024-02-01 09:31:00'),
      (2, NULL, 'status_synced', '{"state":"paused","reason":"fixture"}', '2024-02-03 12:35:00')
  ''');

  // -- edge-case tables --
  await db.execute('''
    INSERT INTO "order" ("group", notes, inserted_at) VALUES
      ('alpha', 'Reserved identifiers fixture', '2024-03-01 08:00:00'),
      ('beta', 'Second row', '2024-03-01 08:05:00')
  ''');

  await db.execute('''
    INSERT INTO json_documents (doc_key, payload, created_at) VALUES
      ('settings', '{"enabled":true,"threshold":42,"tags":["db","ui"]}', '2024-03-04 10:00:00'),
      ('profile', '{"nested":{"level":2},"null_field":null}', '2024-03-05 11:00:00')
  ''');

  await db.execute('''
    INSERT INTO temporal_edges (label_name, due_date, happened_at, created_ts, updated_ts) VALUES
      ('leap-day', '2024-02-29', '2024-02-29 23:59:59', '2024-02-29 23:59:59', '2024-03-01 00:00:00'),
      ('epoch-near', '1970-01-02', '1970-01-02 00:00:01', '1970-01-02 00:00:01', '1970-01-03 00:00:01'),
      ('future-nullable', '2099-12-31', NULL, NULL, NULL)
  ''');

  await db.execute('''
    INSERT INTO org_nodes (id, parent_id, node_name, depth_level) VALUES
      (1, NULL, 'root', 0),
      (2, 1, 'engineering', 1),
      (3, 2, 'query-engine', 2),
      (4, 1, 'design', 1)
  ''');

  // -- large_events: 1000 rows for pagination testing --
  final batch = db.batch();
  final categories = ['audit', 'sync', 'query', 'user'];
  for (var i = 1; i <= 1000; i++) {
    final category = categories[i % 4];
    final eventName = 'event-${i.toString().padLeft(4, '0')}';
    final eventMeta =
        '{"batch":${(i - 1) ~/ 100},"important":${i % 10 == 0},"ordinal":$i}';
    final minutes = i;
    final createdAt = DateTime(2024, 4, 1).add(Duration(minutes: minutes));
    final createdAtStr =
        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-'
        '${createdAt.day.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}:'
        '${createdAt.second.toString().padLeft(2, '0')}';

    batch.rawInsert(
      'INSERT INTO large_events (id, category_name, event_name, event_meta, created_at) '
      'VALUES (?, ?, ?, ?, ?)',
      [i, category, eventName, eventMeta, createdAtStr],
    );
  }
  await batch.commit(noResult: true);
}
