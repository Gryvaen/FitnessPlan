import 'package:flutter/material.dart';

import 'ink_icon.dart';

/// Visual QA surface for the generated ink icon system.
///
/// It intentionally renders every glyph at the three production sizes on
/// both paper and graphite so asset cropping and small-size recognition can
/// be checked without visiting every feature flow.
class InkIconGallery extends StatelessWidget {
  const InkIconGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ink icon gallery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _IconGrid(brightness: Brightness.light),
          SizedBox(height: 24),
          _IconGrid(brightness: Brightness.dark),
        ],
      ),
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    return Theme(
      data: ThemeData(brightness: brightness),
      child: ColoredBox(
        color: dark ? const Color(0xFF171A19) : const Color(0xFFF4F1E9),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final glyph in InkGlyph.values)
                SizedBox(
                  width: 104,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final size in const [18.0, 24.0, 32.0])
                            InkIcon(glyph, size: size),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        glyph.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: dark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
