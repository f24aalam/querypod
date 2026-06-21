import '../../../features/connections/domain/entities/connection.dart';
import 'database_driver.dart';
import 'drivers/mysql_driver.dart';
import 'drivers/postgres_driver.dart';
import 'drivers/sqlite_driver.dart';

class DatabaseDriverFactory {
  static final _mysql = MySQLDriver();
  static final _sqlite = SQLiteDriver();
  static final _postgres = PostgresDriver();

  static DatabaseDriver getDriver(ConnectionType type) {
    switch (type) {
      case ConnectionType.mysql:
        return _mysql;
      case ConnectionType.sqlite:
        return _sqlite;
      case ConnectionType.postgresql:
        return _postgres;
    }
  }
}
