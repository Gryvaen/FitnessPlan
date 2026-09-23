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
import '../ink/ink_icon.dart';
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
        ref.read(dayMarkerRepositoryProvider).clearAll(),
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
                  leading: InkIcon(
                    InkGlyph.folder,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.exportToFolder),
                  subtitle: Text(l10n.exportToFolderHint),
                  onTap: () => Navigator.pop(ctx, _ExportDestination.folder),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: InkIcon(
                    InkGlyph.share,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(l10n.exportViaShare),
                  subtitle: Text(l10n.exportViaShareHint),
                  onTap: () => Navigator.pop(ctx, _ExportDestination.share),
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
                            const InkIcon(
                              InkGlyph.language,
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
                        icon: InkIcon(
                          ref.watch(themeProvider).isDark
                              ? InkGlyph.moon
                              : InkGlyph.sun,
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
                const CultivationHeroCard(),
                const SizedBox(height: AppSpacing.section),
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: InkIcon(
                    InkGlyph.profile,
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
                  trailing: const InkIcon(InkGlyph.chevronRight),
                  onTap: () => context.push('/profile/edit'),
                ),
                _MenuRow(
                  glyph: InkGlyph.target,
                  title: l10n.nutritionTargets,
                  subtitle: _nutritionSubtitle(ref, l10n),
                  color: AppColors.carb,
                  onTap: () => context.push('/profile/nutrition'),
                ),
                _MenuRow(
                  glyph: InkGlyph.notification,
                  title: l10n.reminders,
                  subtitle: l10n.remindersSubtitle,
                  color: AppColors.water,
                  onTap: () => context.push('/profile/reminders'),
                ),
                _MenuRow(
                  glyph: InkGlyph.tools,
                  title: l10n.toolbox,
                  subtitle: l10n.toolboxSubtitle,
                  color: AppColors.fat,
                  onTap: () => context.push('/profile/tools'),
                ),
                SportListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: InkIcon(
                    InkGlyph.info,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(l10n.about),
                  subtitle: versionLabel == null
                      ? null
                      : Text(
                          l10n.appVersionLabel(versionLabel),
                          style: theme.textTheme.meta,
                        ),
                  trailing: const InkIcon(InkGlyph.chevronRight),
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
                  icon: InkIcon(
                    InkGlyph.delete,
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
                    icon: const InkIcon(InkGlyph.upload, color: _exportGreen),
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
                    icon: const InkIcon(InkGlyph.download, color: _importBlue),
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
class CultivationHeroCard extends ConsumerWidget {
  const CultivationHeroCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final v = AppThemeVisuals.of(context);
    final l10n = context.l10n;
    final eligible = ref.watch(cultivationEligibleProvider);
    final progress = eligible ? ref.watch(cultivationProgressProvider) : null;
    final accent = progress?.realm.textColor ?? v.accent;

    final title = progress == null
        ? l10n.cultivationLockedTitle
        : l10n.cultivationLayerBadge(
            progress.realm.label(l10n),
            '${progress.layer}',
          );

    return Semantics(
      button: true,
      label: '${l10n.cultivationHeroLabel}，$title',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/profile/cultivation'),
        child: SizedBox(
          key: const ValueKey('cultivation-ink-card'),
          height: 138,
          width: double.infinity,
          child: CustomPaint(
            painter: _RealmCardPainter(
              paper: v.card,
              ink: theme.colorScheme.onSurface,
              accent: accent,
              dark: theme.brightness == Brightness.dark,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 7,
                  top: 7,
                  bottom: 7,
                  width: 112,
                  child: ClipPath(
                    clipper: const _RealmArtClipper(),
                    child: progress == null
                        ? _LockedRealmArt(accent: accent)
                        : Image.asset(
                            progress.realm.artAsset(progress.layer),
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.42),
                            color: theme.brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: .14)
                                : null,
                            colorBlendMode: theme.brightness == Brightness.dark
                                ? BlendMode.darken
                                : null,
                          ),
                  ),
                ),
                Positioned(
                  left: 102,
                  top: 0,
                  bottom: 0,
                  child: CustomPaint(
                    size: const Size(28, 138),
                    painter: _InkFadePainter(
                      color: v.card,
                      ink: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Positioned(
                  left: 126,
                  right: 16,
                  top: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.cultivationHeroLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 2.4,
                              ),
                            ),
                          ),
                          const InkSeal('境', size: 23),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: accent,
                          fontFamily: AppTheme.displayFontFamily,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .8,
                        ),
                      ),
                      const Spacer(),
                      if (progress == null)
                        _LockedRealmHint(color: accent)
                      else ...[
                        _RealmLayerMarks(layer: progress.layer, color: accent),
                        if (!progress.isMax) ...[
                          const SizedBox(height: 8),
                          InkBrushProgressBar(
                            value: progress.layerProgress,
                            height: 8,
                            color: accent,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedRealmArt extends StatelessWidget {
  const _LockedRealmArt({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: accent.withValues(alpha: .09),
    child: Center(
      child: InkIcon(
        InkGlyph.meditation,
        size: 58,
        color: accent.withValues(alpha: .7),
      ),
    ),
  );
}

class _LockedRealmHint extends StatelessWidget {
  const _LockedRealmHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CustomPaint(size: const Size(48, 8), painter: _DryBrushPainter(color)),
      const SizedBox(width: 8),
      InkIcon(InkGlyph.chevronRight, size: 18, color: color),
    ],
  );
}

class _RealmLayerMarks extends StatelessWidget {
  const _RealmLayerMarks({required this.layer, required this.color});

  final int layer;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('cultivation-layer-marks'),
    children: [
      for (var i = 1; i <= 9; i++) ...[
        if (i > 1) const SizedBox(width: 5),
        CustomPaint(
          size: Size(i == layer ? 13 : 8, 7),
          painter: _LayerMarkPainter(
            color: color,
            filled: i <= layer,
            current: i == layer,
          ),
        ),
      ],
    ],
  );
}

class _RealmCardPainter extends CustomPainter {
  const _RealmCardPainter({
    required this.paper,
    required this.ink,
    required this.accent,
    required this.dark,
  });

  final Color paper;
  final Color ink;
  final Color accent;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final paperPath = Path()
      ..moveTo(11, 3)
      ..quadraticBezierTo(size.width * .35, 0, size.width - 14, 4)
      ..quadraticBezierTo(size.width - 2, 5, size.width - 4, 18)
      ..lineTo(size.width - 2, size.height - 15)
      ..quadraticBezierTo(
        size.width - 4,
        size.height - 3,
        size.width - 18,
        size.height - 4,
      )
      ..quadraticBezierTo(size.width * .52, size.height, 12, size.height - 3)
      ..quadraticBezierTo(2, size.height - 5, 4, size.height - 18)
      ..lineTo(2, 16)
      ..quadraticBezierTo(3, 5, 11, 3)
      ..close();
    canvas.drawShadow(paperPath, Colors.black.withValues(alpha: .18), 10, true);
    canvas.drawPath(paperPath, Paint()..color = paper);

    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          accent.withValues(alpha: dark ? .13 : .08),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawPath(paperPath, wash);

    final border = Paint()
      ..color = ink.withValues(alpha: dark ? .42 : .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(paperPath, border);
    canvas.drawLine(
      Offset(132, 12),
      Offset(size.width - 18, 12),
      Paint()
        ..color = ink.withValues(alpha: .08)
        ..strokeWidth = .8,
    );
  }

  @override
  bool shouldRepaint(_RealmCardPainter oldDelegate) =>
      paper != oldDelegate.paper ||
      ink != oldDelegate.ink ||
      accent != oldDelegate.accent ||
      dark != oldDelegate.dark;
}

class _RealmArtClipper extends CustomClipper<Path> {
  const _RealmArtClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(5, 1)
    ..lineTo(size.width - 10, 0)
    ..quadraticBezierTo(
      size.width,
      size.height * .28,
      size.width - 5,
      size.height * .5,
    )
    ..quadraticBezierTo(
      size.width - 13,
      size.height * .76,
      size.width - 2,
      size.height,
    )
    ..lineTo(3, size.height - 2)
    ..quadraticBezierTo(0, size.height * .52, 4, 1)
    ..close();

  @override
  bool shouldReclip(_RealmArtClipper oldClipper) => false;
}

class _InkFadePainter extends CustomPainter {
  const _InkFadePainter({required this.color, required this.ink});

  final Color color;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color, color],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, fade);
    final stroke = Paint()
      ..color = ink.withValues(alpha: .12)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .7, 18),
      Offset(size.width * .45, size.height - 20),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_InkFadePainter oldDelegate) =>
      color != oldDelegate.color || ink != oldDelegate.ink;
}

class _DryBrushPainter extends CustomPainter {
  const _DryBrushPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .58)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * .45),
      Offset(size.width, size.height * .45),
      paint..strokeWidth = 3.2,
    );
    canvas.drawLine(
      Offset(4, size.height * .78),
      Offset(size.width * .78, size.height * .78),
      paint..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(_DryBrushPainter oldDelegate) =>
      color != oldDelegate.color;
}

class _LayerMarkPainter extends CustomPainter {
  const _LayerMarkPainter({
    required this.color,
    required this.filled,
    required this.current,
  });

  final Color color;
  final bool filled;
  final bool current;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: filled ? 1 : .2)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = current ? 5 : 3;
    canvas.drawLine(
      Offset(1, size.height / 2),
      Offset(size.width - 1, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LayerMarkPainter oldDelegate) =>
      color != oldDelegate.color ||
      filled != oldDelegate.filled ||
      current != oldDelegate.current;
}

/// A profile menu row: tinted icon badge + title + subtitle + chevron.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  final InkGlyph glyph;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SportListTile(
      contentPadding: EdgeInsets.zero,
      leading: InkIcon(glyph, color: color),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: InkIcon(
        InkGlyph.chevronRight,
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
        return const InkIcon(InkGlyph.download, color: color);
      }
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const InkIcon(InkGlyph.download, color: color),
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
          const InkIcon(InkGlyph.download, size: 16, color: color),
        ],
      ),
    );
  }
}
