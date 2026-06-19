import 'package:flutter_bloc/flutter_bloc.dart';

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

  Future<void> load() async {
    emit(state.copyWith(status: ConnectionStatus.loading));
    try {
      final connections = await _repository.getAll();
      emit(
        state.copyWith(
          connections: connections,
          filteredConnections: _filter(connections, state.query),
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
      await load();
      emit(
        _feedback(
          'Connection saved',
          isError: false,
        ).copyWith(selectedId: () => connection.id),
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
        emit(state.copyWith(selectedId: () => null));
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

  void select(String? id) {
    emit(state.copyWith(selectedId: () => id));
  }

  void test(Connection connection) {
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

    emit(_feedback('Connection looks valid', isError: false));
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
