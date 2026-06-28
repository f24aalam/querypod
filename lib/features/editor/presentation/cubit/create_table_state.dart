import 'package:equatable/equatable.dart';
import '../../domain/entities/table_data.dart';

class CreateTableState extends Equatable {
  final String tableName;
  final String? originalTableName;
  final List<TableColumnDefinition> columns;
  final List<TableColumnDefinition>? originalColumns;
  final bool isSubmitting;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const CreateTableState({
    this.tableName = '',
    this.originalTableName,
    this.columns = const [],
    this.originalColumns,
    this.isSubmitting = false,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  CreateTableState copyWith({
    String? tableName,
    String? originalTableName,
    List<TableColumnDefinition>? columns,
    List<TableColumnDefinition>? originalColumns,
    bool? isSubmitting,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return CreateTableState(
      tableName: tableName ?? this.tableName,
      originalTableName: originalTableName ?? this.originalTableName,
      columns: columns ?? this.columns,
      originalColumns: originalColumns ?? this.originalColumns,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        tableName,
        originalTableName,
        columns,
        originalColumns,
        isSubmitting,
        isLoading,
        errorMessage,
        isSuccess,
      ];
}
