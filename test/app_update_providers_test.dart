import 'dart:convert';
import 'dart:async';

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
              size: 100,
              sha256: 'a' * 64,
              candidates: [
                DownloadCandidate(
                  UpdateSource.gitee,
                  'https://example.com/$version.apk',
                ),
              ],
            ),
          ]
        : const [],
  );
}

class _FakeAppUpdateRepository extends AppUpdateRepository {
  int fetchLatestCalls = 0;
  Object? fetchLatestError;
  LatestRelease? nextRelease;

  bool valid = true;
  int queryCalls = 0;
  Completer<ApkDownloadInfo>? blockedQuery;
  @override
  Future<bool> verifyDownload(int downloadId) async => valid;
  @override
  Future<List<DownloadCandidate>> rankCandidates(
    ReleaseAsset asset,
    UpdateSource preference,
  ) async => asset.candidates;
  int enqueueCalls = 0;
  final List<String> enqueuedUrls = [];
  int _nextId = 1;
  final Map<int, ApkDownloadInfo> downloadInfos = {};
  final List<int> cancelled = [];

  @override
  Future<List<LatestRelease>> fetchReleases({String? localVersion}) async {
    fetchLatestCalls++;
    final err = fetchLatestError;
    if (err != null) throw err;
    return [nextRelease!];
  }

  @override
  Future<int> enqueueDownload({
    required String url,
    String fileName = 'FitnessPlan-update.apk',
    int size = 0,
    String sha256 = '',
  }) async {
    enqueueCalls++;
    enqueuedUrls.add(url);
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
    queryCalls++;
    if (blockedQuery != null) return blockedQuery!.future;
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

Future<void> _storeSession(SharedPreferences prefs) async {
  await prefs.setString(
    'app_update_download_session',
    jsonEncode({
      'asset': _release('2.0.0').assets.first.toJson(),
      'remaining': [],
    }),
  );
}

void main() {
  late _FakeAppUpdateRepository repo;
  late SharedPreferences prefs;
  late ProviderContainer container;
  late DateTime now;
  var disposed = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = _FakeAppUpdateRepository();
    now = DateTime(2026, 10, 16);
    disposed = false;
    container = ProviderContainer(
      overrides: [
        appUpdateClockProvider.overrideWithValue(() => now),
        sharedPreferencesProvider.overrideWithValue(prefs),
        appUpdateRepositoryProvider.overrideWithValue(repo),
      ],
    );
  });

  tearDown(() {
    if (!disposed) container.dispose();
  });
  void updateTest(String name, Future<void> Function(WidgetTester) body) {
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        container.dispose();
        disposed = true;
      }
    });
  }

  group('silentCheckForUpdate', () {
    test(
      'sets availableVersion when a newer release has a matching asset',
      () async {
        repo.nextRelease = _release('2.0.0');
        await container
            .read(appUpdateProvider.notifier)
            .silentCheckForUpdate('1.0.0', '2008');

        final status = container.read(appUpdateProvider);
        expect(status.hasUpdateAvailable, isTrue);
        expect(status.availableVersion, '2.0.0');
        expect(prefs.getString('app_update_available_version'), '2.0.0');
      },
    );

    test(
      'does not flag an update when already on the latest version',
      () async {
        repo.nextRelease = _release('1.0.0');
        await container
            .read(appUpdateProvider.notifier)
            .silentCheckForUpdate('1.0.0', '2008');

        expect(container.read(appUpdateProvider).hasUpdateAvailable, isFalse);
      },
    );

    test(
      'does not flag an update when no asset matches this ABI channel',
      () async {
        repo.nextRelease = _release('2.0.0', withAsset: false);
        await container
            .read(appUpdateProvider.notifier)
            .silentCheckForUpdate('1.0.0', '2008');

        expect(container.read(appUpdateProvider).hasUpdateAvailable, isFalse);
      },
    );

    test('checks again on every call, including a second entry', () async {
      repo.nextRelease = _release('2.0.0');
      final notifier = container.read(appUpdateProvider.notifier);
      await notifier.silentCheckForUpdate('1.0.0', '2008');
      await notifier.silentCheckForUpdate('1.0.0', '2008');
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

    test(
      'clears a cached version once it is installed, even offline',
      () async {
        await prefs.setString('app_update_available_version', '2.6.1');
        repo.fetchLatestError = Exception('offline');
        final notifier = container.read(appUpdateProvider.notifier);
        expect(container.read(appUpdateProvider).availableVersion, '2.6.1');

        await notifier.silentCheckForUpdate('2.6.1', '79');

        expect(container.read(appUpdateProvider).hasUpdateAvailable, isFalse);
        expect(prefs.getString('app_update_available_version'), isNull);
      },
    );

    test('keeps a cached version that is still newer when offline', () async {
      await prefs.setString('app_update_available_version', '2.7.0');
      repo.fetchLatestError = Exception('offline');
      await container
          .read(appUpdateProvider.notifier)
          .silentCheckForUpdate('2.6.1', '79');
      expect(container.read(appUpdateProvider).availableVersion, '2.7.0');
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
      await container
          .read(appUpdateProvider.notifier)
          .downloadAndInstall(
            asset: ReleaseAsset(
              name: 'a.apk',
              downloadUrl: 'https://example.com/a.apk',
              size: 100,
              sha256: 'a' * 64,
              candidates: const [
                DownloadCandidate(
                  UpdateSource.gitee,
                  'https://example.com/a.apk',
                ),
              ],
            ),
            localVersion: '1.0.0',
          );
      expect(container.read(appUpdateProvider).lastError, isNull);
      expect(repo.enqueueCalls, 1);
      expect(prefs.getInt('app_update_pending_download_id'), isNotNull);
      expect(
        container.read(appUpdateProvider).phase,
        AppUpdatePhase.downloading,
      );
    });

    test(
      'cancels a stale pending download before starting a new one',
      () async {
        await prefs.setInt('app_update_pending_download_id', 999);
        await container
            .read(appUpdateProvider.notifier)
            .downloadAndInstall(
              asset: ReleaseAsset(
                name: 'a.apk',
                downloadUrl: 'https://example.com/a.apk',
                size: 100,
                sha256: 'a' * 64,
                candidates: const [
                  DownloadCandidate(
                    UpdateSource.gitee,
                    'https://example.com/a.apk',
                  ),
                ],
              ),
              localVersion: '1.0.0',
            );
        expect(repo.cancelled, [999]);
      },
    );
  });

  group('resuming a pending download on a fresh container', () {
    test(
      'reflects a download that finished while the app was closed',
      () async {
        await _storeSession(prefs);
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
      },
    );

    test('reflects an in-progress download and keeps polling', () async {
      await _storeSession(prefs);
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
  ReleaseAsset mirrors() => ReleaseAsset(
    name: 'update.apk',
    downloadUrl: 'https://gitee.com/a.apk',
    size: 100,
    sha256: 'a' * 64,
    candidates: const [
      DownloadCandidate(UpdateSource.gitee, 'https://gitee.com/a.apk'),
      DownloadCandidate(UpdateSource.github, 'https://github.com/a.apk'),
    ],
  );

  Future<void> begin() => container
      .read(appUpdateProvider.notifier)
      .downloadAndInstall(asset: mirrors(), localVersion: '1.0.0');

  updateTest('failed downloads switch once then stop when all sources fail', (
    tester,
  ) async {
    await begin();
    repo.downloadInfos[1] = const ApkDownloadInfo(
      state: ApkDownloadState.failed,
      bytesDownloaded: 0,
      totalBytes: 100,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 2);
    expect(repo.cancelled, [1]);
    repo.downloadInfos[2] = const ApkDownloadInfo(
      state: ApkDownloadState.failed,
      bytesDownloaded: 0,
      totalBytes: 100,
    );
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 2);
    expect(container.read(appUpdateProvider).phase, AppUpdatePhase.idle);
    expect(container.read(appUpdateProvider).lastError, isNotNull);
    expect(prefs.getString('app_update_download_session'), isNull);
  });

  updateTest('no initial bytes switches after 30 seconds', (tester) async {
    await begin();
    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 2);
  });

  updateTest('progress stalls only after 60 seconds', (tester) async {
    await begin();
    repo.downloadInfos[1] = const ApkDownloadInfo(
      state: ApkDownloadState.running,
      bytesDownloaded: 20,
      totalBytes: 100,
    );
    await tester.pump(const Duration(seconds: 1));
    now = now.add(const Duration(seconds: 40));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 1);
    now = now.add(const Duration(seconds: 21));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 2);
  });

  Future<void> beginOnGithub() => container
      .read(appUpdateProvider.notifier)
      .downloadAndInstall(
        asset: ReleaseAsset(
          name: 'update.apk',
          downloadUrl: 'https://github.com/a.apk',
          size: 100 << 20,
          sha256: 'a' * 64,
          candidates: const [
            DownloadCandidate(UpdateSource.github, 'https://github.com/a.apk'),
            DownloadCandidate(UpdateSource.gitee, 'https://gitee.com/a.apk'),
          ],
        ),
        localVersion: '1.0.0',
      );

  ApkDownloadInfo running(int bytes) => ApkDownloadInfo(
    state: ApkDownloadState.running,
    bytesDownloaded: bytes,
    totalBytes: 100 << 20,
  );

  updateTest(
    'slow GitHub switches to Gitee once and keeps GitHub as fallback',
    (tester) async {
      await beginOnGithub();
      // 40 KB/s over the first 16 s — what GitHub manages from mainland links.
      now = now.add(const Duration(seconds: 16));
      repo.downloadInfos[1] = running(16 * 40 * 1024);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.enqueuedUrls, [
        'https://github.com/a.apk',
        'https://gitee.com/a.apk',
      ]);
      expect(repo.cancelled, [1]);
      final session =
          jsonDecode(prefs.getString('app_update_download_session')!) as Map;
      expect((session['remaining'] as List).single['source'], 'github');

      // Gitee being slow too must not bounce back to GitHub.
      now = now.add(const Duration(seconds: 16));
      repo.downloadInfos[2] = running(1024);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.enqueueCalls, 2);
    },
  );

  updateTest('a fast GitHub download is left alone', (tester) async {
    await beginOnGithub();
    now = now.add(const Duration(seconds: 16));
    repo.downloadInfos[1] = running(16 * 400 * 1024);
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 1);
  });

  updateTest('offline waiting resets stall timer without switching', (
    tester,
  ) async {
    await begin();
    repo.downloadInfos[1] = const ApkDownloadInfo(
      state: ApkDownloadState.running,
      bytesDownloaded: 0,
      totalBytes: 100,
      waitingForNetwork: true,
    );
    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 1);
    repo.downloadInfos[1] = const ApkDownloadInfo(
      state: ApkDownloadState.running,
      bytesDownloaded: 0,
      totalBytes: 100,
    );
    now = now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 1);
  });

  updateTest('checksum failure never installs and tries other mirror', (
    tester,
  ) async {
    await begin();
    repo.valid = false;
    repo.downloadInfos[1] = const ApkDownloadInfo(
      state: ApkDownloadState.success,
      bytesDownloaded: 100,
      totalBytes: 100,
      localPath: '/bad.apk',
    );
    await tester.pump(const Duration(seconds: 1));
    expect(repo.enqueueCalls, 2);
    expect(repo.cancelled, [1]);
    expect(container.read(appUpdateProvider).lastOpenMessage, isNull);
  });

  updateTest('overlapping polling callbacks do not duplicate fallback', (
    tester,
  ) async {
    await begin();
    repo.blockedQuery = Completer<ApkDownloadInfo>();
    await tester.pump(const Duration(seconds: 1));
    final calls = repo.queryCalls;
    await tester.pump(const Duration(seconds: 4));
    expect(repo.queryCalls, calls);
    repo.blockedQuery!.complete(
      const ApkDownloadInfo(
        state: ApkDownloadState.failed,
        bytesDownloaded: 0,
        totalBytes: 100,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(repo.enqueueCalls, 2);
    repo.blockedQuery = null;
  });

  updateTest('legacy downloads without integrity session are cancelled', (
    tester,
  ) async {
    await prefs.setInt('app_update_pending_download_id', 99);
    container.read(appUpdateProvider);
    await tester.pump(const Duration(milliseconds: 1));
    expect(repo.cancelled, [99]);
    expect(prefs.getInt('app_update_pending_download_id'), isNull);
  });

  updateTest('restores remaining mirrors after process restart', (
    tester,
  ) async {
    await prefs.setInt('app_update_pending_download_id', 42);
    await prefs.setString(
      'app_update_download_session',
      jsonEncode({
        'asset': mirrors().toJson(),
        'remaining': [mirrors().candidates.last.toJson()],
        'message': 'Gitee',
      }),
    );
    repo.downloadInfos[42] = const ApkDownloadInfo(
      state: ApkDownloadState.failed,
      bytesDownloaded: 0,
      totalBytes: 100,
    );
    container.read(appUpdateProvider);
    await tester.pump(const Duration(milliseconds: 1));
    expect(repo.cancelled, [42]);
    expect(repo.enqueueCalls, 1);
    expect(
      container.read(appUpdateProvider).downloadMessage,
      contains('GitHub'),
    );
  });
}
