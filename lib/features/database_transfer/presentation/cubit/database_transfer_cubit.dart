import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/database_transfer.dart';
import '../../domain/database_transfer_repository.dart';
import 'database_transfer_state.dart';

class DatabaseTransferCubit extends Cubit<DatabaseTransferState> {
  final DatabaseTransferRepository repository;

  DatabaseTransferCubit({required this.repository})
    : super(const DatabaseTransferState());

  Future<void> start(DatabaseTransferRequest request) async {
    if (state.isRunning) return;
    emit(
      const DatabaseTransferState(
        status: DatabaseTransferStatus.running,
        phase: 'Preparing transfer',
      ),
    );
    await for (final event in repository.run(request)) {
      emit(state.apply(event));
    }
  }

  Future<void> cancel() => repository.cancel();

  void reset() {
    if (!state.isRunning) emit(const DatabaseTransferState());
  }
}
