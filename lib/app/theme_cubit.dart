import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

enum AppColorScheme {
  zinc('Zinc'),
  slate('Slate'),
  red('Red'),
  rose('Rose'),
  orange('Orange'),
  green('Green'),
  blue('Blue'),
  yellow('Yellow'),
  violet('Violet');

  final String label;
  const AppColorScheme(this.label);

  FThemeData getTheme(Brightness brightness) {
    final scheme = switch (this) {
      AppColorScheme.zinc => FThemes.zinc,
      AppColorScheme.slate => FThemes.slate,
      AppColorScheme.red => FThemes.red,
      AppColorScheme.rose => FThemes.rose,
      AppColorScheme.orange => FThemes.orange,
      AppColorScheme.green => FThemes.green,
      AppColorScheme.blue => FThemes.blue,
      AppColorScheme.yellow => FThemes.yellow,
      AppColorScheme.violet => FThemes.violet,
    };
    return brightness == Brightness.light
        ? scheme.light.desktop
        : scheme.dark.desktop;
  }
}

class ThemeState {
  final ThemeMode mode;
  final AppColorScheme scheme;

  const ThemeState({
    this.mode = ThemeMode.system,
    this.scheme = AppColorScheme.blue,
  });

  ThemeState copyWith({ThemeMode? mode, AppColorScheme? scheme}) {
    return ThemeState(mode: mode ?? this.mode, scheme: scheme ?? this.scheme);
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState(mode: ThemeMode.dark));

  void setMode(ThemeMode mode) => emit(state.copyWith(mode: mode));
  void setScheme(AppColorScheme scheme) => emit(state.copyWith(scheme: scheme));
}
