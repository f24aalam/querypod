import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../features/connections/presentation/cubit/connection_cubit.dart';
import '../features/connections/presentation/cubit/connection_editor_cubit.dart';
import '../features/editor/presentation/cubit/activity_cubit.dart';
import '../features/editor/presentation/cubit/editor_tabs_cubit.dart';
import '../features/editor/presentation/cubit/query_editor_cubit.dart';
import '../features/editor/presentation/cubit/table_data_cubit.dart';
import '../features/editor/presentation/cubit/connection_metadata_cubit.dart';
import '../features/workspaces/presentation/cubit/workspaces_cubit.dart';
import 'injection.dart';
import 'router.dart';

import 'theme_cubit.dart';

class App extends StatefulWidget {
  final String initialLocation;

  const App({super.key, this.initialLocation = '/'});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => getIt<ConnectionCubit>()..load()),
        BlocProvider(create: (_) => ConnectionEditorCubit()),
        BlocProvider(create: (_) => getIt<ConnectionMetadataCubit>()),
        BlocProvider(create: (_) => ActivityCubit()),
        BlocProvider(create: (_) => EditorTabsCubit()),
        BlocProvider(create: (_) => getIt<QueryEditorCubit>()),
        BlocProvider(create: (_) => getIt<TableDataCubit>()),
        BlocProvider(create: (_) => getIt<WorkspacesCubit>()..loadWorkspaces()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final lightTheme = state.scheme.getTheme(Brightness.light);
          final darkTheme = state.scheme.getTheme(Brightness.dark);

          return MaterialApp.router(
            routerConfig: _router,
            theme: lightTheme.toApproximateMaterialTheme(),
            darkTheme: darkTheme.toApproximateMaterialTheme(),
            themeMode: state.mode,
            debugShowCheckedModeBanner: false,
            supportedLocales: FLocalizations.supportedLocales,
            localizationsDelegates: const [
              ...FLocalizations.localizationsDelegates,
            ],
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              final foruiTheme = state.scheme.getTheme(brightness);
              return FTheme(
                data: foruiTheme,
                child: FToaster(child: FTooltipGroup(child: child!)),
              );
            },
          );
        },
      ),
    );
  }
}
