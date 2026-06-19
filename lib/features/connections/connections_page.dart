import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FScaffold(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QueryPod',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.colors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your database connections',
              style: TextStyle(
                fontSize: 14,
                color: theme.colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            FButton(
              onPress: () => context.go('/workspace'),
              child: const Text('Open Workspace'),
            ),
          ],
        ),
      ),
    );
  }
}
