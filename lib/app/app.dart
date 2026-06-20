import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import '../features/connections/presentation/cubit/connection_cubit.dart';
import '../features/workspace/presentation/cubit/workspace_metadata_cubit.dart';
import 'injection.dart';
import 'router.dart';
import 'theme.dart';
import 'theme_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => getIt<ConnectionCubit>()..load()),
        BlocProvider(create: (_) => getIt<WorkspaceMetadataCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          final foruiTheme = mode == ThemeMode.dark ? darkTheme : lightTheme;
          return MaterialApp.router(
            routerConfig: router,
            theme: lightTheme.toApproximateMaterialTheme(),
            darkTheme: darkTheme.toApproximateMaterialTheme(),
            themeMode: mode,
            debugShowCheckedModeBanner: false,
            supportedLocales: FLocalizations.supportedLocales,
            localizationsDelegates: const [
              ...FLocalizations.localizationsDelegates,
            ],
            builder: (_, child) => FTheme(
              data: foruiTheme,
              child: FToaster(child: FTooltipGroup(child: child!)),
            ),
          );
        },
      ),
    );
  }
}
