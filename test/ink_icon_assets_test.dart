import 'dart:io';
import 'dart:ui' as ui;

import 'package:diet/ui/foods/food_category_art.dart';
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

  test('every food category has a unique generated ink glyph', () {
    const categories = [
      '畜肉',
      '禽肉',
      '水产',
      '乳类',
      '蛋类',
      '豆类',
      '谷类',
      '薯类',
      '水果',
      '糖蜜饯',
      '坚果',
      '油脂',
      '饮料',
      '包装食品',
      '小吃',
      '菌藻',
      '蔬菜',
      '调味品',
      '自定义',
    ];

    final glyphs = categories.map(foodCategoryGlyph).toList();
    expect(glyphs.toSet(), hasLength(categories.length));
    expect(
      glyphs.map((glyph) => glyph.assetName).toSet(),
      hasLength(categories.length),
    );
    expect(glyphs, everyElement(isNot(InkGlyph.food)));
  });

  test('generated food glyphs are transparent RGBA masks', () async {
    const categories = [
      '畜肉',
      '禽肉',
      '水产',
      '乳类',
      '蛋类',
      '豆类',
      '谷类',
      '薯类',
      '水果',
      '糖蜜饯',
      '坚果',
      '油脂',
      '饮料',
      '包装食品',
      '小吃',
      '菌藻',
      '蔬菜',
      '调味品',
      '自定义',
    ];

    for (final category in categories) {
      final glyph = foodCategoryGlyph(category);
      final light = File('assets/ink/icons/light/${glyph.assetName}-v1.png');
      final dark = File('assets/ink/icons/dark/${glyph.assetName}-v1.png');
      expect(await light.readAsBytes(), await dark.readAsBytes());

      final codec = await ui.instantiateImageCodec(await light.readAsBytes());
      final frame = await codec.getNextFrame();
      final rgba = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(rgba, isNotNull, reason: category);
      final bytes = rgba!.buffer.asUint8List();
      var hasTransparentPixel = false;
      var hasVisiblePixel = false;
      for (var i = 3; i < bytes.length; i += 4) {
        hasTransparentPixel |= bytes[i] == 0;
        hasVisiblePixel |= bytes[i] > 0;
        if (hasTransparentPixel && hasVisiblePixel) break;
      }
      expect(hasTransparentPixel, isTrue, reason: category);
      expect(hasVisiblePixel, isTrue, reason: category);
      frame.image.dispose();
      codec.dispose();
    }
  });
}
