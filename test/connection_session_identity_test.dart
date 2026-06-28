import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';

void main() {
  const connection = Connection(
    id: 'connection',
    name: 'Original',
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: '',
    database: 'app',
    workspaceId: 'default',
  );

  test('name-only changes preserve connection session identity', () {
    expect(
      connection.copyWith(name: 'Renamed').sessionIdentity,
      connection.sessionIdentity,
    );
  });

  test('connectivity changes create a new session identity', () {
    expect(
      connection.copyWith(host: '127.0.0.1').sessionIdentity,
      isNot(connection.sessionIdentity),
    );
    expect(
      connection.copyWith(database: 'other').sessionIdentity,
      isNot(connection.sessionIdentity),
    );
    expect(
      connection.copyWith(useTls: false).sessionIdentity,
      isNot(connection.sessionIdentity),
    );
  });
}
