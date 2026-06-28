import '../../domain/entities/connection_database.dart';
import '../../domain/entities/connection_table.dart';
import '../../../connections/domain/entities/connection.dart';

enum ConnectionMetadataStatus { idle, loadingDatabases, loadingTables, error }

class ConnectionMetadataState {
  final String? connectionId;
  final ConnectionSessionIdentity? connectionSession;
  final List<ConnectionDatabase> databases;
  final String? selectedDatabase;
  final List<ConnectionTable> tables;
  final List<ConnectionTable> filteredTables;
  final ConnectionTable? selectedTable;
  final String query;
  final ConnectionMetadataStatus status;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackNonce;

  const ConnectionMetadataState({
    this.connectionId,
    this.connectionSession,
    this.databases = const [],
    this.selectedDatabase,
    this.tables = const [],
    this.filteredTables = const [],
    this.selectedTable,
    this.query = '',
    this.status = ConnectionMetadataStatus.idle,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackNonce = 0,
  });

  ConnectionMetadataState copyWith({
    String? Function()? connectionId,
    ConnectionSessionIdentity? Function()? connectionSession,
    List<ConnectionDatabase>? databases,
    String? Function()? selectedDatabase,
    List<ConnectionTable>? tables,
    List<ConnectionTable>? filteredTables,
    ConnectionTable? Function()? selectedTable,
    String? query,
    ConnectionMetadataStatus? status,
    String? Function()? feedbackMessage,
    bool? feedbackIsError,
    int? feedbackNonce,
  }) {
    return ConnectionMetadataState(
      connectionId: connectionId != null ? connectionId() : this.connectionId,
      connectionSession: connectionSession != null
          ? connectionSession()
          : this.connectionSession,
      databases: databases ?? this.databases,
      selectedDatabase: selectedDatabase != null
          ? selectedDatabase()
          : this.selectedDatabase,
      tables: tables ?? this.tables,
      filteredTables: filteredTables ?? this.filteredTables,
      selectedTable: selectedTable != null
          ? selectedTable()
          : this.selectedTable,
      query: query ?? this.query,
      status: status ?? this.status,
      feedbackMessage: feedbackMessage != null
          ? feedbackMessage()
          : this.feedbackMessage,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackNonce: feedbackNonce ?? this.feedbackNonce,
    );
  }

  bool get isLoadingDatabases =>
      status == ConnectionMetadataStatus.loadingDatabases;

  bool get isLoadingTables => status == ConnectionMetadataStatus.loadingTables;
}
