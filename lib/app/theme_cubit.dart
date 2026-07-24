// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forui/forui.dart';

import 'database.dart';

const int minimumZoomLevel = -2;
const int maximumZoomLevel = 3;

double scaleForZoomLevel(int level) => math.pow(1.2, level).toDouble();

int percentageForZoomLevel(int level) =>
    (scaleForZoomLevel(level) * 100).round();

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

  static AppColorScheme fromPersistedName(String? name) {
    return AppColorScheme.values.firstWhere(
      (scheme) => scheme.name == name,
      orElse: () => AppColorScheme.blue,
    );
  }
}

class ThemeState {
  final ThemeMode mode;
  final AppColorScheme scheme;
  final int zoomLevel;

  const ThemeState({
    this.mode = ThemeMode.system,
    this.scheme = AppColorScheme.blue,
    this.zoomLevel = 0,
  });

  double get zoomScale => scaleForZoomLevel(zoomLevel);
  int get zoomPercentage => percentageForZoomLevel(zoomLevel);

  ThemeState copyWith({
    ThemeMode? mode,
    AppColorScheme? scheme,
    int? zoomLevel,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      scheme: scheme ?? this.scheme,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({
    QueryPodDatabase? database,
    int initialZoomLevel = 0,
    AppColorScheme initialScheme = AppColorScheme.blue,
  }) : _database = database,
       super(
         ThemeState(
           mode: ThemeMode.dark,
           scheme: initialScheme,
           zoomLevel: initialZoomLevel
               .clamp(minimumZoomLevel, maximumZoomLevel)
               .toInt(),
         ),
       );

  final QueryPodDatabase? _database;

  void setMode(ThemeMode mode) => emit(state.copyWith(mode: mode));
  Future<void> setScheme(AppColorScheme scheme) async {
    if (scheme == state.scheme) return;

    emit(state.copyWith(scheme: scheme));
    await _database?.saveAccentColorScheme(scheme.name);
  }

  Future<void> zoomIn() => setZoomLevel(state.zoomLevel + 1);
  Future<void> zoomOut() => setZoomLevel(state.zoomLevel - 1);
  Future<void> resetZoom() => setZoomLevel(0);

  Future<void> setZoomLevel(int zoomLevel) async {
    final clamped = zoomLevel.clamp(minimumZoomLevel, maximumZoomLevel).toInt();
    if (clamped == state.zoomLevel) return;

    emit(state.copyWith(zoomLevel: clamped));
    await _database?.saveZoomLevel(clamped);
  }
}
