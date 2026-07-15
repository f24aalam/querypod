// ignore_for_file: prefer_initializing_formals

import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../app/database.dart';
import '../domain/database_tool.dart';
import '../domain/database_tool_repository.dart';

class DatabaseToolRepositoryImpl implements DatabaseToolRepository {
  final QueryPodDatabase _database;

  DatabaseToolRepositoryImpl({required QueryPodDatabase database})
    : _database = database;

  @override
  Future<String?> getOverride(DatabaseTool tool) async {
    final row = await (_database.select(
      _database.appSettings,
    )..where((row) => row.key.equals(tool.settingsKey))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> setOverride(DatabaseTool tool, String? path) async {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) {
      await (_database.delete(
        _database.appSettings,
      )..where((row) => row.key.equals(tool.settingsKey))).go();
      return;
    }
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: tool.settingsKey, value: normalized),
        );
  }

  @override
  Future<DatabaseToolStatus> inspect(DatabaseTool tool) async {
    final override = await getOverride(tool);
    final executable = override ?? _findExecutable(tool.executableName);
    if (executable == null) {
      return DatabaseToolStatus(
        tool: tool,
        error: '${tool.executableName} was not found',
      );
    }
    if (override != null && !File(executable).existsSync()) {
      return DatabaseToolStatus(
        tool: tool,
        path: executable,
        error: 'Configured file does not exist',
        isOverride: true,
      );
    }

    try {
      final result = await Process.run(executable, const ['--version']);
      if (result.exitCode != 0) {
        return DatabaseToolStatus(
          tool: tool,
          path: executable,
          error: _firstLine(result.stderr.toString(), 'Validation failed'),
          isOverride: override != null,
        );
      }
      return DatabaseToolStatus(
        tool: tool,
        path: executable,
        version: _firstLine(result.stdout.toString(), 'Available'),
        isOverride: override != null,
      );
    } catch (error) {
      return DatabaseToolStatus(
        tool: tool,
        path: executable,
        error: error.toString(),
        isOverride: override != null,
      );
    }
  }

  @override
  Future<Map<DatabaseTool, DatabaseToolStatus>> inspectAll() async {
    final entries = await Future.wait(
      DatabaseTool.values.map(
        (tool) async => MapEntry(tool, await inspect(tool)),
      ),
    );
    return Map.fromEntries(entries);
  }

  String? _findExecutable(String name) {
    final candidates = <String>[];
    final executableName = Platform.isWindows ? '$name.exe' : name;
    for (final directory in (Platform.environment['PATH'] ?? '').split(
      Platform.isWindows ? ';' : ':',
    )) {
      if (directory.isNotEmpty) {
        candidates.add(p.join(directory, executableName));
      }
    }
    if (Platform.isMacOS) {
      candidates.addAll([
        '/opt/homebrew/bin/$name',
        '/usr/local/bin/$name',
        '/Applications/Postgres.app/Contents/Versions/latest/bin/$name',
      ]);
    } else if (Platform.isLinux) {
      candidates.addAll([
        '/usr/bin/$name',
        '/usr/local/bin/$name',
        '/snap/bin/$name',
      ]);
    } else if (Platform.isWindows) {
      for (final root in [
        Platform.environment['ProgramFiles'],
        Platform.environment['ProgramFiles(x86)'],
      ].whereType<String>()) {
        candidates.addAll([
          p.join(root, 'PostgreSQL', 'bin', executableName),
          p.join(root, 'MySQL', 'MySQL Server 8.0', 'bin', executableName),
          p.join(root, 'SQLite', executableName),
        ]);
      }
    }
    return candidates
        .where((candidate) => File(candidate).existsSync())
        .firstOrNull;
  }

  String _firstLine(String value, String fallback) {
    final line = value.trim().split(RegExp(r'[\r\n]')).firstOrNull;
    return line == null || line.isEmpty ? fallback : line;
  }
}
