import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/connection.dart';
import '../../domain/repositories/connection_repository.dart';
import 'connection_state.dart';

class ConnectionCubit extends Cubit<ConnectionsState> {
  final ConnectionRepository _repository;

  ConnectionCubit({required this._repository})
      : super(const ConnectionsState());

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
        state.copyWith(
          selectedId: () => connection.id,
          status: ConnectionStatus.idle,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ConnectionStatus.error));
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
    emit(state.copyWith(selectedId: () => id, testResult: () => null));
  }

  void test(Connection connection) {
    emit(
      state.copyWith(
        status: ConnectionStatus.testing,
        testResult: () => null,
      ),
    );

    if (connection.name.isEmpty) {
      emit(
        state.copyWith(
          status: ConnectionStatus.idle,
          testResult: () => 'Name is required',
        ),
      );
      return;
    }
    if (connection.host.isEmpty) {
      emit(
        state.copyWith(
          status: ConnectionStatus.idle,
          testResult: () => 'Host is required',
        ),
      );
      return;
    }
    if (connection.port <= 0) {
      emit(
        state.copyWith(
          status: ConnectionStatus.idle,
          testResult: () => 'Port is required',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ConnectionStatus.idle,
        testResult: () => 'Validation passed',
      ),
    );
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
