import 'package:flutter/foundation.dart';

bool get isMacOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
bool get isLinux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
bool get isWindows =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
bool get isDesktop => isMacOS || isLinux || isWindows;
