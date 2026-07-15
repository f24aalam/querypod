enum DatabaseTool { mysql, mysqldump, psql, pgDump, pgRestore, sqlite3 }

extension DatabaseToolInfo on DatabaseTool {
  String get executableName => switch (this) {
    DatabaseTool.mysql => 'mysql',
    DatabaseTool.mysqldump => 'mysqldump',
    DatabaseTool.psql => 'psql',
    DatabaseTool.pgDump => 'pg_dump',
    DatabaseTool.pgRestore => 'pg_restore',
    DatabaseTool.sqlite3 => 'sqlite3',
  };

  String get label => switch (this) {
    DatabaseTool.mysql => 'MySQL client',
    DatabaseTool.mysqldump => 'MySQL dump',
    DatabaseTool.psql => 'PostgreSQL client',
    DatabaseTool.pgDump => 'PostgreSQL dump',
    DatabaseTool.pgRestore => 'PostgreSQL restore',
    DatabaseTool.sqlite3 => 'SQLite CLI',
  };

  String get settingsKey => 'database_tool.$executableName.path';
}

class DatabaseToolStatus {
  final DatabaseTool tool;
  final String? path;
  final String? version;
  final String? error;
  final bool isOverride;

  const DatabaseToolStatus({
    required this.tool,
    this.path,
    this.version,
    this.error,
    this.isOverride = false,
  });

  bool get isAvailable => path != null && error == null;
}
