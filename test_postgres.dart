import 'package:postgres/postgres.dart';

void main() {
  print(Sql.named('SELECT * FROM users WHERE id = @id').runtimeType);
}
