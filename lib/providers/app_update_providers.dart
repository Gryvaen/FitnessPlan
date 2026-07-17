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
  });

  final AppUpdatePhase phase;

  /// 0..1 while [phase] is [AppUpdatePhase.downloading]; 0 means connecting.
  final double progress;
  final String? lastError;

  /// Non-null when the installer could not be opened after download.
  final String? lastOpenMessage;

  bool get isBusy => phase != AppUpdatePhase.idle;

  AppUpdateStatus copyWith({
    AppUpdatePhase? phase,
    double? progress,
    String? lastError,
    String? lastOpenMessage,
    bool clearError = false,
    bool clearOpenMessage = false,
  }) {
    return AppUpdateStatus(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastOpenMessage: clearOpenMessage
          ? null
          : (lastOpenMessage ?? this.lastOpenMessage),
    );
  }
}

final appUpdateProvider = NotifierProvider<AppUpdateNotifier, AppUpdateStatus>(
  AppUpdateNotifier.new,
);

class AppUpdateNotifier extends Notifier<AppUpdateStatus> {
  @override
  AppUpdateStatus build() => const AppUpdateStatus();

  /// Check GitHub for a newer release. Returns the release when an update is
  /// available; otherwise `null` (already latest / no APK / cancelled).
  Future<LatestRelease?> checkForUpdate(
    String localVersion,
    String localBuildNumber,
  ) async {
    if (state.isBusy) return null;
    state = const AppUpdateStatus(phase: AppUpdatePhase.checking);
    try {
      final repo = ref.read(appUpdateRepositoryProvider);
      final latest = await repo.fetchLatest(localVersion: localVersion);
      if (!AppUpdateLogic.isNewer(localVersion, latest.version)) {
        state = const AppUpdateStatus();
        return null;
      }
      final asset = AppUpdateLogic.pickApkAsset(
        latest.assets,
        version: latest.version,
        localBuildNumber: localBuildNumber,
      );
      if (asset == null) {
        state = const AppUpdateStatus();
        throw StateError('no_apk');
      }
      state = const AppUpdateStatus();
      return latest;
    } catch (e) {
      state = const AppUpdateStatus();
      rethrow;
    }
  }

  /// Download [asset] in the background and open the APK when finished.
  Future<void> downloadAndInstall({
    required ReleaseAsset asset,
    required String localVersion,
  }) async {
    if (state.isBusy) return;
    state = const AppUpdateStatus(phase: AppUpdatePhase.downloading);
    try {
      final repo = ref.read(appUpdateRepositoryProvider);
      final path = await repo.downloadApk(
        asset.downloadUrl,
        localVersion: localVersion,
        onProgress: (p) {
          if (state.phase != AppUpdatePhase.downloading) return;
          state = AppUpdateStatus(
            phase: AppUpdatePhase.downloading,
            progress: p,
          );
        },
      );
      state = const AppUpdateStatus();
      final result = await OpenFilex.open(
        path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) {
        state = AppUpdateStatus(lastOpenMessage: result.message);
      }
    } catch (e) {
      state = AppUpdateStatus(lastError: '$e');
    }
  }

  void clearFeedback() {
    if (state.lastError == null && state.lastOpenMessage == null) return;
    state = state.copyWith(clearError: true, clearOpenMessage: true);
  }
}
