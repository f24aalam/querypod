import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mysql_client_plus/exception.dart';
import 'package:mysql_client_plus/mysql_client_plus.dart';

import '../../domain/entities/connection.dart';
import '../../domain/repositories/connection_repository.dart';
import 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionsState> {
  final ConnectionRepository _repository;

  ConnectionCubit({required this._repository})
    : super(const ConnectionsState());

  ConnectionsState _feedback(
    String message, {
    required bool isError,
    ConnectionStatus status = ConnectionStatus.idle,
  }) {
    return state.copyWith(
      status: status,
      feedbackMessage: () => message,
      feedbackIsError: isError,
      feedbackNonce: state.feedbackNonce + 1,
    );
  }

  String _connectionErrorMessage(Object error, Connection connection) {
    if (error is MySQLException) {
      final base = error.message.isNotEmpty
          ? error.message
          : 'MySQL client returned an error';
      return 'Failed to connect: $base';
    }

    final message = error.toString();
    final localhostHint =
        (connection.host == '127.0.0.1' || connection.host == 'localhost') &&
        (message.contains('Connection refused') ||
            message.contains('No route to host') ||
            message.contains('OS Error'));

    if (localhostHint) {
      return 'Failed to connect: $message. If this app is running on a simulator/device, 127.0.0.1 points to the device, not your computer.';
    }

    return 'Failed to connect: $message';
  }

  Future<void> load() async {
    emit(state.copyWith(status: ConnectionStatus.loading));
    try {
      final connections = await _repository.getAll();
      final persistedSelectedId = await _repository.getSelectedId();
      final selectedId = connections.any((c) => c.id == persistedSelectedId)
          ? persistedSelectedId
          : null;

      if (persistedSelectedId != null && selectedId == null) {
        await _repository.setSelectedId(null);
      }

      emit(
        state.copyWith(
          connections: connections,
          filteredConnections: _filter(connections, state.query),
          selectedId: () => selectedId,
          activeConnection: () => selectedId != null
              ? connections.where((c) => c.id == selectedId).firstOrNull
              : state.activeConnection,
          status: ConnectionStatus.idle,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ConnectionStatus.error));
    }
  }

  Future<void> save(Connection connection) async {
    emit(state.copyWith(status: ConnectionStatus.saving));
    try {
      await _repository.save(connection);
      await _repository.setSelectedId(connection.id);
      await load();
      emit(
        _feedback('Connection saved', isError: false).copyWith(
          selectedId: () => connection.id,
          activeConnection: () => connection,
        ),
      );
    } catch (e) {
      emit(
        _feedback(
          'Failed to save connection',
          isError: true,
          status: ConnectionStatus.error,
        ),
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
      if (state.selectedId == id) {
        await _repository.setSelectedId(null);
        emit(
          state.copyWith(selectedId: () => null, activeConnection: () => null),
        );
      }
      await load();
    } catch (e) {
      emit(state.copyWith(status: ConnectionStatus.error));
    }
  }

  void search(String query) {
    final filtered = _filter(state.connections, query);
    emit(state.copyWith(query: query, filteredConnections: filtered));
  }

  Future<void> select(String? id) async {
    await _repository.setSelectedId(id);
    final selectedConnection = id == null
        ? null
        : state.connections.where((c) => c.id == id).firstOrNull;
    emit(
      state.copyWith(
        selectedId: () => id,
        activeConnection: () => selectedConnection ?? state.activeConnection,
      ),
    );
  }

  Future<void> test(Connection connection) async {
    emit(state.copyWith(status: ConnectionStatus.testing));

    if (connection.name.isEmpty) {
      emit(_feedback('Name is required', isError: true));
      return;
    }
    if (connection.host.isEmpty) {
      emit(_feedback('Host is required', isError: true));
      return;
    }
    if (connection.port <= 0) {
      emit(_feedback('Port is required', isError: true));
      return;
    }

    try {
      final conn = await MySQLConnection.createConnection(
        host: connection.host,
        port: connection.port,
        userName: connection.user,
        password: connection.password,
        databaseName: connection.database.isEmpty ? null : connection.database,
        secure: false,
      );
      await conn.connect();
      await conn.execute('SELECT 1');
      await conn.close();

      emit(
        _feedback('Connection successful', isError: false).copyWith(
          activeConnection: () => connection,
          openWorkspaceNonce: state.openWorkspaceNonce + 1,
        ),
      );
    } catch (e) {
      emit(
        _feedback(
          _connectionErrorMessage(e, connection),
          isError: true,
          status: ConnectionStatus.error,
        ),
      );
    }
  }

  List<Connection> _filter(List<Connection> connections, String query) {
    if (query.isEmpty) return List.from(connections);
    final q = query.toLowerCase();
    return connections
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.host.toLowerCase().contains(q),
        )
        .toList();
  }
}
