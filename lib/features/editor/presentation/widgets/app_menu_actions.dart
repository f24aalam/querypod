import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

class AppMenuActions {
  static void quit() {
    SystemNavigator.pop();
    if (!kIsWeb &&
        (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      exit(0);
    }
  }

  static void changeWorkspace(BuildContext context) {
    context.go('/');
  }
}
