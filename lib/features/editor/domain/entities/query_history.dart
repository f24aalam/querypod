import 'package:equatable/equatable.dart';

class QueryHistory extends Equatable {
  final String id;
  final String connectionId;
  final String sourceType;
  final String? sourceId;
  final String sql;
  final int executionTimeMs;
  final String status;
  final String? errorMessage;
  final DateTime createdAt;

  const QueryHistory({
    required this.id,
    required this.connectionId,
    required this.sourceType,
    this.sourceId,
    required this.sql,
    required this.executionTimeMs,
    required this.status,
    this.errorMessage,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    connectionId,
    sourceType,
    sourceId,
    sql,
    executionTimeMs,
    status,
    errorMessage,
    createdAt,
  ];
}
