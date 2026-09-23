import 'dart:io';
import 'dart:ui' as ui;

import 'package:diet/ui/ink/ink_icon.dart';
import 'package:diet/ui/ink/ink_icon_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every glyph has decodable 256px light and dark PNG assets', () async {
    for (final glyph in InkGlyph.values) {
      for (final variant in const ['light', 'dark']) {
        final path = 'assets/ink/icons/$variant/${glyph.assetName}-v1.png';
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'missing $path');
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 256, reason: path);
        expect(frame.image.height, 256, reason: path);
        frame.image.dispose();
        codec.dispose();
      }
    }
  });

  testWidgets('gallery renders every glyph in both theme variants', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: InkIconGallery()));
    await tester.pump();
    expect(find.byType(InkIcon), findsNWidgets(InkGlyph.values.length * 6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark-theme glyphs use the high-contrast surface foreground', (
    tester,
  ) async {
    const foreground = Color(0xFFECEFF2);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(onSurface: foreground),
        ),
        home: const Scaffold(body: InkIcon(InkGlyph.food)),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.color, foreground);
    expect(image.colorBlendMode, BlendMode.srcIn);
  });
}
