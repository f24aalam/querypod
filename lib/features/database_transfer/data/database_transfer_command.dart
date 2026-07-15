import '../../connections/domain/entities/connection.dart';
import '../domain/database_tool.dart';
import '../domain/database_transfer.dart';

class DatabaseTransferCommand {
  final DatabaseTool tool;
  final List<String> arguments;
  final String? sqliteOutputPath;

  const DatabaseTransferCommand({
    required this.tool,
    required this.arguments,
    this.sqliteOutputPath,
  });
}

class DatabaseTransferCommandFactory {
  const DatabaseTransferCommandFactory();

  DatabaseTransferCommand build(
    DatabaseTransferRequest request, {
    required String workingPath,
    String? mysqlDefaultsPath,
  }) {
    return switch (request.connection.type) {
      ConnectionType.mysql => _mysql(
        request,
        mysqlDefaultsPath: mysqlDefaultsPath,
      ),
      ConnectionType.postgresql => _postgres(request, workingPath),
      ConnectionType.sqlite => _sqlite(request, workingPath),
    };
  }

  DatabaseTransferCommand _mysql(
    DatabaseTransferRequest request, {
    required String? mysqlDefaultsPath,
  }) {
    if (mysqlDefaultsPath == null) {
      throw StateError('MySQL credentials were not prepared');
    }
    final defaults = '--defaults-extra-file=$mysqlDefaultsPath';
    if (request.direction == DatabaseTransferDirection.import) {
      return DatabaseTransferCommand(
        tool: DatabaseTool.mysql,
        arguments: [defaults, '--database=${request.database}'],
      );
    }

    final arguments = <String>[
      defaults,
      '--single-transaction',
      '--quick',
      '--routines',
      '--events',
      '--triggers',
      if (request.content == DatabaseTransferContent.schemaOnly) '--no-data',
      if (request.content == DatabaseTransferContent.dataOnly)
        '--no-create-info',
      request.database,
    ];
    return DatabaseTransferCommand(
      tool: DatabaseTool.mysqldump,
      arguments: arguments,
    );
  }

  DatabaseTransferCommand _postgres(
    DatabaseTransferRequest request,
    String workingPath,
  ) {
    final connectionArguments = _postgresConnectionArguments(
      request.connection,
    );
    if (request.direction == DatabaseTransferDirection.export) {
      final format = switch (request.format) {
        DatabaseTransferFormat.postgresCustom => 'custom',
        DatabaseTransferFormat.postgresTar => 'tar',
        _ => 'plain',
      };
      return DatabaseTransferCommand(
        tool: DatabaseTool.pgDump,
        arguments: [
          ...connectionArguments,
          '--format=$format',
          if (request.content == DatabaseTransferContent.schemaOnly)
            '--schema-only',
          if (request.content == DatabaseTransferContent.dataOnly)
            '--data-only',
          request.database,
        ],
      );
    }

    if (request.format == DatabaseTransferFormat.postgresCustom ||
        request.format == DatabaseTransferFormat.postgresTar) {
      return DatabaseTransferCommand(
        tool: DatabaseTool.pgRestore,
        arguments: [
          ...connectionArguments,
          '--dbname=${request.database}',
          '--exit-on-error',
          workingPath,
        ],
      );
    }
    return DatabaseTransferCommand(
      tool: DatabaseTool.psql,
      arguments: [
        ...connectionArguments,
        '--dbname=${request.database}',
        '--no-psqlrc',
        '--set=ON_ERROR_STOP=on',
      ],
    );
  }

  DatabaseTransferCommand _sqlite(
    DatabaseTransferRequest request,
    String workingPath,
  ) {
    final databasePath = request.connection.database;
    if (request.direction == DatabaseTransferDirection.import) {
      return DatabaseTransferCommand(
        tool: DatabaseTool.sqlite3,
        arguments: [databasePath, '-bail'],
      );
    }
    if (request.format == DatabaseTransferFormat.sqliteDatabase) {
      final quotedPath = '"${workingPath.replaceAll('"', '""')}"';
      return DatabaseTransferCommand(
        tool: DatabaseTool.sqlite3,
        arguments: [databasePath, '.backup $quotedPath'],
        sqliteOutputPath: workingPath,
      );
    }
    final command = switch (request.content) {
      DatabaseTransferContent.full => '.dump --nosys',
      DatabaseTransferContent.schemaOnly => '.schema --nosys',
      DatabaseTransferContent.dataOnly => '.dump --data-only --nosys',
    };
    return DatabaseTransferCommand(
      tool: DatabaseTool.sqlite3,
      arguments: [databasePath, command],
    );
  }

  List<String> _postgresConnectionArguments(Connection connection) => [
    '--host=${connection.host}',
    '--port=${connection.port}',
    if (connection.user.isNotEmpty) '--username=${connection.user}',
  ];
}
