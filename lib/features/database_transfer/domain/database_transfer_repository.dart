import 'database_transfer.dart';

abstract class DatabaseTransferRepository {
  Stream<DatabaseTransferEvent> run(DatabaseTransferRequest request);
  Future<void> cancel();
}
