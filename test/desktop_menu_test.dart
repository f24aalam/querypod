import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:querypod/app/theme.dart' as app_theme;
import 'package:querypod/features/editor/presentation/widgets/app_menu_bar.dart';
import 'package:querypod/features/editor/presentation/widgets/app_title_bar.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  var isMaximized = false;

  setUp(() {
    calls.clear();
    isMaximized = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), (
          call,
        ) async {
          calls.add(call);
          switch (call.method) {
            case 'isMaximized':
              return isMaximized;
            case 'maximize':
              isMaximized = true;
            case 'unmaximize':
              isMaximized = false;
          }
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('window_manager'), null);
  });

  testWidgets('Windows uses custom chrome and updates maximize state', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await tester.pumpWidget(_titleBarApp());
    await tester.pump();

    expect(find.byType(MenuBar), findsOneWidget);
    expect(find.byType(DragToMoveArea), findsOneWidget);
    expect(find.byKey(const ValueKey('app-title-bar-icon')), findsOneWidget);
    expect(find.byTooltip('Minimize'), findsOneWidget);
    expect(find.byTooltip('Maximize'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);

    await tester.tap(find.byTooltip('Maximize'));
    await tester.pump();

    expect(find.byTooltip('Restore'), findsOneWidget);
    expect(calls.map((call) => call.method), contains('maximize'));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Linux uses one custom title row with menu and controls', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await tester.pumpWidget(_titleBarApp());
    await tester.pump();

    expect(find.byType(MenuBar), findsOneWidget);
    expect(find.byType(DragToMoveArea), findsOneWidget);
    expect(find.byKey(const ValueKey('app-title-bar-icon')), findsOneWidget);
    expect(find.byTooltip('Minimize'), findsOneWidget);
    expect(find.byTooltip('Maximize'), findsOneWidget);
    expect(find.byTooltip('Close'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('macOS uses a drag strip without material menu or inset', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    await tester.pumpWidget(_titleBarApp());

    expect(find.byType(MenuBar), findsNothing);
    expect(find.byType(DragToMoveArea), findsOneWidget);
    expect(find.byType(WindowCaptionButton), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 80,
      ),
      findsNothing,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('desktop Ctrl+Q closes through window manager', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    await tester.pumpWidget(
      MaterialApp(
        home: AppMenuShell(
          child: Focus(autofocus: true, child: const SizedBox.expand()),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(calls.map((call) => call.method), contains('close'));
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('macOS installs one native application menu', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    await tester.pumpWidget(
      const MaterialApp(home: AppMenuShell(child: SizedBox.expand())),
    );

    expect(find.byType(PlatformMenuBar), findsOneWidget);
    final menuBar = tester.widget<PlatformMenuBar>(
      find.byType(PlatformMenuBar),
    );
    expect(menuBar.menus, hasLength(2));
    expect((menuBar.menus.first as PlatformMenu).label, 'QueryPod');
    expect((menuBar.menus.last as PlatformMenu).label, 'Workspace');
    debugDefaultTargetPlatformOverride = null;
  });

  for (final (name, theme) in [
    ('light', app_theme.lightTheme),
    ('dark', app_theme.darkTheme),
  ]) {
    testWidgets('desktop menu uses VS Code-like chrome in $name mode', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(_titleBarApp(theme));
      await tester.pump();

      final titleBar = tester.widget<Container>(
        find.byKey(const ValueKey('app-title-bar')),
      );
      final decoration = titleBar.decoration! as BoxDecoration;
      expect(
        tester.getSize(find.byKey(const ValueKey('app-title-bar'))).height,
        30,
      );
      expect(decoration.border, isNotNull);

      final fileMenu = tester.widget<SubmenuButton>(
        find.byType(SubmenuButton).first,
      );
      expect(fileMenu.alignmentOffset, const Offset(0, -4));
      expect(fileMenu.menuStyle!.elevation!.resolve({}), 6);
      expect(
        (fileMenu.menuStyle!.shape!.resolve({})! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.zero,
      );
      expect(fileMenu.menuStyle!.backgroundColor!.resolve({}), isNotNull);
      expect(fileMenu.menuStyle!.side!.resolve({}), BorderSide.none);
      expect(
        fileMenu.style!.backgroundColor!.resolve({WidgetState.hovered}),
        isNot(Colors.transparent),
      );
      expect(
        fileMenu.menuStyle!.backgroundColor!.resolve({}),
        fileMenu.style!.backgroundColor!.resolve({WidgetState.hovered}),
      );
      expect(
        (fileMenu.style!.shape!.resolve({})! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.zero,
      );

      final quitItem = fileMenu.menuChildren.single as MenuItemButton;
      expect(
        quitItem.style!.backgroundColor!.resolve({}),
        fileMenu.menuStyle!.backgroundColor!.resolve({}),
      );
      expect(
        quitItem.style!.backgroundColor!.resolve({WidgetState.focused}),
        isNot(Colors.transparent),
      );
      expect(quitItem.style!.minimumSize!.resolve({}), const Size(208, 28));
      expect(
        (quitItem.style!.shape!.resolve({})! as RoundedRectangleBorder)
            .borderRadius,
        BorderRadius.zero,
      );
      final shortcut = quitItem.trailingIcon! as Text;
      expect(shortcut.data, 'Ctrl+Q');
      expect(shortcut.style!.fontSize, 11);

      await tester.tap(find.text('File'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quit-shortcut-hint')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('desktop-caption-buttons')),
        findsOneWidget,
      );
      final captionContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('desktop-caption-buttons')),
              matching: find.byType(Container),
            )
            .first,
      );
      final captionDecoration = captionContainer.decoration! as BoxDecoration;
      final captionBorder = captionDecoration.border! as Border;
      expect(captionBorder.left.color, isNot(Colors.transparent));

      debugDefaultTargetPlatformOverride = null;
    });
  }
}

Widget _titleBarApp([FThemeData? theme]) {
  final resolvedTheme = theme ?? app_theme.lightTheme;
  return MaterialApp(
    theme: resolvedTheme.toApproximateMaterialTheme(),
    home: FTheme(
      data: resolvedTheme,
      child: const Scaffold(body: AppTitleBar()),
    ),
  );
}
