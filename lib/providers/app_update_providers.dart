import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
    this.downloadMessage,
    this.readyVersion,
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
  final String? downloadMessage;

  /// Version of a verified APK already downloaded but not yet installed —
  /// tapping the update button installs it straight away instead of
  /// downloading again. Cleared once that version is installed or replaced.
  final String? readyVersion;

  bool get isBusy => phase != AppUpdatePhase.idle;
  bool get hasUpdateAvailable => availableVersion != null;

  AppUpdateStatus copyWith({
    AppUpdatePhase? phase,
    double? progress,
    String? lastError,
    String? lastOpenMessage,
    String? availableVersion,
    String? downloadMessage,
    String? readyVersion,
    bool clearError = false,
    bool clearOpenMessage = false,
    bool clearAvailableVersion = false,
    bool clearReadyVersion = false,
  }) {
    return AppUpdateStatus(
      phase: phase ?? this.phase,
      downloadMessage: downloadMessage ?? this.downloadMessage,
      progress: progress ?? this.progress,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastOpenMessage: clearOpenMessage
          ? null
          : (lastOpenMessage ?? this.lastOpenMessage),
      availableVersion: clearAvailableVersion
          ? null
          : (availableVersion ?? this.availableVersion),
      readyVersion: clearReadyVersion
          ? null
          : (readyVersion ?? this.readyVersion),
    );
  }
}

final appUpdateClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// A GitHub download averaging less than [kSlowDownloadBytesPerSecond] over
/// its first [kSlowDownloadWindow] switches to Gitee.
const kSlowDownloadWindow = Duration(seconds: 15);
const kSlowDownloadBytesPerSecond = 150 * 1024;

/// Split-APK ABI of this device; overridden in tests.
final appUpdateDeviceAbiProvider = Provider<String?>((ref) => currentApkAbi());

/// Whether the app is in the foreground. Android 10+ silently blocks a
/// background app from starting the installer, so a download finishing in
/// the background waits for [AppUpdateNotifier.onAppResumed] instead.
/// Overridden in tests.
final appUpdateIsForegroundProvider = Provider<bool Function()>((ref) {
  return () {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  };
});

/// Opens the system installer for the APK at a path; returns an error
/// message when it could not be opened, null otherwise. Overridden in tests.
final appUpdateInstallerProvider = Provider<Future<String?> Function(String)>(
  (ref) => (path) async {
    final result = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    return result.type == ResultType.done ? null : result.message;
  },
);

final appUpdateProvider = NotifierProvider<AppUpdateNotifier, AppUpdateStatus>(
  AppUpdateNotifier.new,
);

class AppUpdateNotifier extends Notifier<AppUpdateStatus> {
  static const _kAvailableVersion = 'app_update_available_version';
  static const _kPendingDownloadId = 'app_update_pending_download_id';

  /// `{version, downloadId, asset}` of the verified, not-yet-installed APK.
  static const _kReadyApk = 'app_update_ready_apk';

  /// Set when a download finished in the background: the installer opens on
  /// the next resume (or launch) instead.
  static const _kInstallOnResume = 'app_update_install_on_resume';
  bool _installingReady = false;

  Timer? _pollTimer;
  bool _polling = false;
  ReleaseAsset? _asset;
  List<DownloadCandidate> _remaining = [];
  DownloadCandidate? _current;
  int _lastBytes = 0;
  DateTime _lastProgress = DateTime.now();

  /// Start of the current speed window and the bytes downloaded at that
  /// moment; see [_isTooSlowOnGithub].
  DateTime? _attemptStart;
  int _attemptStartBytes = 0;
  bool _slowSwitched = false;
  static const _sessionKey = 'app_update_download_session';
  UpdateSource get sourcePreference {
    final name = ref
        .read(sharedPreferencesProvider)
        .getString('app_update_source');
    return UpdateSource.values.where((s) => s.name == name).firstOrNull ??
        UpdateSource.auto;
  }

  Future<void> setSourcePreference(UpdateSource source) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString('app_update_source', source.name);
  }

  Future<void> _saveSession() async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(
          _sessionKey,
          jsonEncode({
            'asset': _asset!.toJson(),
            'remaining': _remaining.map((c) => c.toJson()).toList(),
            'message': state.downloadMessage,
            'current': _current?.toJson(),
          }),
        );
  }

  Future<void> _enqueueNext() async {
    final repo = ref.read(appUpdateRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    while (_remaining.isNotEmpty) {
      final next = _remaining.removeAt(0);
      _current = next;
      state = state.copyWith(
        phase: AppUpdatePhase.downloading,
        progress: 0,
        downloadMessage:
            '下载中 · ${next.source.name == 'gitee' ? 'Gitee' : 'GitHub'}',
      );
      await _saveSession();
      try {
        final id = await repo.enqueueDownload(
          url: next.url,
          fileName: _asset!.name,
          size: _asset!.size,
          sha256: _asset!.sha256,
        );
        await prefs.setInt(_kPendingDownloadId, id);
        _lastBytes = 0;
        _lastProgress = ref.read(appUpdateClockProvider)();
        _attemptStart = _lastProgress;
        _attemptStartBytes = 0;
        _startPolling(id);
        return;
      } catch (_) {
        /* Try the next mirror once. */
      }
    }
    await prefs.remove(_kPendingDownloadId);
    await prefs.remove(_sessionKey);
    state = state.copyWith(
      phase: AppUpdatePhase.idle,
      lastError: '所有下载源均失败，请稍后重试',
    );
  }

  /// GitHub is often an order of magnitude slower than Gitee from mainland
  /// networks; switch once per session when a Gitee mirror is left to try.
  bool _isTooSlowOnGithub(ApkDownloadInfo info, DateTime now) {
    final start = _attemptStart;
    if (_slowSwitched ||
        start == null ||
        _current?.source != UpdateSource.github ||
        !_remaining.any((c) => c.source == UpdateSource.gitee)) {
      return false;
    }
    final elapsed = now.difference(start);
    if (elapsed < kSlowDownloadWindow) return false;
    final bytes = info.bytesDownloaded - _attemptStartBytes;
    return bytes * 1000 / elapsed.inMilliseconds < kSlowDownloadBytesPerSecond;
  }

  Future<void> _switchSource(int id) async {
    _pollTimer?.cancel();
    try {
      await ref.read(appUpdateRepositoryProvider).cancelDownload(id);
      await ref.read(sharedPreferencesProvider).remove(_kPendingDownloadId);
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(
          phase: AppUpdatePhase.idle,
          lastError: '无法停止旧下载，请重试',
        );
      }
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(downloadMessage: '正在切换下载源');
    await _enqueueNext();
  }

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  AppUpdateStatus build() {
    ref.onDispose(() => _pollTimer?.cancel());
    final prefs = ref.read(sharedPreferencesProvider);
    final cached = prefs.getString(_kAvailableVersion);
    // Resuming a download already in flight (or one that finished while the
    // app was closed) needs a real platform-channel round trip, so it can't
    // happen synchronously here — kicked off after build() returns. A
    // download that finished in the background before the process died is
    // handled by [onAppResumed], which `MainShell` also calls at launch.
    _resumePendingDownloadIfAny();
    return AppUpdateStatus(
      availableVersion: cached,
      readyVersion: _readReady()?.version,
    );
  }

  ({String version, int downloadId, ReleaseAsset asset})? _readReady() {
    final raw = ref.read(sharedPreferencesProvider).getString(_kReadyApk);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        version: json['version'] as String,
        downloadId: json['downloadId'] as int,
        asset: ReleaseAsset.fromJson(
          Map<String, dynamic>.from(json['asset'] as Map),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveReady(int downloadId, ReleaseAsset asset) async {
    final previous = _readReady();
    if (previous != null && previous.downloadId != downloadId) {
      await _discardReady();
    }
    final version =
        AppUpdateLogic.versionOfApkName(asset.name) ?? state.availableVersion;
    if (version == null) return;
    await ref
        .read(sharedPreferencesProvider)
        .setString(
          _kReadyApk,
          jsonEncode({
            'version': version,
            'downloadId': downloadId,
            'asset': asset.toJson(),
          }),
        );
    if (ref.mounted) state = state.copyWith(readyVersion: version);
  }

  /// Drops the ready APK: its DownloadManager record and file go too.
  Future<void> _discardReady() async {
    final ready = _readReady();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_kReadyApk);
    await prefs.remove(_kInstallOnResume);
    if (ready != null) {
      try {
        await ref
            .read(appUpdateRepositoryProvider)
            .cancelDownload(ready.downloadId);
      } catch (_) {
        /* The file is app-private; a stray one is harmless. */
      }
    }
    if (ref.mounted) state = state.copyWith(clearReadyVersion: true);
  }

  /// Opens the installer for the already-downloaded APK after re-verifying
  /// it. Returns false — and forgets the APK — when it is gone or no longer
  /// matches its checksum, so the caller can fall back to downloading.
  Future<bool> installReady() async {
    final ready = _readReady();
    if (ready == null || _installingReady) return false;
    _installingReady = true;
    try {
      final repo = ref.read(appUpdateRepositoryProvider);
      var valid = false;
      String? path;
      try {
        valid = await repo.verifyDownload(ready.downloadId);
        if (valid) {
          path = (await repo.queryDownload(ready.downloadId)).localPath;
        }
      } catch (_) {
        valid = false;
      }
      if (!ref.mounted) return false;
      if (!valid || path == null) {
        await _discardReady();
        return false;
      }
      await _openInstaller(path);
      return true;
    } finally {
      _installingReady = false;
    }
  }

  /// Opens the installer a background-finished download deferred; `MainShell`
  /// calls this at launch and on every resume. An APK no newer than
  /// [localVersion] was installed meanwhile (e.g. from the notification) and
  /// is dropped instead.
  Future<void> onAppResumed(String localVersion) async {
    final ready = state.readyVersion;
    if (ready != null && !AppUpdateLogic.isNewer(localVersion, ready)) {
      await _discardReady();
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    if (!(prefs.getBool(_kInstallOnResume) ?? false) || state.isBusy) return;
    await prefs.remove(_kInstallOnResume);
    if (!ref.mounted) return;
    await installReady();
  }

  Future<void> _openInstaller(String path) async {
    try {
      final message = await ref.read(appUpdateInstallerProvider)(path);
      if (!ref.mounted) return;
      if (message != null) state = state.copyWith(lastOpenMessage: message);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(lastError: '$e');
    }
    // The installer is up, so the "tap to install" notification is moot.
    await ref.read(appUpdateRepositoryProvider).dismissInstallNotification();
  }

  Future<void> _resumePendingDownloadIfAny() async {
    await Future<void>.delayed(Duration.zero);
    if (!ref.mounted || state.isBusy) return;
    final prefs = ref.read(sharedPreferencesProvider);
    final id = prefs.getInt(_kPendingDownloadId);
    if (id == null) return;
    final session = prefs.getString(_sessionKey);
    if (session == null) {
      await ref.read(appUpdateRepositoryProvider).cancelDownload(id);
      await prefs.remove(_kPendingDownloadId);
      if (ref.mounted) state = state.copyWith(lastError: '旧下载缺少校验信息，请重新检查更新');
      return;
    }
    try {
      final json = jsonDecode(session) as Map<String, dynamic>;
      _asset = ReleaseAsset.fromJson(
        Map<String, dynamic>.from(json['asset'] as Map),
      );
      _remaining = (json['remaining'] as List)
          .map(
            (c) =>
                DownloadCandidate.fromJson(Map<String, dynamic>.from(c as Map)),
          )
          .toList();
      _current = json['current'] is Map
          ? DownloadCandidate.fromJson(
              Map<String, dynamic>.from(json['current'] as Map),
            )
          : null;
      if (!_asset!.isVerified) throw StateError('invalid session');
      state = state.copyWith(
        phase: AppUpdatePhase.downloading,
        downloadMessage: json['message'] as String?,
      );
    } catch (_) {
      await ref.read(appUpdateRepositoryProvider).cancelDownload(id);
      await prefs.remove(_kPendingDownloadId);
      await prefs.remove(_sessionKey);
      return;
    }
    final repo = ref.read(appUpdateRepositoryProvider);
    final ApkDownloadInfo info;
    try {
      info = await repo.queryDownload(id);
    } catch (_) {
      if (ref.mounted) _startPolling(id);
      return;
    }
    if (!ref.mounted) return;
    _lastProgress = ref.read(appUpdateClockProvider)();
    _lastBytes = info.bytesDownloaded;
    _attemptStart = _lastProgress;
    _attemptStartBytes = info.bytesDownloaded;
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
        await _switchSource(id);
    }
  }

  /// Background check on every app launch and resume. Never surfaces errors
  /// or dialogs — it only updates the cached [AppUpdateStatus.availableVersion]
  /// that the red dot reads.
  Future<void> silentCheckForUpdate(
    String localVersion,
    String localBuildNumber,
  ) async {
    if (!_isAndroid || state.isBusy) return;
    await _dropStaleAvailableVersion(localVersion);
    try {
      await _fetchAndRecord(localVersion, localBuildNumber);
    } catch (_) {
      // Silent — a manual tap will surface the real error if it recurs.
    }
  }

  /// Clears the cached red-dot version once it is no longer newer than the
  /// installed build (e.g. right after installing it), without waiting for a
  /// network check that may fail.
  Future<void> _dropStaleAvailableVersion(String localVersion) async {
    final ready = state.readyVersion;
    if (ready != null && !AppUpdateLogic.isNewer(localVersion, ready)) {
      // Installed (or superseded locally) — the APK is no longer needed.
      await _discardReady();
    }
    final cached = state.availableVersion;
    if (cached == null || AppUpdateLogic.isNewer(localVersion, cached)) return;
    await ref.read(sharedPreferencesProvider).remove(_kAvailableVersion);
    state = state.copyWith(clearAvailableVersion: true);
  }

  /// Check both sources for a newer release. Returns the release when an update is
  /// available; otherwise `null` (already latest / cancelled).
  Future<LatestRelease?> checkForUpdate(
    String localVersion,
    String localBuildNumber,
  ) async {
    if (state.isBusy) return null;
    await _dropStaleAvailableVersion(localVersion);
    state = state.copyWith(
      phase: AppUpdatePhase.checking,
      downloadMessage: '正在检查更新',
    );
    try {
      final latest = await _fetchAndRecord(localVersion, localBuildNumber);
      state = state.copyWith(phase: AppUpdatePhase.idle);
      if (latest == null) return null;
      final asset = AppUpdateLogic.pickApkAsset(
        latest.assets,
        version: latest.version,
        localBuildNumber: localBuildNumber,
        deviceAbi: ref.read(appUpdateDeviceAbiProvider),
      );
      if (asset == null) throw StateError('no_apk');
      return latest;
    } catch (e) {
      state = state.copyWith(phase: AppUpdatePhase.idle);
      rethrow;
    }
  }

  /// Fetches the latest release and updates the cached available-version
  /// the red dot reads. Returns the release when
  /// it's newer than [localVersion] *and* has a matching APK asset;
  /// otherwise null (and the cache is cleared either way it isn't).
  Future<LatestRelease?> _fetchAndRecord(
    String localVersion,
    String localBuildNumber,
  ) async {
    final repo = ref.read(appUpdateRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);
    final deviceAbi = ref.read(appUpdateDeviceAbiProvider);
    final latest = AppUpdateLogic.selectRelease(
      await repo.fetchReleases(localVersion: localVersion),
      localBuildNumber,
      deviceAbi: deviceAbi,
    );
    final isNewer = AppUpdateLogic.isNewer(localVersion, latest.version);
    final asset = isNewer
        ? AppUpdateLogic.pickApkAsset(
            latest.assets,
            version: latest.version,
            localBuildNumber: localBuildNumber,
            deviceAbi: deviceAbi,
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
    final ready = _readReady();
    if (ready != null) {
      final same =
          ready.asset.sha256.toLowerCase() == asset.sha256.toLowerCase();
      // Already downloaded and still intact: install, don't fetch it again.
      if (same && await installReady()) return;
      // A different (newer) package replaces it.
      if (!same) await _discardReady();
      if (!ref.mounted) return;
    }
    final repo = ref.read(appUpdateRepositoryProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    state = state.copyWith(
      phase: AppUpdatePhase.downloading,
      progress: 0,
      clearError: true,
      clearOpenMessage: true,
    );
    try {
      final staleId = prefs.getInt(_kPendingDownloadId);
      if (staleId != null) {
        await repo.cancelDownload(staleId);
        await prefs.remove(_kPendingDownloadId);
      }
      if (!asset.isVerified || asset.candidates.isEmpty) {
        throw StateError('安装包缺少有效校验信息，请重新检查更新');
      }
      _asset = asset;
      _slowSwitched = false;
      state = state.copyWith(downloadMessage: '正在探测下载源');
      _remaining = List.of(await repo.rankCandidates(asset, sourcePreference));
      await _enqueueNext();
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
    if (_polling) return;
    _polling = true;
    try {
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
          final now = ref.read(appUpdateClockProvider)();
          if (info.waitingForNetwork || info.bytesDownloaded > _lastBytes) {
            _lastProgress = now;
          }
          _lastBytes = info.bytesDownloaded;
          if (!info.waitingForNetwork &&
              now.difference(_lastProgress).inSeconds >=
                  (_lastBytes == 0 ? 30 : 60)) {
            await _switchSource(downloadId);
            return;
          }
          if (info.waitingForNetwork) {
            // Time spent offline says nothing about the source's speed.
            _attemptStart = now;
            _attemptStartBytes = info.bytesDownloaded;
          } else if (_isTooSlowOnGithub(info, now)) {
            // Keep GitHub as the fallback in case Gitee fails.
            _slowSwitched = true;
            _remaining.add(_current!);
            await _switchSource(downloadId);
            return;
          }
          state = state.copyWith(
            phase: AppUpdatePhase.downloading,
            progress: info.progress,
          );
        case ApkDownloadState.success:
          await _finishDownload(downloadId, info);
        case ApkDownloadState.failed:
        case ApkDownloadState.missing:
          await _switchSource(downloadId);
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _finishDownload(int downloadId, ApkDownloadInfo info) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    state = state.copyWith(downloadMessage: '正在校验安装包');
    var valid = false;
    try {
      valid = await ref
          .read(appUpdateRepositoryProvider)
          .verifyDownload(downloadId);
    } catch (_) {
      /* Never install when native verification is unavailable. */
    }
    if (!ref.mounted) return;
    if (!valid) {
      await _switchSource(downloadId);
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_sessionKey);
    await prefs.remove(_kPendingDownloadId);
    // Keep the DownloadManager record: if the user backs out of the
    // installer, the next tap re-verifies and installs this same file.
    final asset = _asset;
    if (asset != null) await _saveReady(downloadId, asset);
    if (!ref.mounted) return;
    state = state.copyWith(phase: AppUpdatePhase.idle);
    final path = info.localPath;
    if (path == null) {
      state = state.copyWith(lastError: '无法打开下载文件，请重新检查更新');
      return;
    }
    if (ref.read(appUpdateIsForegroundProvider)()) {
      await prefs.remove(_kInstallOnResume);
      await _openInstaller(path);
    } else {
      // Android 10+ would silently drop the installer launch; the native
      // receiver's notification covers the background, and returning to
      // the app opens it.
      await prefs.setBool(_kInstallOnResume, true);
    }
  }

  void clearFeedback() {
    if (state.lastError == null && state.lastOpenMessage == null) return;
    state = state.copyWith(clearError: true, clearOpenMessage: true);
  }
}
