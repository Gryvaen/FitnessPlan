import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/repositories/app_update_repository.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/calorie_breakdown.dart';

/// 「我的」入口页：只读配额摘要 + 进入「我的档案」编辑。
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  Future<void> _clearData() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearData),
        content: Text(l10n.clearDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await Future.wait([
        ref.read(mealRepositoryProvider).clearAll(),
        ref.read(weightRepositoryProvider).clearAll(),
        ref.read(workoutRepositoryProvider).clearAll(),
        ref.read(noteRepositoryProvider).clearAll(),
        ref.read(foodRepositoryProvider).clearFavorites(),
        ref.read(formMemoryRepositoryProvider).clear(),
        ref.read(mealPresetRepositoryProvider).clearAll(),
        ref.read(waterRepositoryProvider).clearAll(),
      ]);
      await ref.read(profileProvider.notifier).clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.clearFailed('$e'))));
    }
  }

  Future<void> _checkForUpdate() async {
    final update = ref.read(appUpdateProvider);
    if (update.isBusy) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final local = _packageInfo?.version ?? '0.0.0';
    final localBuildNumber = _packageInfo?.buildNumber ?? '0';
    final notifier = ref.read(appUpdateProvider.notifier);

    try {
      final latest = await notifier.checkForUpdate(local, localBuildNumber);
      if (!mounted) return;

      if (latest == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.alreadyLatest(local))),
        );
        return;
      }

      final asset = AppUpdateLogic.pickApkAsset(
        latest.assets,
        version: latest.version,
        localBuildNumber: localBuildNumber,
      );
      if (asset == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.noInstallPackage)));
        return;
      }

      final notes = latest.body.isEmpty
          ? l10n.newVersionAsk(latest.version)
          : latest.body.length > 400
          ? '${latest.body.substring(0, 400)}…'
          : latest.body;

      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.newVersionTitle(latest.version)),
          content: SingleChildScrollView(child: Text(notes)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.later),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.downloadInstall),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(l10n.downloading)));
      // Fire-and-forget: progress lives on [appUpdateProvider] / AppBar icon.
      notifier.downloadAndInstall(asset: asset, localVersion: local);
    } on StateError catch (e) {
      if (!mounted) return;
      if (e.message == 'no_apk') {
        messenger.showSnackBar(SnackBar(content: Text(l10n.noInstallPackage)));
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.checkUpdateFailed('$e'))),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.checkUpdateFailed('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final update = ref.watch(appUpdateProvider);
    ref.listen<AppUpdateStatus>(appUpdateProvider, (prev, next) {
      final l10n = context.l10n;
      final messenger = ScaffoldMessenger.of(context);
      if (next.lastError != null && next.lastError != prev?.lastError) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.checkUpdateFailed(next.lastError!))),
        );
        ref.read(appUpdateProvider.notifier).clearFeedback();
      } else if (next.lastOpenMessage != null &&
          next.lastOpenMessage != prev?.lastOpenMessage) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.cannotOpenApk(next.lastOpenMessage!))),
        );
        ref.read(appUpdateProvider.notifier).clearFeedback();
      }
    });

    final plan = ref.read(profileRepositoryProvider).buildPlan(profile);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final versionLabel = _packageInfo?.version;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.me),
            if (versionLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                versionLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (isAndroid)
            IconButton(
              onPressed: update.isBusy ? null : _checkForUpdate,
              tooltip: update.phase == AppUpdatePhase.downloading
                  ? (update.progress > 0
                        ? '${(update.progress * 100).toStringAsFixed(0)}%'
                        : l10n.connecting)
                  : l10n.checkUpdate,
              icon: _UpdateDownloadIcon(status: update),
            ),
          IconButton(
            onPressed: _clearData,
            tooltip: l10n.clearData,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          AppSpacing.formPage,
          AppSpacing.formPage,
          listBottomInset(context, hasFab: false),
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dailyQuota, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${profile.targets.calories}',
                        style: theme.textTheme.statValue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'kcal',
                        style: theme.textTheme.statUnit?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'P ${profile.targets.proteinG.toStringAsFixed(0)} · '
                    'C ${profile.targets.carbG.toStringAsFixed(0)} · '
                    'F ${profile.targets.fatG.toStringAsFixed(0)}',
                    style: theme.textTheme.meta,
                  ),
                  if (profile.goal == FitnessGoal.cut &&
                      profile.dailyDeficit != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.deficitLine('${profile.dailyDeficit!.round()}')}'
                      '${profile.weeklyLossKg != null ? l10n.weeklyLossLine(profile.weeklyLossKg!.toStringAsFixed(1)) : ''}'
                      '${profile.goalWeeks != null ? l10n.aboutNWeeks(profile.goalWeeks!) : ''}',
                      style: theme.textTheme.meta,
                    ),
                  ],
                  if (profile.calorieAdjustment > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.plateauAdjLine('${profile.calorieAdjustment}'),
                      style: theme.textTheme.meta,
                    ),
                  ],
                  const SizedBox(height: 8),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      l10n.calcMethod,
                      style: theme.textTheme.titleSmall,
                    ),
                    children: [CalorieBreakdown(plan: plan, compact: true)],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l10n.myProfile),
              subtitle: Text(
                l10n.profileSubtitle(
                  profile.sex.label(l10n),
                  profile.age,
                  '${profile.heightCm.round()}',
                  profile.weightKg.toStringAsFixed(1),
                  profile.goal.label(l10n),
                ),
                style: theme.textTheme.meta,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/edit'),
            ),
          ),
          const SizedBox(height: AppSpacing.field),
          Card(
            child: ListTile(
              leading: const Icon(Icons.handyman_outlined),
              title: Text(l10n.toolbox),
              subtitle: Text(l10n.toolboxSubtitle, style: theme.textTheme.meta),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/tools'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Download icon with an optional progress ring for background update downloads.
class _UpdateDownloadIcon extends StatelessWidget {
  const _UpdateDownloadIcon({required this.status});

  final AppUpdateStatus status;

  @override
  Widget build(BuildContext context) {
    if (status.phase == AppUpdatePhase.idle) {
      return const Icon(Icons.download_outlined);
    }

    final scheme = Theme.of(context).colorScheme;
    final determinate =
        status.phase == AppUpdatePhase.downloading && status.progress > 0;

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: determinate ? status.progress.clamp(0.0, 1.0) : null,
            strokeWidth: 2.5,
            color: scheme.primary,
            backgroundColor: scheme.primary.withValues(alpha: 0.18),
          ),
          Icon(Icons.download_outlined, size: 16, color: scheme.onSurface),
        ],
      ),
    );
  }
}
