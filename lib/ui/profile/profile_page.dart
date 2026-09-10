import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/repositories/app_update_repository.dart';
import '../../domain/calorie_calculator.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../strategy/strategy_labels.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/calorie_breakdown.dart';
import 'theme_page.dart';

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
        ref.read(dietStrategyRepositoryProvider).clearAll(),
      ]);
      await ref.read(profileProvider.notifier).clear();
      await ref.read(workoutReminderProvider.notifier).syncSchedule();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.clearFailed('$e'))));
    }
  }

  String _nutritionSubtitle(WidgetRef ref, AppLocalizations l10n) {
    final active = ref.watch(activeDietPlanProvider).value;
    final today = ref.watch(todayTargetProvider).value;
    final kcal = today?.caloriesRounded;
    final strategy = active == null
        ? l10n.noStrategyShort
        : active.kind.label(l10n);
    return kcal == null ? strategy : '$kcal kcal · $strategy';
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

    return AppChromeScaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.listPage,
            8,
            AppSpacing.listPage,
            listBottomInset(context, hasFab: false),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.listPage,
                8,
                AppSpacing.listPage,
                AppSpacing.section,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(l10n.me, style: theme.textTheme.headlineSmall),
                  if (versionLabel != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      'v$versionLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.language,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref
                        .read(localeProvider.notifier)
                        .toggle(Localizations.localeOf(context)),
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.translate, size: 18),
                        const SizedBox(width: 2),
                        Text(
                          Localizations.localeOf(context).languageCode == 'zh'
                              ? 'EN'
                              : '中',
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                  if (isAndroid)
                    IconButton(
                      tooltip: update.phase == AppUpdatePhase.downloading
                          ? (update.progress > 0
                                ? '${(update.progress * 100).toStringAsFixed(0)}%'
                                : l10n.connecting)
                          : l10n.checkUpdate,
                      onPressed: update.isBusy ? null : _checkForUpdate,
                      icon: _UpdateDownloadIcon(status: update),
                    ),
                ],
              ),
            ),
            SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                l10n.profileGreeting,
                style: theme.textTheme.titleMedium,
              ),
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
            _MenuRow(
              icon: Icons.track_changes_outlined,
              title: l10n.nutritionTargets,
              subtitle: _nutritionSubtitle(ref, l10n),
              onTap: () => context.push('/profile/nutrition'),
            ),
            _MenuRow(
              icon: Icons.notifications_outlined,
              title: l10n.reminders,
              subtitle: l10n.remindersSubtitle,
              onTap: () => context.push('/profile/reminders'),
            ),
            _MenuRow(
              icon: Icons.handyman_outlined,
              title: l10n.toolbox,
              subtitle: l10n.toolboxSubtitle,
              onTap: () => context.push('/profile/tools'),
            ),
            _MenuRow(
              icon: Icons.palette_outlined,
              title: l10n.theme,
              subtitle: ref.watch(themeProvider).label(l10n),
              onTap: () => context.push('/profile/theme'),
            ),
            SportListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.about),
              subtitle: versionLabel == null
                  ? null
                  : Text(
                      l10n.appVersionLabel(versionLabel),
                      style: theme.textTheme.meta,
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAbout(context, plan, versionLabel),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context, CaloriePlan plan, String? version) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.formPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appTitle, style: theme.textTheme.titleLarge),
              if (version != null)
                Text(
                  l10n.appVersionLabel(version),
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: AppSpacing.section),
              Text(l10n.calcMethod, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.compact),
              CalorieBreakdown(plan: plan, compact: true),
              const SizedBox(height: AppSpacing.section),
              SportListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  l10n.clearData,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _clearData();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A profile menu row: icon badge + title + subtitle + chevron.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SportListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
