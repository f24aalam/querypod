// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../../connections/domain/entities/connection.dart';
import '../domain/database_tool.dart';
import '../domain/database_tool_repository.dart';
import '../domain/database_transfer.dart';
import '../domain/database_transfer_repository.dart';
import 'database_transfer_command.dart';

class DatabaseTransferRepositoryImpl implements DatabaseTransferRepository {
  final DatabaseToolRepository _tools;
  final DatabaseTransferCommandFactory _commands;
  Process? _process;
  bool _running = false;
  bool _cancelRequested = false;

  DatabaseTransferRepositoryImpl({
    required DatabaseToolRepository tools,
    DatabaseTransferCommandFactory commands =
        const DatabaseTransferCommandFactory(),
  }) : _tools = tools,
       _commands = commands;

  @override
  Stream<DatabaseTransferEvent> run(DatabaseTransferRequest request) {
    final controller = StreamController<DatabaseTransferEvent>();
    if (_running) {
      controller
        ..add(
          const DatabaseTransferFailed('Another transfer is already running'),
        )
        ..close();
      return controller.stream;
    }
    _running = true;
    _cancelRequested = false;
    unawaited(_run(request, controller));
    return controller.stream;
  }

  Future<void> _run(
    DatabaseTransferRequest request,
    StreamController<DatabaseTransferEvent> events,
  ) async {
    final stopwatch = Stopwatch()..start();
    String? mysqlDefaultsPath;
    String? workingPath;
    try {
      _validateRequest(request);
      events.add(const DatabaseTransferStarted('Checking database tools'));
      mysqlDefaultsPath = request.connection.type == ConnectionType.mysql
          ? await _createMySqlDefaultsFile(request.connection)
          : null;

      if (request.direction == DatabaseTransferDirection.import) {
        await _validateImport(request, events);
      }
      if (request.direction == DatabaseTransferDirection.export &&
          request.connection.type == ConnectionType.sqlite &&
          request.content == DatabaseTransferContent.dataOnly) {
        await _validateSqliteDataOnlySupport();
      }
      if (_cancelRequested) throw const _TransferCancelled();

      if (request.direction == DatabaseTransferDirection.import &&
          request.restoreMode == DatabaseRestoreMode.clean &&
          request.connection.type != ConnectionType.sqlite) {
        events.add(const DatabaseTransferStarted('Cleaning target database'));
        await _cleanRemoteDatabase(
          request,
          events,
          mysqlDefaultsPath: mysqlDefaultsPath,
        );
      }

      if (request.direction == DatabaseTransferDirection.export) {
        workingPath = _temporarySibling(request.path);
        await _deleteIfExists(workingPath);
      } else if (request.connection.type == ConnectionType.sqlite &&
          request.restoreMode == DatabaseRestoreMode.clean) {
        workingPath = _temporarySibling(request.connection.database);
        await _deleteIfExists(workingPath);
      } else {
        workingPath = request.path;
      }

      if (request.direction == DatabaseTransferDirection.import &&
          request.connection.type == ConnectionType.sqlite &&
          request.format == DatabaseTransferFormat.sqliteDatabase) {
        events.add(const DatabaseTransferStarted('Validating SQLite backup'));
        await File(request.path).copy(workingPath);
        await _validateSqliteDatabase(workingPath, events);
        if (_cancelRequested) throw const _TransferCancelled();
        await _replaceFile(workingPath, request.connection.database);
      } else {
        final effectiveRequest = _withSqliteWorkingDatabase(
          request,
          workingPath,
        );
        final command = _commands.build(
          effectiveRequest,
          workingPath: workingPath,
          mysqlDefaultsPath: mysqlDefaultsPath,
        );
        final tool = await _requireTool(command.tool);
        events.add(
          DatabaseTransferStarted(
            request.direction == DatabaseTransferDirection.import
                ? 'Importing database'
                : 'Exporting database',
          ),
        );
        await _executeTransfer(
          request: effectiveRequest,
          command: command,
          executable: tool,
          workingPath: workingPath,
          events: events,
        );

        if (request.direction == DatabaseTransferDirection.export) {
          await _replaceFile(workingPath, request.path);
        } else if (request.connection.type == ConnectionType.sqlite &&
            request.restoreMode == DatabaseRestoreMode.clean) {
          await _validateSqliteDatabase(workingPath, events);
          await _replaceFile(workingPath, request.connection.database);
        }
      }

      if (_cancelRequested) throw const _TransferCancelled();
      final resultPath = request.direction == DatabaseTransferDirection.export
          ? request.path
          : null;
      events.add(
        DatabaseTransferCompleted(
          duration: stopwatch.elapsed,
          bytes: resultPath == null ? null : await File(resultPath).length(),
        ),
      );
    } on _TransferCancelled {
      events.add(const DatabaseTransferCancelled());
    } catch (error) {
      events.add(DatabaseTransferFailed(_friendlyError(error)));
    } finally {
      _process = null;
      _running = false;
      if (mysqlDefaultsPath != null) await _deleteIfExists(mysqlDefaultsPath);
      if (workingPath != null &&
          workingPath != request.path &&
          workingPath != request.connection.database) {
        await _deleteIfExists(workingPath);
      }
      await events.close();
    }
  }

  DatabaseTransferRequest _withSqliteWorkingDatabase(
    DatabaseTransferRequest request,
    String workingPath,
  ) {
    if (request.connection.type != ConnectionType.sqlite ||
        request.direction != DatabaseTransferDirection.import ||
        request.restoreMode != DatabaseRestoreMode.clean) {
      return request;
    }
    return DatabaseTransferRequest(
      direction: request.direction,
      connection: request.connection.copyWith(database: workingPath),
      database: request.database,
      path: request.path,
      format: request.format,
      content: request.content,
      restoreMode: request.restoreMode,
      gzip: request.gzip,
    );
  }

  Future<void> _executeTransfer({
    required DatabaseTransferRequest request,
    required DatabaseTransferCommand command,
    required String executable,
    required String workingPath,
    required StreamController<DatabaseTransferEvent> events,
  }) async {
    final environment = _environmentFor(request.connection);
    final process = await Process.start(
      executable,
      command.arguments,
      environment: environment,
      includeParentEnvironment: true,
      runInShell: false,
    );
    _process = process;

    final stderrDone = _forwardLines(process.stderr, events);
    Future<void> stdoutDone;
    Future<void>? inputDone;
    if (request.direction == DatabaseTransferDirection.export &&
        command.sqliteOutputPath == null) {
      var output = process.stdout;
      if (request.gzip) output = output.transform(gzip.encoder);
      stdoutDone = output.pipe(File(workingPath).openWrite());
    } else {
      stdoutDone = _forwardLines(process.stdout, events);
    }

    if (request.direction == DatabaseTransferDirection.import &&
        request.format.isPlainSql) {
      Stream<List<int>> input = File(request.path).openRead();
      if (request.gzip || request.path.toLowerCase().endsWith('.gz')) {
        input = input.transform(gzip.decoder);
      }
      inputDone = input.pipe(process.stdin);
    } else {
      await process.stdin.close();
    }

    final exitCode = await process.exitCode;
    final pendingStreams = [stdoutDone, stderrDone];
    if (inputDone != null) pendingStreams.add(inputDone);
    try {
      await Future.wait(pendingStreams);
    } catch (_) {
      if (_cancelRequested) throw const _TransferCancelled();
      rethrow;
    }
    _process = null;
    if (_cancelRequested) throw const _TransferCancelled();
    if (exitCode != 0) {
      throw ProcessException(
        executable,
        command.arguments,
        'Exited with code $exitCode',
        exitCode,
      );
    }
  }

  Future<void> _cleanRemoteDatabase(
    DatabaseTransferRequest request,
    StreamController<DatabaseTransferEvent> events, {
    required String? mysqlDefaultsPath,
  }) async {
    if (request.connection.type == ConnectionType.mysql) {
      final executable = await _requireTool(DatabaseTool.mysql);
      final quoted = _mysqlIdentifier(request.database);
      final metadata = await _capture(executable, [
        '--defaults-extra-file=$mysqlDefaultsPath',
        '--batch',
        '--skip-column-names',
        '--execute=SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME=${_sqlLiteral(request.database)};',
      ], request.connection);
      final properties = metadata.trim().split('\t');
      final charset = properties.firstOrNull;
      final collation = properties.length > 1 ? properties[1] : null;
      final createOptions =
          charset != null &&
              collation != null &&
              RegExp(r'^[A-Za-z0-9_]+$').hasMatch(charset) &&
              RegExp(r'^[A-Za-z0-9_]+$').hasMatch(collation)
          ? ' CHARACTER SET $charset COLLATE $collation'
          : '';
      final command = DatabaseTransferCommand(
        tool: DatabaseTool.mysql,
        arguments: [
          '--defaults-extra-file=$mysqlDefaultsPath',
          '--execute=DROP DATABASE IF EXISTS $quoted; CREATE DATABASE $quoted$createOptions;',
        ],
      );
      await _executeSimple(
        executable,
        command.arguments,
        request.connection,
        events,
      );
      return;
    }

    final executable = await _requireTool(DatabaseTool.psql);
    final maintenance = request.database == 'postgres'
        ? 'template1'
        : 'postgres';
    final quoted = _postgresIdentifier(request.database);
    final connectionArguments = [
      '--host=${request.connection.host}',
      '--port=${request.connection.port}',
      if (request.connection.user.isNotEmpty)
        '--username=${request.connection.user}',
      '--dbname=$maintenance',
      '--no-psqlrc',
    ];
    final metadata = await _capture(executable, [
      ...connectionArguments,
      '--tuples-only',
      '--no-align',
      '--field-separator=\t',
      '--command=SELECT pg_encoding_to_char(encoding), datcollate, datctype, pg_get_userbyid(datdba) FROM pg_database WHERE datname = ${_sqlLiteral(request.database)};',
    ], request.connection);
    final properties = metadata.trim().split('\t');
    final createOptions = properties.length >= 4
        ? ' WITH OWNER=${_postgresIdentifier(properties[3])}'
              ' ENCODING=${_sqlLiteral(properties[0])}'
              ' LC_COLLATE=${_sqlLiteral(properties[1])}'
              ' LC_CTYPE=${_sqlLiteral(properties[2])}'
              ' TEMPLATE=template0'
        : '';
    final commonArguments = [...connectionArguments, '--set=ON_ERROR_STOP=on'];
    await _executeSimple(
      executable,
      [
        ...commonArguments,
        '--command=DROP DATABASE IF EXISTS $quoted WITH (FORCE);',
      ],
      request.connection,
      events,
    );
    await _executeSimple(
      executable,
      [...commonArguments, '--command=CREATE DATABASE $quoted$createOptions;'],
      request.connection,
      events,
    );
  }

  Future<String> _capture(
    String executable,
    List<String> arguments,
    Connection connection,
  ) async {
    final result = await Process.run(
      executable,
      arguments,
      environment: _environmentFor(connection),
      includeParentEnvironment: true,
      runInShell: false,
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        executable,
        const [],
        result.stderr.toString().trim(),
        result.exitCode,
      );
    }
    return result.stdout.toString();
  }

  Future<void> _executeSimple(
    String executable,
    List<String> arguments,
    Connection connection,
    StreamController<DatabaseTransferEvent> events,
  ) async {
    final process = await Process.start(
      executable,
      arguments,
      environment: _environmentFor(connection),
      includeParentEnvironment: true,
      runInShell: false,
    );
    _process = process;
    final output = _forwardLines(process.stdout, events);
    final errors = _forwardLines(process.stderr, events);
    final exitCode = await process.exitCode;
    await Future.wait([output, errors]);
    _process = null;
    if (_cancelRequested) throw const _TransferCancelled();
    if (exitCode != 0) {
      throw ProcessException(
        executable,
        const [],
        'Exited with code $exitCode',
        exitCode,
      );
    }
  }

  Future<void> _validateImport(
    DatabaseTransferRequest request,
    StreamController<DatabaseTransferEvent> events,
  ) async {
    final file = File(request.path);
    if (!await file.exists()) {
      throw StateError('The selected file does not exist');
    }
    final header = await file
        .openRead(0, min(16, await file.length()))
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    final isGzip = header.length >= 2 && header[0] == 0x1f && header[1] == 0x8b;
    if (request.path.toLowerCase().endsWith('.gz') && !isGzip) {
      throw const FormatException(
        'The file has a .gz extension but is not gzip data',
      );
    }
    if (request.format == DatabaseTransferFormat.sqliteDatabase) {
      final signature = ascii.decode(
        header.take(16).toList(),
        allowInvalid: true,
      );
      if (signature != 'SQLite format 3\u0000') {
        throw const FormatException(
          'The selected file is not a SQLite database',
        );
      }
    }
    if (request.format == DatabaseTransferFormat.postgresCustom ||
        request.format == DatabaseTransferFormat.postgresTar) {
      final executable = await _requireTool(DatabaseTool.pgRestore);
      final result = await Process.run(executable, ['--list', request.path]);
      if (result.exitCode != 0) {
        throw const FormatException(
          'The selected file is not a PostgreSQL archive',
        );
      }
      events.add(const DatabaseTransferLog('PostgreSQL archive validated'));
    }
  }

  Future<void> _validateSqliteDatabase(
    String path,
    StreamController<DatabaseTransferEvent> events,
  ) async {
    final executable = await _requireTool(DatabaseTool.sqlite3);
    final result = await Process.run(executable, [path, 'PRAGMA quick_check;']);
    if (result.exitCode != 0 || result.stdout.toString().trim() != 'ok') {
      throw const FormatException('SQLite integrity check failed');
    }
    events.add(const DatabaseTransferLog('SQLite integrity check passed'));
  }

  Future<void> _validateSqliteDataOnlySupport() async {
    final executable = await _requireTool(DatabaseTool.sqlite3);
    final result = await Process.run(executable, [':memory:', '.help dump']);
    if (result.exitCode != 0 ||
        !result.stdout.toString().contains('--data-only')) {
      throw StateError(
        'The installed SQLite CLI does not support data-only dumps',
      );
    }
  }

  Future<String> _requireTool(DatabaseTool tool) async {
    final status = await _tools.inspect(tool);
    if (!status.isAvailable) {
      throw StateError('${tool.label} is unavailable: ${status.error}');
    }
    return status.path!;
  }

  Future<String> _createMySqlDefaultsFile(Connection connection) async {
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    final file = File(
      p.join(Directory.systemTemp.path, 'querypod_mysql_$random.cnf'),
    );
    final sslMode = connection.useTls ? 'REQUIRED' : 'DISABLED';
    await file.writeAsString('''[client]
host=${_mysqlOptionValue(connection.host)}
port=${connection.port}
user=${_mysqlOptionValue(connection.user)}
password=${_mysqlOptionValue(connection.password)}
ssl-mode=$sslMode
''', flush: true);
    if (!Platform.isWindows) {
      final result = await Process.run('chmod', ['600', file.path]);
      if (result.exitCode != 0) {
        await file.delete();
        throw StateError('Could not secure the temporary MySQL credentials');
      }
    }
    return file.path;
  }

  Map<String, String> _environmentFor(Connection connection) {
    if (connection.type != ConnectionType.postgresql) return const {};
    return {
      'PGPASSWORD': connection.password,
      'PGSSLMODE': connection.useTls ? 'require' : 'disable',
    };
  }

  Future<void> _forwardLines(
    Stream<List<int>> stream,
    StreamController<DatabaseTransferEvent> events,
  ) async {
    await for (final line
        in stream.transform(utf8.decoder).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) events.add(DatabaseTransferLog(trimmed));
    }
  }

  Future<void> _replaceFile(String source, String destination) async {
    if (p.equals(source, destination)) return;
    final backup = '$destination.querypod-previous';
    await _deleteIfExists(backup);
    final destinationFile = File(destination);
    if (await destinationFile.exists()) await destinationFile.rename(backup);
    try {
      await File(source).rename(destination);
      await _deleteIfExists(backup);
    } catch (_) {
      if (await File(backup).exists()) await File(backup).rename(destination);
      rethrow;
    }
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  String _temporarySibling(String path) =>
      '$path.querypod-part-${DateTime.now().microsecondsSinceEpoch}';

  String _mysqlIdentifier(String value) => '`${value.replaceAll('`', '``')}`';
  String _postgresIdentifier(String value) =>
      '"${value.replaceAll('"', '""')}"';
  String _sqlLiteral(String value) => "'${value.replaceAll("'", "''")}'";
  String _mysqlOptionValue(String value) =>
      '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"').replaceAll('\n', r'\n').replaceAll('\r', r'\r')}"';

  void _validateRequest(DatabaseTransferRequest request) {
    if (request.path.trim().isEmpty) {
      throw ArgumentError('A file path is required');
    }
    if (request.database.trim().isEmpty) {
      throw ArgumentError('A target database is required');
    }
    if (request.format == DatabaseTransferFormat.sqliteDatabase &&
        request.direction == DatabaseTransferDirection.import &&
        request.restoreMode != DatabaseRestoreMode.clean) {
      throw ArgumentError('SQLite database files can only replace the target');
    }
    if (request.gzip && !request.format.isPlainSql) {
      throw ArgumentError('Only plain SQL files can use gzip compression');
    }
  }

  String _friendlyError(Object error) {
    if (error is ProcessException) {
      return error.message.isEmpty
          ? '${p.basename(error.executable)} failed'
          : error.message;
    }
    return error.toString().replaceFirst(
      RegExp(r'^(Exception|Bad state):\s*'),
      '',
    );
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    _process?.kill();
  }
}

class _TransferCancelled implements Exception {
  const _TransferCancelled();
}
