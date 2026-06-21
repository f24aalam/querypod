import 'package:mysql_client_plus/mysql_client_plus.dart';

void main() async {
  final conn = await MySQLConnection.createConnection(
    host: 'localhost',
    port: 3306,
    userName: 'root',
    password: '',
    databaseName: 'mysql',
    secure: false,
  );
  await conn.connect();
  
  final resultSets = await conn.execute(
    "SELECT 1 as val_1_1; SELECT 2 as val_2_1, 3 as val_2_2",
  );

  for (final result in resultSets) {
    print("Result set columns: \${result.cols.map((c) => c.name).toList()}");
    for (final row in result.rows) {
      print(row.assoc());
    }
  }
  
  await conn.close();
}
