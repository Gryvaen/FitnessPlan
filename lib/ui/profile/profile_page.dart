import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/app_update_repository.dart';
import '../../domain/calorie_calculator.dart';
import '../../l10n/app_localizations_ext.dart';
import '../../providers/app_providers.dart';
import '../shell/swipe_tab_view.dart';
import '../strategy/strategy_labels.dart';
import '../theme/app_theme.dart';
import '../theme/sport_chrome.dart';
import '../widgets/calorie_breakdown.dart';
import 'cultivation_labels.dart';

/// Me header action tints — distinct from menu-row macro colors.
const _languageColor = Color(0xFF5B6CDB); // indigo
const _themeColor = Color(0xFFE8A317); // amber / sun
const _updateColor = Color(0xFF2E7D32); // download green

/// 「我的」入口页：只读配额摘要 + 进入「我的档案」编辑。
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  PackageInfo? _packageInfo;

  /// Guards the three data-management actions below (clear/export/import):
  /// the "关于" sheet that triggers them pops itself immediately, so nothing
  /// stops the user from reopening it and tapping again while a prior
  /// operation (especially `_importData`, which closes the DB connection
  /// and replaces the on-disk file) is still in flight. A single shared
  /// flag is enough since only one of these should ever run at a time.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
  }

  Future<void> _clearData() async {
    if (_busy) return;
    _busy = true;
    try {
      await _doClearData();
    } finally {
      _busy = false;
    }
  }

  Future<void> _doClearData() async {
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
        ref.read(foodRepositoryProvider).clearHiddenRecentFoods(),
        ref.read(formMemoryRepositoryProvider).clear(),
        ref.read(mealPresetRepositoryProvider).clearAll(),
        ref.read(waterRepositoryProvider).clearAll(),
        ref.read(dietStrategyRepositoryProvider).clearAll(),
      ]);
      await ref.read(profileProvider.notifier).clear();
      await ref.read(remindersProvider.notifier).syncSchedule();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.clearFailed('$e'))));
    }
  }

  Future<void> _exportData() async {
    if (_busy) return;
    _busy = true;
    try {
      await _doExportData();
    } finally {
      _busy = false;
    }
  }

  Future<void> _doExportData() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final destination = await showModalBottomSheet<_ExportDestination>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.formPage,
              0,
              AppSpacing.formPage,
              AppSpacing.formPage,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.exportData, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.compact),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.folder_open_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.exportToFolder),
                  subtitle: Text(l10n.exportToFolderHint),
                  onTap: () =>
                      Navigator.pop(ctx, _ExportDestination.folder),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.share_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.exportViaShare),
                  subtitle: Text(l10n.exportViaShareHint),
                  onTap: () =>
                      Navigator.pop(ctx, _ExportDestination.share),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (destination == null || !mounted) return;

    try {
      final repo = ref.read(dataBackupRepositoryProvider);
      if (destination == _ExportDestination.folder) {
        // Android SAF paths from getDirectoryPath are not writable via dart:io.
        // saveFile(bytes:) writes through the system picker instead.
        final payload = await repo.buildBackup();
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: l10n.exportData,
          fileName: payload.fileName,
          bytes: payload.bytes,
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
        if (savedPath == null || !mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.exportDataSavedTo(savedPath))),
        );
      } else {
        final file = await repo.writeBackupToTemp();
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/json')],
            subject: l10n.exportData,
          ),
        );
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(l10n.exportDataDone)));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportDataFailed('$e'))),
      );
    }
  }

  Future<void> _importData() async {
    if (_busy) return;
    _busy = true;
    try {
      await _doImportData();
    } finally {
      _busy = false;
    }
  }

  Future<void> _doImportData() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importData),
        content: Text(l10n.importDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.importData),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: l10n.importData,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('invalid_backup');
      }

      await ref.read(dataBackupRepositoryProvider).importFromBytes(bytes);
      ref.invalidate(databaseProvider);
      ref.invalidate(themeProvider);
      ref.invalidate(localeProvider);
      ref.invalidate(remindersProvider);
      ref.read(profileProvider.notifier).reload();
      await ref.read(remindersProvider.notifier).syncSchedule();

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.importDataDone)));
    } catch (e) {
      // DB may already be closed; force a fresh connection so the app recovers.
      ref.invalidate(databaseProvider);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importDataFailed('$e'))),
      );
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
    // Re-fetch rather than trust the cached _packageInfo: this page's state
    // outlives an in-place update install (the 我的 tab is kept alive by the
    // StatefulShellRoute), so a stale cached version number kept re-offering
    // an update that had already been installed as still available.
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _packageInfo = info);
    final local = info.version;
    final localBuildNumber = info.buildNumber;
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
      body: SwipeTabView(
        branchIndex: 3,
        index: 0,
        onIndexChanged: (_) {},
        children: [
          SafeArea(
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
                  // Align the title with the rows below and with the 食物 / 记录
                  // pages: the ListView already supplies the 20px side inset.
                  padding: const EdgeInsets.only(bottom: AppSpacing.section),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(l10n.me, style: theme.textTheme.headlineSmall),
                      if (versionLabel != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onLongPress: kReleaseMode
                              ? null
                              : () => context.push('/debug/swordsman-loading'),
                          child: Text(
                            'v$versionLabel',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                            const Icon(
                              Icons.translate,
                              size: 18,
                              color: _languageColor,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              Localizations.localeOf(context).languageCode ==
                                      'zh'
                                  ? 'EN'
                                  : '中',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: _languageColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.theme,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final current = ref.read(themeProvider);
                          ref
                              .read(themeProvider.notifier)
                              .select(current.toggled);
                        },
                        icon: Icon(
                          ref.watch(themeProvider).isDark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          size: 20,
                          color: _themeColor,
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
                const _CultivationHeroCard(),
                const SizedBox(height: AppSpacing.section),
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MenuIconBadge(
                    icon: Icons.person_outline,
                    color: AppThemeVisuals.of(context).accent,
                  ),
                  title: Text(
                    l10n.myProfile,
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
                  color: AppColors.carb,
                  onTap: () => context.push('/profile/nutrition'),
                ),
                _MenuRow(
                  icon: Icons.notifications_outlined,
                  title: l10n.reminders,
                  subtitle: l10n.remindersSubtitle,
                  color: AppColors.water,
                  onTap: () => context.push('/profile/reminders'),
                ),
                _MenuRow(
                  icon: Icons.handyman_outlined,
                  title: l10n.toolbox,
                  subtitle: l10n.toolboxSubtitle,
                  color: AppColors.fat,
                  onTap: () => context.push('/profile/tools'),
                ),
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MenuIconBadge(
                    icon: Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
        ],
      ),
    );
  }

  void _showAbout(BuildContext context, CaloriePlan plan, String? version) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _AboutSheet(
        plan: plan,
        version: version,
        onExport: () {
          Navigator.of(sheetContext).pop();
          _exportData();
        },
        onImport: () {
          Navigator.of(sheetContext).pop();
          _importData();
        },
        onClear: () {
          Navigator.of(sheetContext).pop();
          _clearData();
        },
      ),
    );
  }
}

enum _ExportDestination { folder, share }

class _AboutSheet extends StatelessWidget {
  const _AboutSheet({
    required this.plan,
    required this.version,
    required this.onExport,
    required this.onImport,
    required this.onClear,
  });

  final CaloriePlan plan;
  final String? version;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onClear;

  static const _exportGreen = Color(0xFF2E7D32);
  static const _importBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.formPage,
          0,
          AppSpacing.formPage,
          AppSpacing.formPage,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.appTitle, style: theme.textTheme.titleLarge),
                      if (version != null)
                        Text(
                          l10n.appVersionLabel(version!),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    l10n.clearData,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.section),
            Divider(height: 1, color: AppThemeVisuals.of(context).divider),
            const SizedBox(height: AppSpacing.section),
            Text(l10n.calcMethod, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.compact),
            CalorieBreakdown(
              plan: plan,
              compact: true,
              showTargetAndMacros: false,
            ),
            const SizedBox(height: AppSpacing.compact),
            Text(
              l10n.kcalPerKgFatFact(
                CalorieCalculator.kcalPerKgFat.toInt().toString(),
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.section),
            Divider(height: 1, color: AppThemeVisuals.of(context).divider),
            const SizedBox(height: AppSpacing.compact),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onExport,
                    icon: const Icon(
                      Icons.upload_outlined,
                      color: _exportGreen,
                    ),
                    label: Text(
                      l10n.exportData,
                      style: const TextStyle(
                        color: _exportGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onImport,
                    icon: const Icon(
                      Icons.download_outlined,
                      color: _importBlue,
                    ),
                    label: Text(
                      l10n.importData,
                      style: const TextStyle(
                        color: _importBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Entry into the cultivation-realm mini-game. Shows live realm/layer
/// progress once the user is eligible ([cultivationEligibleProvider]);
/// otherwise a generic invite that still routes to the locked explainer.
class _CultivationHeroCard extends ConsumerWidget {
  const _CultivationHeroCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final v = AppThemeVisuals.of(context);
    final l10n = context.l10n;
    final eligible = ref.watch(cultivationEligibleProvider);
    final progress = eligible ? ref.watch(cultivationProgressProvider) : null;

    return Material(
      color: v.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/profile/cultivation'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.card),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: v.cardBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: progress == null
                    ? Container(
                        width: 64,
                        height: 64,
                        color: v.accentSoft,
                        child: Icon(Icons.self_improvement, color: v.accent),
                      )
                    : Image.asset(
                        progress.realm.artAsset(progress.layer),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.4),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cultivationHeroLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      progress == null
                          ? l10n.cultivationLockedTitle
                          : l10n.cultivationLayerBadge(
                              progress.realm.label(l10n),
                              '${progress.layer}',
                            ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: progress?.realm.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (progress != null && !progress.isMax) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(color: v.track),
                              FractionallySizedBox(
                                alignment: AlignmentDirectional.centerStart,
                                widthFactor: progress.layerProgress.clamp(
                                  0.0,
                                  1.0,
                                ),
                                child: ColoredBox(
                                  color: progress.realm.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A profile menu row: tinted icon badge + title + subtitle + chevron.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SportListTile(
      contentPadding: EdgeInsets.zero,
      leading: MenuIconBadge(icon: icon, color: color),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
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
    const color = _updateColor;
    if (status.phase == AppUpdatePhase.idle) {
      if (!status.hasUpdateAvailable) {
        return const Icon(Icons.download_outlined, color: color);
      }
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.download_outlined, color: color),
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
            color: color,
            backgroundColor: color.withValues(alpha: 0.18),
          ),
          const Icon(Icons.download_outlined, size: 16, color: color),
        ],
      ),
    );
  }
}
