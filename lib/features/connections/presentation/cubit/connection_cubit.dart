// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/database/database_driver_factory.dart';

import '../../domain/entities/connection.dart';
import '../../domain/repositories/connection_repository.dart';
import 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionsState> {
  ConnectionCubit({required ConnectionRepository repository})
    : _repository = repository,
      super(const ConnectionsState());

  final ConnectionRepository _repository;

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
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> load() async {
    emit(state.copyWith(status: ConnectionStatus.loading));
    try {
      final allConnections = await _repository.getAll();
      final connections = state.activeWorkspaceId != null
          ? allConnections
                .where((c) => c.workspaceId == state.activeWorkspaceId)
                .toList()
          : allConnections;

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

  Future<bool> save(Connection connection) async {
    emit(state.copyWith(status: ConnectionStatus.saving));
    try {
      final connectionToSave = state.activeWorkspaceId != null
          ? connection.copyWith(workspaceId: state.activeWorkspaceId)
          : connection;
      await _repository.save(connectionToSave);
      await _repository.setSelectedId(connectionToSave.id);
      await load();
      emit(
        _feedback('Connection saved', isError: false).copyWith(
          selectedId: () => connectionToSave.id,
          activeConnection: () => connectionToSave,
        ),
      );
      return true;
    } catch (e) {
      emit(
        _feedback(
          'Failed to save connection',
          isError: true,
          status: ConnectionStatus.error,
        ),
      );
      return false;
    }
  }

  Future<void> delete(String id) async {
    try {
      final shouldClearActive =
          state.selectedId == id || state.activeConnection?.id == id;
      await _repository.delete(id);
      if (state.selectedId == id) {
        await _repository.setSelectedId(null);
      }
      if (shouldClearActive) {
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
    emit(state.copyWith(selectedId: () => id));
  }

  Future<void> setWorkspace(String? workspaceId) async {
    emit(state.copyWith(activeWorkspaceId: workspaceId));
    await load();
  }

  Future<void> openSavedConnection(String id) async {
    await _repository.setSelectedId(id);
    final selectedConnection = state.connections
        .where((c) => c.id == id)
        .firstOrNull;
    emit(
      state.copyWith(
        selectedId: () => id,
        activeConnection: () => selectedConnection ?? state.activeConnection,
        openConnectionNonce: state.openConnectionNonce + 1,
      ),
    );
  }

  Future<void> test(Connection connection) async {
    emit(state.copyWith(status: ConnectionStatus.testing));

    if (connection.name.isEmpty) {
      emit(_feedback('Name is required', isError: true));
      return;
    }

    if (connection.type == ConnectionType.mysql) {
      if (connection.host.isEmpty) {
        emit(_feedback('Host is required', isError: true));
        return;
      }
      if (connection.port <= 0) {
        emit(_feedback('Port is required', isError: true));
        return;
      }
    } else if (connection.type == ConnectionType.sqlite) {
      if (connection.database.isEmpty) {
        emit(_feedback('Database File Path is required', isError: true));
        return;
      }
    }

    try {
      final driver = DatabaseDriverFactory.getDriver(connection.type);
      await driver.testConnection(connection);

      emit(_feedback('Connection successful', isError: false));
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
