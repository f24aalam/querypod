import 'package:flutter_test/flutter_test.dart';
import 'package:querypod/app/theme_cubit.dart';

import 'support/persistence_test_support.dart';

void main() {
  test('setScheme persists the selected accent color', () async {
    final database = createTestDatabase();
    final cubit = ThemeCubit(database: database);

    try {
      await cubit.setScheme(AppColorScheme.green);

      expect(cubit.state.scheme, AppColorScheme.green);
      expect(await database.loadAccentColorScheme(), 'green');
    } finally {
      await cubit.close();
      await database.close();
    }
  });

  test('persisted accent parser falls back to blue for invalid values', () {
    expect(
      AppColorScheme.fromPersistedName('not-a-scheme'),
      AppColorScheme.blue,
    );
  });
}
