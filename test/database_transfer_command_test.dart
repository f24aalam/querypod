import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/features/connections/domain/entities/connection.dart';
import 'package:querypod/features/database_transfer/data/database_transfer_command.dart';
import 'package:querypod/features/database_transfer/domain/database_tool.dart';
import 'package:querypod/features/database_transfer/domain/database_transfer.dart';

void main() {
  const factory = DatabaseTransferCommandFactory();

  test('MySQL full export includes consistent database objects', () {
    final command = factory.build(
      _request(
        connection: _connection(ConnectionType.mysql),
        format: DatabaseTransferFormat.mysqlSql,
      ),
      workingPath: '/tmp/output.sql',
      mysqlDefaultsPath: '/tmp/client.cnf',
    );

    expect(command.tool, DatabaseTool.mysqldump);
    expect(command.arguments.first, '--defaults-extra-file=/tmp/client.cnf');
    expect(
      command.arguments,
      containsAll([
        '--single-transaction',
        '--routines',
        '--events',
        '--triggers',
      ]),
    );
    expect(command.arguments.last, 'app');
  });

  test('MySQL schema and data exports use mutually exclusive flags', () {
    final schema = factory.build(
      _request(
        connection: _connection(ConnectionType.mysql),
        format: DatabaseTransferFormat.mysqlSql,
        content: DatabaseTransferContent.schemaOnly,
      ),
      workingPath: '/tmp/schema.sql',
      mysqlDefaultsPath: '/tmp/client.cnf',
    );
    final data = factory.build(
      _request(
        connection: _connection(ConnectionType.mysql),
        format: DatabaseTransferFormat.mysqlSql,
        content: DatabaseTransferContent.dataOnly,
      ),
      workingPath: '/tmp/data.sql',
      mysqlDefaultsPath: '/tmp/client.cnf',
    );

    expect(schema.arguments, contains('--no-data'));
    expect(schema.arguments, isNot(contains('--no-create-info')));
    expect(data.arguments, contains('--no-create-info'));
    expect(data.arguments, isNot(contains('--no-data')));
  });

  test('PostgreSQL custom export targets complete selected database', () {
    final command = factory.build(
      _request(
        connection: _connection(ConnectionType.postgresql),
        format: DatabaseTransferFormat.postgresCustom,
      ),
      workingPath: '/tmp/app.dump',
    );

    expect(command.tool, DatabaseTool.pgDump);
    expect(command.arguments, contains('--format=custom'));
    expect(command.arguments, isNot(contains('--schema=public')));
    expect(command.arguments.last, 'app');
  });

  test('PostgreSQL archives restore with pg_restore and exit on error', () {
    final command = factory.build(
      _request(
        direction: DatabaseTransferDirection.import,
        connection: _connection(ConnectionType.postgresql),
        format: DatabaseTransferFormat.postgresTar,
      ),
      workingPath: '/tmp/app.tar',
    );

    expect(command.tool, DatabaseTool.pgRestore);
    expect(command.arguments, contains('--exit-on-error'));
    expect(command.arguments, contains('--dbname=app'));
    expect(command.arguments.last, '/tmp/app.tar');
  });

  test('SQLite binary backup safely quotes output path', () {
    final command = factory.build(
      _request(
        connection: _connection(ConnectionType.sqlite),
        format: DatabaseTransferFormat.sqliteDatabase,
      ),
      workingPath: '/tmp/My Backup.sqlite',
    );

    expect(command.tool, DatabaseTool.sqlite3);
    expect(command.arguments.last, '.backup "/tmp/My Backup.sqlite"');
  });

  test('SQLite data-only SQL uses supported dump mode', () {
    final command = factory.build(
      _request(
        connection: _connection(ConnectionType.sqlite),
        format: DatabaseTransferFormat.sqliteSql,
        content: DatabaseTransferContent.dataOnly,
      ),
      workingPath: '/tmp/data.sql',
    );

    expect(command.arguments.last, '.dump --data-only --nosys');
  });
}

DatabaseTransferRequest _request({
  DatabaseTransferDirection direction = DatabaseTransferDirection.export,
  required Connection connection,
  required DatabaseTransferFormat format,
  DatabaseTransferContent content = DatabaseTransferContent.full,
}) => DatabaseTransferRequest(
  direction: direction,
  connection: connection,
  database: 'app',
  path: '/tmp/input',
  format: format,
  content: content,
);

Connection _connection(ConnectionType type) => Connection(
  id: 'connection',
  name: 'Local',
  host: 'localhost',
  port: type == ConnectionType.postgresql ? 5432 : 3306,
  user: 'user',
  password: 'secret',
  database: type == ConnectionType.sqlite ? '/tmp/source.sqlite' : 'app',
  workspaceId: 'workspace',
  type: type,
  useTls: true,
);
