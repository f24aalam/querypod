import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const App());
}
