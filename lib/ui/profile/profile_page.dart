import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
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
  bool _checkingUpdate = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.clearFailed('$e'))),
      );
    }
  }

  Future<void> _checkForUpdate() async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final local = _packageInfo?.version ?? '0.0.0';
      final repo = ref.read(appUpdateRepositoryProvider);
      final latest = await repo.fetchLatest(localVersion: local);
      if (!mounted) return;

      if (!AppUpdateLogic.isNewer(local, latest.version)) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.alreadyLatest(local))),
        );
        return;
      }

      final asset = AppUpdateLogic.pickApkAsset(latest.assets);
      if (asset == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.noInstallPackage)),
        );
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

      final progress = ValueNotifier<double>(0);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(l10n.downloading),
            content: ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (context, value, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: value > 0 ? value : null),
                    const SizedBox(height: 12),
                    Text(
                      value > 0
                          ? '${(value * 100).toStringAsFixed(0)}%'
                          : l10n.connecting,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      try {
        final path = await repo.downloadApk(
          asset.downloadUrl,
          localVersion: local,
          onProgress: (p) => progress.value = p,
        );
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        final result = await OpenFilex.open(
          path,
          type: 'application/vnd.android.package-archive',
        );
        if (!mounted) return;
        if (result.type != ResultType.done) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.cannotOpenApk(result.message))),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        rethrow;
      } finally {
        progress.dispose();
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.checkUpdateFailed('$e'))),
      );
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              onPressed: _checkingUpdate ? null : _checkForUpdate,
              tooltip: l10n.checkUpdate,
              icon: _checkingUpdate
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
            ),
          IconButton(
            onPressed: _clearData,
            tooltip: l10n.clearData,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.formPage),
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
              subtitle: Text(
                l10n.toolboxSubtitle,
                style: theme.textTheme.meta,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/tools'),
            ),
          ),
        ],
      ),
    );
  }
}
