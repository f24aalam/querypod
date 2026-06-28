import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

class AppMenuActions {
  static Future<void> quit() => windowManager.close();

  static void changeWorkspace(BuildContext context) {
    context.go('/');
  }
}
