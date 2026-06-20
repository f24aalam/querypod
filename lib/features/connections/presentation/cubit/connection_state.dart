import '../../domain/entities/connection.dart';

enum ConnectionStatus { idle, loading, saving, testing, error }

class ConnectionsState {
  final List<Connection> connections;
  final List<Connection> filteredConnections;
  final String query;
  final String? selectedId;
  final Connection? activeConnection;
  final ConnectionStatus status;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackNonce;
  final int selectionNonce;
  final int openWorkspaceNonce;

  const ConnectionsState({
    this.connections = const [],
    this.filteredConnections = const [],
    this.query = '',
    this.selectedId,
    this.activeConnection,
    this.status = ConnectionStatus.idle,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackNonce = 0,
    this.selectionNonce = 0,
    this.openWorkspaceNonce = 0,
  });

  ConnectionsState copyWith({
    List<Connection>? connections,
    List<Connection>? filteredConnections,
    String? query,
    String? Function()? selectedId,
    Connection? Function()? activeConnection,
    ConnectionStatus? status,
    String? Function()? feedbackMessage,
    bool? feedbackIsError,
    int? feedbackNonce,
    int? selectionNonce,
    int? openWorkspaceNonce,
  }) {
    return ConnectionsState(
      connections: connections ?? this.connections,
      filteredConnections: filteredConnections ?? this.filteredConnections,
      query: query ?? this.query,
      selectedId: selectedId != null ? selectedId() : this.selectedId,
      activeConnection: activeConnection != null
          ? activeConnection()
          : this.activeConnection,
      status: status ?? this.status,
      feedbackMessage: feedbackMessage != null
          ? feedbackMessage()
          : this.feedbackMessage,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackNonce: feedbackNonce ?? this.feedbackNonce,
      selectionNonce: selectionNonce ?? this.selectionNonce,
      openWorkspaceNonce: openWorkspaceNonce ?? this.openWorkspaceNonce,
    );
  }

  Connection? get selectedConnection => selectedId != null
      ? connections.where((c) => c.id == selectedId).firstOrNull
      : null;
}
