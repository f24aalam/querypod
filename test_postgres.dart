import 'package:postgres/postgres.dart';

void main() {
  // ignore: avoid_print
  print(Sql.named('SELECT * FROM users WHERE id = @id').runtimeType);
}
