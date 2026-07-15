import '../../domain/database_transfer.dart';

enum DatabaseTransferStatus { idle, running, success, failure, cancelled }

class DatabaseTransferState {
  final DatabaseTransferStatus status;
  final String phase;
  final List<String> logs;
  final Duration? duration;
  final int? bytes;
  final String? error;

  const DatabaseTransferState({
    this.status = DatabaseTransferStatus.idle,
    this.phase = '',
    this.logs = const [],
    this.duration,
    this.bytes,
    this.error,
  });

  bool get isRunning => status == DatabaseTransferStatus.running;
  bool get isTerminal => switch (status) {
    DatabaseTransferStatus.success ||
    DatabaseTransferStatus.failure ||
    DatabaseTransferStatus.cancelled => true,
    _ => false,
  };

  DatabaseTransferState apply(DatabaseTransferEvent event) {
    if (event is DatabaseTransferLog) {
      final nextLogs = [...logs, event.message];
      return DatabaseTransferState(
        status: DatabaseTransferStatus.running,
        phase: phase,
        logs: nextLogs.length > 500
            ? nextLogs.sublist(nextLogs.length - 500)
            : nextLogs,
      );
    }
    return switch (event) {
      DatabaseTransferStarted(:final phase) => DatabaseTransferState(
        status: DatabaseTransferStatus.running,
        phase: phase,
        logs: logs,
      ),
      DatabaseTransferLog() => throw StateError('Handled above'),
      DatabaseTransferCompleted(:final duration, :final bytes) =>
        DatabaseTransferState(
          status: DatabaseTransferStatus.success,
          phase: 'Completed',
          logs: logs,
          duration: duration,
          bytes: bytes,
        ),
      DatabaseTransferFailed(:final message) => DatabaseTransferState(
        status: DatabaseTransferStatus.failure,
        phase: 'Failed',
        logs: logs,
        error: message,
      ),
      DatabaseTransferCancelled() => DatabaseTransferState(
        status: DatabaseTransferStatus.cancelled,
        phase: 'Cancelled',
        logs: logs,
      ),
    };
  }
}
