import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../data/repositories/app_update_repository.dart';
import 'core_providers.dart';

enum AppUpdatePhase { idle, checking, downloading }

class AppUpdateStatus {
  const AppUpdateStatus({
    this.phase = AppUpdatePhase.idle,
    this.progress = 0,
    this.lastError,
    this.lastOpenMessage,
    this.availableVersion,
  });

  final AppUpdatePhase phase;

  /// 0..1 while [phase] is [AppUpdatePhase.downloading]; 0 means connecting.
  final double progress;
  final String? lastError;

  /// Non-null when the installer could not be opened after download.
  final String? lastOpenMessage;

  /// Newest known version, cached from the last successful check (manual or
  /// silent) — non-null only when it's actually newer than the installed
  /// build and has a matching APK asset. Drives the red-dot indicator on
  /// the update icon; cleared once that version is installed or a fresh
  /// check finds nothing newer.
  final String? availableVersion;

  bool get isBusy => phase != AppUpdatePhase.idle;
  bool get hasUpdateAvailable => availableVersion != null;

  AppUpdateStatus copyWith({
    AppUpdatePhase? phase,
    double? progress,
    String? lastError,
    String? lastOpenMessage,
    String? availableVersion,
    bool clearError = false,
    bool clearOpenMessage = false,
    bool clearAvailableVersion = false,
  }) {
    return AppUpdateStatus(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastOpenMessage: clearOpenMessage
          ? null
          : (lastOpenMessage ?? this.lastOpenMessage),
      availableVersion: clearAvailableVersion
          ? null
          : (availableVersion ?? this.availableVersion),
    );
  }
}

final appUpdateProvider = NotifierProvider<AppUpdateNotifier, AppUpdateStatus>(
  AppUpdateNotifier.new,
);

class AppUpdateNotifier extends Notifier<AppUpdateStatus> {
  static const _kLastCheckedAt = 'app_update_last_checked_at';
  static const _kAvailableVersion = 'app_update_available_version';
  static const _kPendingDownloadId = 'app_update_pending_download_id';

  /// Silent checks are throttled to once a day; a manual tap always forces
  /// a fresh check regardless of this window.
  static const _checkThrottle = Duration(hours: 24);

  Timer? _pollTimer;

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  AppUpdateStatus build() {
    ref.onDispose(() => _pollTimer?.cancel());
    final prefs = ref.read(sharedPreferencesProvider);
    final cached = prefs.getString(_kAvailableVersion);
    // Resuming a download already in flight (or one that finished while the
    // app was closed) needs a real platform-channel round trip, so it can't
    // happen synchronously here — kicked off after build() returns.
    _resumePendingDownloadIfAny();
    return AppUpdateStatus(availableVersion: cached);
  }

  Future<void> _resumePendingDownloadIfAny() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final id = prefs.getInt(_kPendingDownloadId);
    if (id == null) return;
    final repo = ref.read(appUpdateRepositoryProvider);
    final ApkDownloadInfo info;
    try {
      info = await repo.queryDownload(id);
    } catch (_) {
      return;
    }
    if (!ref.mounted) return;
    switch (info.state) {
      case ApkDownloadState.running:
        state = state.copyWith(
          phase: AppUpdatePhase.downloading,
          progress: info.progress,
        );
        _startPolling(id);
      case ApkDownloadState.success:
        await _finishDownload(id, info);
      case ApkDownloadState.failed:
      case ApkDownloadState.missing:
        await prefs.remove(_kPendingDownloadId);
    }
  }

  /// Background check on app launch / resume: throttled, and never surfaces
  /// errors or dialogs — it only updates the cached [AppUpdateStatus.
  /// availableVersion] that the red dot reads. Pass [force] to bypass the
  /// throttle (not currently used, kept for a future "check now" action).
  Future<void> silentCheckForUpdate(
    String localVersion,
    String localBuildNumber, {
    bool force = false,
  }) async {
    if (!_isAndroid || state.isBusy) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final lastChecked = prefs.getInt(_kLastCheckedAt);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force &&
        lastChecked != null &&
        now - lastChecked < _checkThrottle.inMilliseconds) {
      return;
    }
    try {
      await _fetchAndRecord(localVersion, localBuildNumber);
    } catch (_) {
      // Silent — a manual tap will surface the real error if it recurs.
    }
  }

  /// Check GitHub for a newer release. Returns the release when an update is
  /// available; otherwise `null` (already latest / cancelled).
  Future<LatestRelease?> checkForUpdate(
    String localVersion,
    String localBuildNumber,
  ) async {
    if (state.isBusy) return null;
    state = state.copyWith(phase: AppUpdatePhase.checking);
    try {
      final latest = await _fetchAndRecord(localVersion, localBuildNumber);
      state = state.copyWith(phase: AppUpdatePhase.idle);
      if (latest == null) return null;
      final asset = AppUpdateLogic.pickApkAsset(
        latest.assets,
        version: latest.version,
        localBuildNumber: localBuildNumber,
      );
      if (asset == null) throw StateError('no_apk');
      return latest;
    } catch (e) {
      state = state.copyWith(phase: AppUpdatePhase.idle);
      rethrow;
    }
  }

  /// Fetches the latest release and updates the cached available-version /
  /// last-checked bookkeeping the red dot reads. Returns the release when
  /// it's newer than [localVersion] *and* has a matching APK asset;
  /// otherwise null (and the cache is cleared either way it isn't).
  Future<LatestRelease?> _fetchAndRecord(
    String localVersion,
    String localBuildNumber,
  ) async {
    final repo = ref.read(appUpdateRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final latest = await repo.fetchLatest(localVersion: localVersion);
    await prefs.setInt(_kLastCheckedAt, DateTime.now().millisecondsSinceEpoch);
    final isNewer = AppUpdateLogic.isNewer(localVersion, latest.version);
    final asset = isNewer
        ? AppUpdateLogic.pickApkAsset(
            latest.assets,
            version: latest.version,
            localBuildNumber: localBuildNumber,
          )
        : null;
    if (asset == null) {
      await prefs.remove(_kAvailableVersion);
      state = state.copyWith(clearAvailableVersion: true);
      return isNewer ? latest : null;
    }
    await prefs.setString(_kAvailableVersion, latest.version);
    state = state.copyWith(availableVersion: latest.version);
    return latest;
  }

  /// Download [asset] via the system DownloadManager (survives the app
  /// being backgrounded/killed) and open the installer once it lands.
  Future<void> downloadAndInstall({
    required ReleaseAsset asset,
    required String localVersion,
  }) async {
    if (state.isBusy) return;
    final repo = ref.read(appUpdateRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    final staleId = prefs.getInt(_kPendingDownloadId);
    if (staleId != null) {
      await repo.cancelDownload(staleId);
      await prefs.remove(_kPendingDownloadId);
    }

    state = state.copyWith(
      phase: AppUpdatePhase.downloading,
      progress: 0,
      clearError: true,
      clearOpenMessage: true,
    );
    try {
      final downloadId = await repo.enqueueDownload(url: asset.downloadUrl);
      await prefs.setInt(_kPendingDownloadId, downloadId);
      _startPolling(downloadId);
    } catch (e) {
      state = state.copyWith(phase: AppUpdatePhase.idle, lastError: '$e');
    }
  }

  void _startPolling(int downloadId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: 800),
      (_) => _pollOnce(downloadId),
    );
  }

  Future<void> _pollOnce(int downloadId) async {
    final repo = ref.read(appUpdateRepositoryProvider);
    final ApkDownloadInfo info;
    try {
      info = await repo.queryDownload(downloadId);
    } catch (_) {
      return; // Transient channel hiccup — try again next tick.
    }
    if (!ref.mounted) return;
    switch (info.state) {
      case ApkDownloadState.running:
        state = state.copyWith(
          phase: AppUpdatePhase.downloading,
          progress: info.progress,
        );
      case ApkDownloadState.success:
        await _finishDownload(downloadId, info);
      case ApkDownloadState.failed:
      case ApkDownloadState.missing:
        _pollTimer?.cancel();
        _pollTimer = null;
        await ref.read(sharedPreferencesProvider).remove(_kPendingDownloadId);
        state = state.copyWith(
          phase: AppUpdatePhase.idle,
          lastError: info.reason != null ? '下载失败（错误码 ${info.reason}）' : '下载失败',
        );
    }
  }

  Future<void> _finishDownload(int downloadId, ApkDownloadInfo info) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kPendingDownloadId);
    await prefs.remove(_kAvailableVersion);
    state = state.copyWith(
      phase: AppUpdatePhase.idle,
      clearAvailableVersion: true,
    );
    final path = info.localPath;
    if (path == null) return;
    try {
      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      if (!ref.mounted) return;
      if (result.type != ResultType.done) {
        state = state.copyWith(lastOpenMessage: result.message);
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(lastError: '$e');
    }
  }

  void clearFeedback() {
    if (state.lastError == null && state.lastOpenMessage == null) return;
    state = state.copyWith(clearError: true, clearOpenMessage: true);
  }
}
