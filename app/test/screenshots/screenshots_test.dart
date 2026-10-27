// Renders the main screens to PNG files for visual review. Skipped unless SCREENSHOT_DIR is set:
//
//   SCREENSHOT_DIR=/some/dir flutter test test/screenshots
//
// Loads the real Roboto and Material Icons fonts from the Flutter SDK so text is readable
// (the default test font draws boxes).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';

final _dir = Platform.environment['SCREENSHOT_DIR'];
const _fonts = '/opt/flutter/bin/cache/artifacts/material_fonts';
final _shotKey = GlobalKey();

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Roboto', ['$_fonts/Roboto-Regular.ttf', '$_fonts/Roboto-Medium.ttf', '$_fonts/Roboto-Bold.ttf']);
  await load('MaterialIcons', ['$_fonts/MaterialIcons-Regular.otf']);
  // A serif stand-in for Android's default serif.
  await load('serif', ['/opt/flutter/engine/src/flutter/txt/third_party/fonts/RobotoSlab-VariableFont_wght.ttf']);
}

Future<void> _shot(WidgetTester t, String name, {double ratio = 2}) async {
  await t.pump(const Duration(milliseconds: 300));
  final boundary = _shotKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> _open(WidgetTester t, AppHarness h, {Size size = const Size(412, 892), double textScale = 1, Brightness? brightness}) async {
  t.view.physicalSize = size * 2;
  t.view.devicePixelRatio = 2;
  t.platformDispatcher.textScaleFactorTestValue = textScale;
  if (brightness != null) t.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(() {
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    t.platformDispatcher.clearAllTestValues();
  });
  await t.pumpWidget(RepaintBoundary(key: _shotKey, child: h.app));
  await pumpUntilFound(t, find.byType(Card));
  await settle(t);
}

void main() {
  final skip = _dir == null ? 'set SCREENSHOT_DIR to render screenshots' : null;
  setUpAll(() async {
    if (_dir != null) {
      Directory(_dir!).createSync(recursive: true);
      await _loadFonts();
    }
  });

  testWidgets('phone, light', (t) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await _open(t, h);
    await _shot(t, '01_today_light');

    await t.tap(find.byType(Card).first.hitTestable());
    await pumpUntilFound(t, find.text('Why this story was included'));
    await settle(t);
    await _shot(t, '02_story_light');
    await t.tap(find.byTooltip('Save story'));
    await settle(t);
    await t.tap(find.byTooltip('Back'));
    await settle(t);
    await t.tap(find.text('Explore'));
    await settle(t);
    await _shot(t, '03_explore_light');
    await t.tap(find.text('Saved'));
    await settle(t);
    await _shot(t, '04_saved_light');
    await t.tap(find.text('Settings'));
    await settle(t);
    await _shot(t, '05_settings_light');
  }, skip: skip != null, tags: 'screenshots');

  testWidgets('phone, dark', (t) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await _open(t, h, brightness: Brightness.dark);
    await _shot(t, '06_today_dark');
  }, skip: skip != null, tags: 'screenshots');

  testWidgets('phone, large text', (t) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await _open(t, h, textScale: 2);
    await _shot(t, '07_today_text200');
  }, skip: skip != null, tags: 'screenshots');

  testWidgets('tablet', (t) async {
    final h = AppHarness();
    addTearDown(h.dispose);
    await _open(t, h, size: const Size(1000, 700));
    await _shot(t, '08_today_tablet');
  }, skip: skip != null, tags: 'screenshots');

  testWidgets('offline with nothing cached', (t) async {
    final h = AppHarness(online: false);
    addTearDown(h.dispose);
    t.view.physicalSize = const Size(824, 1784);
    t.view.devicePixelRatio = 2;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(RepaintBoundary(key: _shotKey, child: h.app));
    await pumpUntilFound(t, find.text('No stories to show yet'));
    await settle(t);
    await _shot(t, '09_today_offline_empty');
  }, skip: skip != null, tags: 'screenshots');
}
