import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/pinned_tables_repository.dart';

class PinnedTablesRepositoryImpl implements PinnedTablesRepository {
  static const _pinnedTablesKey = 'querypod_pinned_tables';

  final SharedPreferences _prefs;
  final String _storageKey;

  PinnedTablesRepositoryImpl(this._prefs, {String keyNamespace = ''})
    : _storageKey = _withNamespace(_pinnedTablesKey, keyNamespace);

  static String _withNamespace(String key, String namespace) {
    final normalized = namespace.trim();
    if (normalized.isEmpty) return key;
    return '${normalized}_$key';
  }

  @override
  Future<List<String>> getPinnedTables({
    required String connectionId,
    required String database,
  }) async {
    final data = _read();
    final connectionPins = data[connectionId];
    if (connectionPins is! Map<String, dynamic>) return [];

    final databasePins = connectionPins[database];
    if (databasePins is! List) return [];

    return databasePins.whereType<String>().toList();
  }

  @override
  Future<void> setPinnedTables({
    required String connectionId,
    required String database,
    required List<String> tableNames,
  }) async {
    final data = _read();
    final connectionPins = Map<String, dynamic>.from(
      (data[connectionId] as Map?) ?? const <String, dynamic>{},
    );

    if (tableNames.isEmpty) {
      connectionPins.remove(database);
    } else {
      connectionPins[database] = List<String>.unmodifiable(tableNames);
    }

    if (connectionPins.isEmpty) {
      data.remove(connectionId);
    } else {
      data[connectionId] = connectionPins;
    }

    if (data.isEmpty) {
      await _prefs.remove(_storageKey);
      return;
    }

    await _prefs.setString(_storageKey, jsonEncode(data));
  }

  Map<String, dynamic> _read() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return <String, dynamic>{};
    return Map<String, dynamic>.from(decoded);
  }
}
