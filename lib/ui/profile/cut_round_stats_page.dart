import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../ink/ink_icon.dart';
import '../theme/sport_chrome.dart';
import 'cut_round_stats_view.dart';

/// 境界修行 → 「本轮统计」: totals of the cut round in progress.
class CutRoundStatsPage extends ConsumerWidget {
  const CutRoundStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final round = ref.watch(currentCutRoundProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cultivationSideStats)),
      body: round == null
          ? SportEmptyState(
              title: l10n.cutRoundNone,
              iconWidget: const StampedInkEmptyIcon(
                glyph: InkGlyph.factCheck,
                seal: '统',
              ),
            )
          : CutRoundStatsView(segment: round),
    );
  }
}
