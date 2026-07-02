import 'package:integration_test/integration_test.dart';

import 'support/db_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  defineRepositoryIntegrationSuite(TestDatabaseEngine.mysql);
  defineRepositoryIntegrationSuite(TestDatabaseEngine.postgres);
  defineRepositoryIntegrationSuite(TestDatabaseEngine.sqlite);
}
