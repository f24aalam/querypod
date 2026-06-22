import 'package:equatable/equatable.dart';
import '../../domain/entities/table_data.dart';

class CreateTableState extends Equatable {
  final String tableName;
  final List<TableColumnDefinition> columns;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const CreateTableState({
    this.tableName = '',
    this.columns = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  CreateTableState copyWith({
    String? tableName,
    List<TableColumnDefinition>? columns,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return CreateTableState(
      tableName: tableName ?? this.tableName,
      columns: columns ?? this.columns,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        tableName,
        columns,
        isSubmitting,
        errorMessage,
        isSuccess,
      ];
}
