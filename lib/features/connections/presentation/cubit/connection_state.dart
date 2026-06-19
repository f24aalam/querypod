import '../../domain/entities/connection.dart';

enum ConnectionStatus { idle, loading, saving, testing, error }

class ConnectionsState {
  final List<Connection> connections;
  final List<Connection> filteredConnections;
  final String query;
  final String? selectedId;
  final ConnectionStatus status;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackNonce;

  const ConnectionsState({
    this.connections = const [],
    this.filteredConnections = const [],
    this.query = '',
    this.selectedId,
    this.status = ConnectionStatus.idle,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackNonce = 0,
  });

  ConnectionsState copyWith({
    List<Connection>? connections,
    List<Connection>? filteredConnections,
    String? query,
    String? Function()? selectedId,
    ConnectionStatus? status,
    String? Function()? feedbackMessage,
    bool? feedbackIsError,
    int? feedbackNonce,
  }) {
    return ConnectionsState(
      connections: connections ?? this.connections,
      filteredConnections: filteredConnections ?? this.filteredConnections,
      query: query ?? this.query,
      selectedId: selectedId != null ? selectedId() : this.selectedId,
      status: status ?? this.status,
      feedbackMessage: feedbackMessage != null
          ? feedbackMessage()
          : this.feedbackMessage,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackNonce: feedbackNonce ?? this.feedbackNonce,
    );
  }

  Connection? get selectedConnection => selectedId != null
      ? connections.where((c) => c.id == selectedId).firstOrNull
      : null;
}
