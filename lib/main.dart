import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const App());
}
