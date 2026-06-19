import 'package:go_router/go_router.dart';

import '../features/connections/presentation/pages/connections_page.dart';
import '../features/workspace/presentation/pages/workspace_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ConnectionsPage()),
    GoRoute(
      path: '/workspace',
      builder: (context, state) => const WorkspacePage(),
    ),
  ],
);
