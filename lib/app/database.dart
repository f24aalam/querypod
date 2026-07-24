import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('WorkspaceRow')
class Workspaces extends Table {
  @override
  String get tableName => 'workspaces';

  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'idx_connections_workspace_id', columns: {#workspaceId})
@DataClassName('ConnectionRow')
class Connections extends Table {
  @override
  String get tableName => 'connections';

  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get host => text()();
  IntColumn get port => integer()();
  TextColumn get user => text()();
  TextColumn get database => text()();
  TextColumn get connectionType => text().named('type')();
  BoolColumn get useTls => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(
  name: 'idx_saved_queries_connection_id',
  columns: {#connectionId, #createdAt},
)
@DataClassName('SavedQueryRow')
class SavedQueries extends Table {
  @override
  String get tableName => 'saved_queries';

  TextColumn get id => text()();
  TextColumn get connectionId =>
      text().references(Connections, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get sql => text()();
  TextColumn get database => text().nullable()();
  TextColumn get querySchema => text().named('schema').nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(
  name: 'idx_query_history_connection_id',
  columns: {#connectionId, #createdAt},
)
@DataClassName('QueryHistoryRow')
class QueryHistoryEntries extends Table {
  @override
  String get tableName => 'query_history';

  TextColumn get id => text()();
  TextColumn get connectionId =>
      text().references(Connections, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourceType => text()();
  TextColumn get sourceId => text().nullable()();
  TextColumn get sql => text()();
  IntColumn get executionTimeMs => integer()();
  TextColumn get status => text()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PinnedTableRow')
class PinnedTables extends Table {
  @override
  String get tableName => 'pinned_tables';

  TextColumn get connectionId =>
      text().references(Connections, #id, onDelete: KeyAction.cascade)();
  TextColumn get database => text()();
  TextColumn get pgSchema =>
      text().named('schema').withDefault(const Constant('public'))();
  TextColumn get table => text().named('table_name')();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    connectionId,
    database,
    pgSchema,
    table,
  };
}

@DataClassName('SelectedSchemaRow')
class SelectedSchemas extends Table {
  @override
  String get tableName => 'selected_schemas';

  TextColumn get connectionId =>
      text().references(Connections, #id, onDelete: KeyAction.cascade)();
  TextColumn get database => text()();
  TextColumn get pgSchema => text().named('schema')();

  @override
  Set<Column<Object>> get primaryKey => {connectionId, database};
}

@DataClassName('AppStateRow')
class AppStateEntries extends Table {
  @override
  String get tableName => 'app_state';

  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get selectedConnectionId => text().nullable().references(
    Connections,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}

@DriftDatabase(
  tables: [
    Workspaces,
    Connections,
    SavedQueries,
    QueryHistoryEntries,
    PinnedTables,
    SelectedSchemas,
    AppStateEntries,
  ],
)
class QueryPodDatabase extends _$QueryPodDatabase {
  QueryPodDatabase({QueryExecutor? executor, String profileNamespace = ''})
    : super(executor ?? _openProfileDatabase(profileNamespace));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement('INSERT INTO app_state (id) VALUES (1)');
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(savedQueries, savedQueries.querySchema);
        await customStatement(
          'ALTER TABLE pinned_tables RENAME TO pinned_tables_old',
        );
        await migrator.createTable(pinnedTables);
        await customStatement('''
          INSERT INTO pinned_tables (connection_id, database, schema, table_name, sort_order)
          SELECT connection_id, database, 'public', table_name, sort_order
          FROM pinned_tables_old
          ''');
        await customStatement('DROP TABLE pinned_tables_old');
        await migrator.createTable(selectedSchemas);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static String filenameForProfile(String profileNamespace) {
    final normalized = profileNamespace.trim();
    if (normalized.isEmpty) return 'querypod.db';

    final encoded = base64Url
        .encode(utf8.encode(normalized))
        .replaceAll('=', '');
    return 'querypod_$encoded.db';
  }
}

QueryExecutor _openProfileDatabase(String profileNamespace) {
  return LazyDatabase(() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final databaseDirectory = Directory(
      p.join(supportDirectory.path, 'querypod'),
    );
    await databaseDirectory.create(recursive: true);
    final file = File(
      p.join(
        databaseDirectory.path,
        QueryPodDatabase.filenameForProfile(profileNamespace),
      ),
    );
    return NativeDatabase.createInBackground(file);
  });
}
