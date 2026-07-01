import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/connection.dart';
import '../../domain/repositories/connection_repository.dart';
import '../models/connection_model.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  static const _connectionsKey = 'querypod_connections';
  static const _passwordPrefix = 'querypod_connection_';
  static const _selectedConnectionKey = 'querypod_selected_connection_id';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  final String _connectionsStorageKey;
  final String _selectedConnectionStorageKey;
  final String _passwordStoragePrefix;

  ConnectionRepositoryImpl({
    required this._secureStorage,
    required this._prefs,
    String keyNamespace = '',
  }) : _connectionsStorageKey = _withNamespace(_connectionsKey, keyNamespace),
       _selectedConnectionStorageKey = _withNamespace(
         _selectedConnectionKey,
         keyNamespace,
       ),
       _passwordStoragePrefix = _withNamespace(_passwordPrefix, keyNamespace);

  static String _withNamespace(String key, String namespace) {
    final normalized = namespace.trim();
    if (normalized.isEmpty) return key;
    return '${normalized}_$key';
  }

  @override
  Future<List<Connection>> getAll() async {
    final jsonStr = _prefs.getString(_connectionsStorageKey);
    if (jsonStr == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    final connections = <Connection>[];

    for (final json in jsonList) {
      final connMap = json as Map<String, dynamic>;
      final id = connMap['id'] as String;
      final password = await _secureStorage.read(
        key: _passwordStoragePrefix + id,
      );
      connections.add(
        ConnectionModel.fromJson(connMap, password: password ?? ''),
      );
    }

    return connections;
  }

  @override
  Future<Connection?> getById(String id) async {
    final connections = await getAll();
    for (final connection in connections) {
      if (connection.id == id) return connection;
    }
    return null;
  }

  @override
  Future<Connection> save(Connection connection) async {
    final connections = await getAll();
    final existingIndex = connections.indexWhere((c) => c.id == connection.id);

    if (existingIndex >= 0) {
      connections[existingIndex] = connection;
    } else {
      connections.add(connection);
    }

    await _secureStorage.write(
      key: _passwordStoragePrefix + connection.id,
      value: connection.password,
    );

    final modelsJson = connections
        .map((c) => ConnectionModel.fromEntity(c).toJsonMap())
        .toList();

    await _prefs.setString(_connectionsStorageKey, jsonEncode(modelsJson));

    return connection;
  }

  @override
  Future<void> delete(String id) async {
    final connections = await getAll();
    connections.removeWhere((c) => c.id == id);

    await _secureStorage.delete(key: _passwordStoragePrefix + id);

    final modelsJson = connections
        .map((c) => ConnectionModel.fromEntity(c).toJsonMap())
        .toList();

    await _prefs.setString(_connectionsStorageKey, jsonEncode(modelsJson));
  }

  @override
  Future<String?> getSelectedId() async =>
      _prefs.getString(_selectedConnectionStorageKey);

  @override
  Future<void> setSelectedId(String? id) async {
    if (id == null) {
      await _prefs.remove(_selectedConnectionStorageKey);
      return;
    }

    await _prefs.setString(_selectedConnectionStorageKey, id);
  }
}
