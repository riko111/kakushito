import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kakushito_mobile/features/settings/settings_screen.dart';
import 'package:kakushito_mobile/features/viewer/mask_overlay.dart';

void main() {
  testWidgets('Changing mask color persists using _maskColorKey', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.tap(find.text('色を選ぶ'));
    await tester.pumpAndSettle();

    final redColor = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.red,
      ),
    );
    await tester.tap(redColor);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('maskColor'), Colors.red.value);
  });

  testWidgets('MaskOverlay uses persisted mask color', (tester) async {
    SharedPreferences.setMockInitialValues({'maskColor': Colors.red.value});

    final key = GlobalKey();
    final strokes = [
      MaskStroke(points: const [Offset(0, 50), Offset(100, 50)], page: 0),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: RepaintBoundary(
                key: key,
                child: MaskOverlay(strokes: strokes, maskEnabled: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = byteData!.buffer.asUint8List();
      final width = image.width;
      final index = ((50 * width) + 10) * 4;
      final color = (bytes[index + 3] << 24) |
          (bytes[index] << 16) |
          (bytes[index + 1] << 8) |
          bytes[index + 2];
      expect(color, equals(Colors.red.value));
    });
  });
}

