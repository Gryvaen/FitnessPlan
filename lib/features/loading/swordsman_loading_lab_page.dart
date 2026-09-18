import 'package:flutter/material.dart';

import 'swordsman_loading_page.dart';

/// Non-release sandbox for iterating on the swordsman splash without
/// cold-starting the whole app. Loops (or replays) the real loading page
/// with a no-op initialize and no FitnessApp prewarm underneath.
class SwordsmanLoadingLabPage extends StatefulWidget {
  const SwordsmanLoadingLabPage({super.key});

  @override
  State<SwordsmanLoadingLabPage> createState() =>
      _SwordsmanLoadingLabPageState();
}

class _SwordsmanLoadingLabPageState extends State<SwordsmanLoadingLabPage> {
  int _generation = 0;
  bool _loop = true;

  void _replay() => setState(() => _generation++);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: ValueKey(_generation),
          child: SwordsmanLoadingPage(
            onInitialize: () async {},
            onFinished: () {
              if (!mounted) return;
              if (_loop) {
                _replay();
              } else {
                Navigator.of(context).maybePop();
              }
            },
            onEnterAnyway: () => Navigator.of(context).maybePop(),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.black.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    FilterChip(
                      label: Text(
                        _loop ? 'Loop' : 'Once',
                        style: const TextStyle(color: Colors.white),
                      ),
                      selected: _loop,
                      onSelected: (v) => setState(() => _loop = v),
                      selectedColor: Colors.white24,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      side: const BorderSide(color: Colors.white54),
                    ),
                    IconButton(
                      tooltip: 'Replay',
                      onPressed: _replay,
                      icon: const Icon(Icons.replay, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
