import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cultivation.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'cultivation_labels.dart';

enum _RealmStatus { done, current, locked }

String _kg(double v) => v.round().toString();

/// 「境界体系」总览：练气/筑基/结丹/元婴/化神五大境界的门槛、每层 kcal 与
/// 当前突破进度一览，从 [CultivationPage] 的侧边「境界体系」图标进入。
class RealmGuidePage extends ConsumerWidget {
  const RealmGuidePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = ref.watch(cultivationProgressProvider);
    final currentIndex = CultivationRealm.values.indexOf(progress.realm);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.realmGuideTitle)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.compact,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          Text(
            l10n.realmGuideIntro,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          for (final realm in CultivationRealm.values) ...[
            _RealmGuideCard(
              realm: realm,
              status: realm.index < currentIndex
                  ? _RealmStatus.done
                  : realm.index == currentIndex
                  ? _RealmStatus.current
                  : _RealmStatus.locked,
              currentLayer: progress.layer,
            ),
            const SizedBox(height: AppSpacing.card),
          ],
          const SizedBox(height: AppSpacing.compact),
          Text.rich(
            TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
              children: [
                TextSpan(
                  text: l10n.realmGuideFootnoteTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: l10n.realmGuideFootnoteBody),
                const TextSpan(text: '\n'),
                TextSpan(text: l10n.realmGuideFootnoteNote),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RealmGuideCard extends StatelessWidget {
  const _RealmGuideCard({
    required this.realm,
    required this.status,
    required this.currentLayer,
  });

  final CultivationRealm realm;
  final _RealmStatus status;
  final int currentLayer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locked = status == _RealmStatus.locked;
    final glow = status != _RealmStatus.locked;

    final layersDone = switch (status) {
      _RealmStatus.done => kCultivationLayers,
      _RealmStatus.current => currentLayer,
      _RealmStatus.locked => 0,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.compact),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: glow
              ? const Color(0xFFE8C468).withValues(alpha: 0.55)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: glow ? 1.2 : 1,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: const Color(0xFFE8C468).withValues(alpha: 0.18),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RealmSwatch(realm: realm, locked: locked),
          const SizedBox(width: AppSpacing.card),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        realm.label(l10n),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: realm.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusTag(
                      realm: realm,
                      status: status,
                      currentLayer: currentLayer,
                      l10n: l10n,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  realm.isMax
                      ? l10n.realmGuideMaxRangeLine(_kg(realm.floorKg))
                      : l10n.realmGuideRangeLine(
                          _kg(realm.floorKg),
                          _kg(realm.ceilKg),
                          formatKcal(realm.perLayerKcal!),
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!realm.isMax) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.realmGuideNextThresh(
                      realm.next!.label(l10n),
                      _kg(realm.ceilKg),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: realm.textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 1; i <= kCultivationLayers; i++) ...[
                      if (i > 1) const SizedBox(width: 5),
                      _RealmGuideDot(
                        filled: i <= layersDone,
                        current: status == _RealmStatus.current && !realm.isMax
                            ? i == layersDone
                            : false,
                        color: realm.textColor,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RealmSwatch extends StatelessWidget {
  const _RealmSwatch({required this.realm, required this.locked});

  final CultivationRealm realm;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      realm.artAsset(kCultivationLayers),
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.6),
    );
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: locked
                ? Opacity(
                    opacity: 0.55,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: image,
                    ),
                  )
                : image,
          ),
          if (locked)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.realm,
    required this.status,
    required this.currentLayer,
    required this.l10n,
  });

  final CultivationRealm realm;
  final _RealmStatus status;
  final int currentLayer;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (text, fg, bg) = switch (status) {
      _RealmStatus.done => (
        l10n.realmGuideTagDone,
        realm.textColor,
        realm.textColor.withValues(alpha: 0.12),
      ),
      _RealmStatus.current => (
        realm.isMax
            ? l10n.cultivationMaxCaption
            : l10n.realmGuideTagCurrent('$currentLayer'),
        realm.textColor,
        realm.textColor.withValues(alpha: 0.16),
      ),
      _RealmStatus.locked => (
        realm.isMax ? l10n.realmGuideTagLockedMax : l10n.realmGuideTagLocked,
        theme.colorScheme.onSurfaceVariant,
        theme.colorScheme.surfaceContainerHighest,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RealmGuideDot extends StatelessWidget {
  const _RealmGuideDot({
    required this.filled,
    required this.current,
    required this.color,
  });

  final bool filled;
  final bool current;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (current) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      );
    }
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : color.withValues(alpha: 0.16),
      ),
    );
  }
}
