import '../../connections/domain/entities/connection.dart';

enum DatabaseTransferDirection { import, export }

enum DatabaseTransferContent { full, schemaOnly, dataOnly }

enum DatabaseRestoreMode { merge, clean }

enum DatabaseTransferFormat {
  mysqlSql,
  postgresPlain,
  postgresCustom,
  postgresTar,
  sqliteSql,
  sqliteDatabase,
}

extension DatabaseTransferFormatInfo on DatabaseTransferFormat {
  String get label => switch (this) {
    DatabaseTransferFormat.mysqlSql => 'SQL',
    DatabaseTransferFormat.postgresPlain => 'Plain SQL',
    DatabaseTransferFormat.postgresCustom => 'Custom archive',
    DatabaseTransferFormat.postgresTar => 'Tar archive',
    DatabaseTransferFormat.sqliteSql => 'SQL',
    DatabaseTransferFormat.sqliteDatabase => 'SQLite database',
  };

  String get defaultExtension => switch (this) {
    DatabaseTransferFormat.mysqlSql ||
    DatabaseTransferFormat.postgresPlain ||
    DatabaseTransferFormat.sqliteSql => 'sql',
    DatabaseTransferFormat.postgresCustom => 'dump',
    DatabaseTransferFormat.postgresTar => 'tar',
    DatabaseTransferFormat.sqliteDatabase => 'sqlite',
  };

  bool get isPlainSql => switch (this) {
    DatabaseTransferFormat.mysqlSql ||
    DatabaseTransferFormat.postgresPlain ||
    DatabaseTransferFormat.sqliteSql => true,
    _ => false,
  };
}

class DatabaseTransferRequest {
  final DatabaseTransferDirection direction;
  final Connection connection;
  final String database;
  final String path;
  final DatabaseTransferFormat format;
  final DatabaseTransferContent content;
  final DatabaseRestoreMode restoreMode;
  final bool gzip;

  const DatabaseTransferRequest({
    required this.direction,
    required this.connection,
    required this.database,
    required this.path,
    required this.format,
    this.content = DatabaseTransferContent.full,
    this.restoreMode = DatabaseRestoreMode.merge,
    this.gzip = false,
  });
}

sealed class DatabaseTransferEvent {
  const DatabaseTransferEvent();
}

class DatabaseTransferStarted extends DatabaseTransferEvent {
  final String phase;
  const DatabaseTransferStarted(this.phase);
}

class DatabaseTransferLog extends DatabaseTransferEvent {
  final String message;
  const DatabaseTransferLog(this.message);
}

class DatabaseTransferCompleted extends DatabaseTransferEvent {
  final Duration duration;
  final int? bytes;
  const DatabaseTransferCompleted({required this.duration, this.bytes});
}

class DatabaseTransferFailed extends DatabaseTransferEvent {
  final String message;
  const DatabaseTransferFailed(this.message);
}

class DatabaseTransferCancelled extends DatabaseTransferEvent {
  const DatabaseTransferCancelled();
}
