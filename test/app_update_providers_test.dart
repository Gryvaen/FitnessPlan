import 'package:diet/data/repositories/app_update_repository.dart';
import 'package:diet/providers/app_update_providers.dart';
import 'package:diet/providers/core_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Covers the red-dot bookkeeping (AppUpdateNotifier.silentCheckForUpdate)
// and the download-persistence/resume logic added for
// lib/providers/app_update_providers.dart — the parts that don't need an
// actual Android device to exercise. The DownloadManager plumbing itself
// (ApkDownloader.kt / ApkDownloadCompleteReceiver.kt) needs on-device
// verification (see the "验证" section of the update-flow plan).

LatestRelease _release(String version, {bool withAsset = true}) {
  return LatestRelease(
    tagName: 'v$version',
    version: version,
    body: '',
    assets: withAsset
        ? [
            ReleaseAsset(
              name: 'FitnessPlan-$version-android-arm64-v8a.apk',
              downloadUrl: 'https://example.com/$version.apk',
            ),
          ]
        : const [],
  );
}

class _FakeAppUpdateRepository extends AppUpdateRepository {
  int fetchLatestCalls = 0;
  Object? fetchLatestError;
  LatestRelease? nextRelease;

  int enqueueCalls = 0;
  int _nextId = 1;
  final Map<int, ApkDownloadInfo> downloadInfos = {};
  final List<int> cancelled = [];

  @override
  Future<LatestRelease> fetchLatest({String? localVersion}) async {
    fetchLatestCalls++;
    final err = fetchLatestError;
    if (err != null) throw err;
    return nextRelease!;
  }

  @override
  Future<int> enqueueDownload({
    required String url,
    String fileName = 'FitnessPlan-update.apk',
  }) async {
    enqueueCalls++;
    final id = _nextId++;
    downloadInfos[id] = const ApkDownloadInfo(
      state: ApkDownloadState.running,
      bytesDownloaded: 0,
      totalBytes: 100,
    );
    return id;
  }

  @override
  Future<ApkDownloadInfo> queryDownload(int downloadId) async {
    return downloadInfos[downloadId] ??
        const ApkDownloadInfo(
          state: ApkDownloadState.missing,
          bytesDownloaded: 0,
          totalBytes: 0,
        );
  }

  @override
  Future<void> cancelDownload(int downloadId) async {
    cancelled.add(downloadId);
  }
}

void main() {
  late _FakeAppUpdateRepository repo;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _FakeAppUpdateRepository();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appUpdateRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('silentCheckForUpdate', () {
    test('sets availableVersion when a newer release has a matching asset',
        () async {
      repo.nextRelease = _release('2.0.0');
      await container
          .read(appUpdateProvider.notifier)
          .silentCheckForUpdate('1.0.0', '2008');

      final status = container.read(appUpdateProvider);
      expect(status.hasUpdateAvailable, isTrue);
      expect(status.availableVersion, '2.0.0');
      expect(prefs.getString('app_update_available_version'), '2.0.0');
    });

    test('does not flag an update when already on the latest version',
        () async {
      repo.nextRelease = _release('1.0.0');
      await container
          .read(appUpdateProvider.notifier)
          .silentCheckForUpdate('1.0.0', '2008');

      expect(container.read(appUpdateProvider).hasUpdateAvailable, isFalse);
    });

    test('does not flag an update when no asset matches this ABI channel',
        () async {
      repo.nextRelease = _release('2.0.0', withAsset: false);
      await container
          .read(appUpdateProvider.notifier)
          .silentCheckForUpdate('1.0.0', '2008');

      expect(container.read(appUpdateProvider).hasUpdateAvailable, isFalse);
    });

    test('is throttled to one real check within the window', () async {
      repo.nextRelease = _release('2.0.0');
      final notifier = container.read(appUpdateProvider.notifier);
      await notifier.silentCheckForUpdate('1.0.0', '2008');
      await notifier.silentCheckForUpdate('1.0.0', '2008');
      expect(repo.fetchLatestCalls, 1);
    });

    test('force bypasses the throttle', () async {
      repo.nextRelease = _release('2.0.0');
      final notifier = container.read(appUpdateProvider.notifier);
      await notifier.silentCheckForUpdate('1.0.0', '2008');
      await notifier.silentCheckForUpdate('1.0.0', '2008', force: true);
      expect(repo.fetchLatestCalls, 2);
    });

    test('swallows network errors without throwing', () async {
      repo.fetchLatestError = Exception('boom');
      await container
          .read(appUpdateProvider.notifier)
          .silentCheckForUpdate('1.0.0', '2008');
      expect(container.read(appUpdateProvider).hasUpdateAvailable, isFalse);
      expect(container.read(appUpdateProvider).lastError, isNull);
    });
  });

  group('checkForUpdate (manual)', () {
    test('returns the release and records it for the red dot', () async {
      repo.nextRelease = _release('2.0.0');
      final result = await container
          .read(appUpdateProvider.notifier)
          .checkForUpdate('1.0.0', '2008');
      expect(result?.version, '2.0.0');
      expect(container.read(appUpdateProvider).hasUpdateAvailable, isTrue);
    });

    test('throws StateError(no_apk) when nothing matches this channel', () {
      repo.nextRelease = _release('2.0.0', withAsset: false);
      expect(
        () => container
            .read(appUpdateProvider.notifier)
            .checkForUpdate('1.0.0', '2008'),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'no_apk'),
        ),
      );
    });
  });

  group('downloadAndInstall persistence', () {
    test('persists the download id so a restart can resume it', () async {
      await container.read(appUpdateProvider.notifier).downloadAndInstall(
            asset: const ReleaseAsset(
              name: 'a.apk',
              downloadUrl: 'https://example.com/a.apk',
            ),
            localVersion: '1.0.0',
          );
      expect(repo.enqueueCalls, 1);
      expect(prefs.getInt('app_update_pending_download_id'), isNotNull);
      expect(container.read(appUpdateProvider).phase, AppUpdatePhase.downloading);
    });

    test('cancels a stale pending download before starting a new one',
        () async {
      await prefs.setInt('app_update_pending_download_id', 999);
      await container.read(appUpdateProvider.notifier).downloadAndInstall(
            asset: const ReleaseAsset(
              name: 'a.apk',
              downloadUrl: 'https://example.com/a.apk',
            ),
            localVersion: '1.0.0',
          );
      expect(repo.cancelled, [999]);
    });
  });

  group('resuming a pending download on a fresh container', () {
    test('reflects a download that finished while the app was closed',
        () async {
      await prefs.setInt('app_update_pending_download_id', 7);
      repo.downloadInfos[7] = const ApkDownloadInfo(
        state: ApkDownloadState.success,
        bytesDownloaded: 100,
        totalBytes: 100,
        localPath: null, // no OpenFilex round trip needed for this check
      );
      // Reading the provider triggers Notifier.build(), which kicks off
      // the resume check as a fire-and-forget Future.
      container.read(appUpdateProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(prefs.getInt('app_update_pending_download_id'), isNull);
      expect(container.read(appUpdateProvider).phase, AppUpdatePhase.idle);
    });

    test('reflects an in-progress download and keeps polling', () async {
      await prefs.setInt('app_update_pending_download_id', 8);
      repo.downloadInfos[8] = const ApkDownloadInfo(
        state: ApkDownloadState.running,
        bytesDownloaded: 40,
        totalBytes: 100,
      );
      container.read(appUpdateProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final status = container.read(appUpdateProvider);
      expect(status.phase, AppUpdatePhase.downloading);
      expect(status.progress, 0.4);
    });
  });
}
