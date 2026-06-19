import 'package:go_router/go_router.dart';

import '../features/connections/connections_page.dart';
import '../features/workspace/workspace_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ConnectionsPage()),
    GoRoute(
      path: '/workspace',
      builder: (context, state) => const WorkspacePage(),
    ),
  ],
);
