import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'router.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return FTheme(
      data: theme,
      child: MaterialApp.router(routerConfig: router),
    );
  }
}
