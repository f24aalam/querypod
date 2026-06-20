import '../../domain/entities/workspace_database.dart';
import '../../domain/entities/workspace_table.dart';

enum WorkspaceMetadataStatus { idle, loadingDatabases, loadingTables, error }

class WorkspaceMetadataState {
  final String? connectionId;
  final List<WorkspaceDatabase> databases;
  final String? selectedDatabase;
  final List<WorkspaceTable> tables;
  final List<WorkspaceTable> filteredTables;
  final WorkspaceTable? selectedTable;
  final String query;
  final WorkspaceMetadataStatus status;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackNonce;

  const WorkspaceMetadataState({
    this.connectionId,
    this.databases = const [],
    this.selectedDatabase,
    this.tables = const [],
    this.filteredTables = const [],
    this.selectedTable,
    this.query = '',
    this.status = WorkspaceMetadataStatus.idle,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackNonce = 0,
  });

  WorkspaceMetadataState copyWith({
    String? Function()? connectionId,
    List<WorkspaceDatabase>? databases,
    String? Function()? selectedDatabase,
    List<WorkspaceTable>? tables,
    List<WorkspaceTable>? filteredTables,
    WorkspaceTable? Function()? selectedTable,
    String? query,
    WorkspaceMetadataStatus? status,
    String? Function()? feedbackMessage,
    bool? feedbackIsError,
    int? feedbackNonce,
  }) {
    return WorkspaceMetadataState(
      connectionId: connectionId != null ? connectionId() : this.connectionId,
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
      status == WorkspaceMetadataStatus.loadingDatabases;

  bool get isLoadingTables => status == WorkspaceMetadataStatus.loadingTables;
}
