import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:diet/data/repositories/app_update_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const apk = 'FitnessPlan-3.0.0-android-arm64-v8a.apk';
final hash = 'a' * 64;
Map<String, dynamic> release(
  String host, {
  String version = '3.0.0',
  bool draft = false,
}) => {
  'tag_name': 'v$version',
  'draft': draft,
  'body': 'notes',
  'assets': [
    {'name': apk, 'browser_download_url': 'https://$host/app.apk'},
    {
      'name': 'update-manifest.json',
      'browser_download_url': 'https://$host/manifest',
    },
  ],
};
String manifest({String? sha, String version = '3.0.0'}) => jsonEncode({
  'schemaVersion': 1,
  'version': version,
  'assets': [
    {'name': apk, 'size': 100, 'sha256': sha ?? hash},
  ],
});

void main() {
  test('falls back to Gitee download links when its API is blocked', () async {
    const universal = 'FitnessPlan-3.0.0-android.apk';
    const giteeBase = 'https://gitee.com/$kGiteeRepo/releases/download/v3.0.0';
    final bigManifest = jsonEncode({
      'schemaVersion': 1,
      'version': '3.0.0',
      'assets': [
        {'name': apk, 'size': 100, 'sha256': hash},
        {'name': universal, 'size': kGiteeMaxAssetBytes + 1, 'sha256': hash},
      ],
    });
    final repo = AppUpdateRepository(
      client: MockClient((req) async {
        final url = req.url.toString();
        if (url == '$giteeBase/update-manifest.json' ||
            req.url.path == '/manifest') {
          return http.Response(bigManifest, 200);
        }
        if (req.url.host == 'gitee.com') {
          return http.Response('403 Forbidden (Rate Limit Exceeded)', 403);
        }
        final j = release('github.com');
        (j['assets'] as List).add({
          'name': universal,
          'browser_download_url': 'https://github.com/universal.apk',
        });
        return http.Response(jsonEncode([j]), 200);
      }),
    );
    final releases = await repo.fetchReleases();
    final gitee = releases.where(
      (r) => r.assets.any(
        (a) => a.candidates.any((c) => c.source == UpdateSource.gitee),
      ),
    );
    // The universal APK is over Gitee's limit, so it gets no Gitee link.
    expect(gitee.single.assets.map((a) => a.name), [apk]);

    final result = AppUpdateLogic.selectRelease(
      releases,
      '79',
      deviceAbi: 'arm64-v8a',
    );
    expect(result.assets.single.name, apk);
    expect(result.assets.single.candidates.map((c) => c.url), [
      '$giteeBase/$apk',
      'https://github.com/app.apk',
    ]);
  });

  test('asks each source once for only the newest releases', () async {
    final listRequests = <Uri>[];
    final repo = AppUpdateRepository(
      client: MockClient((req) async {
        if (req.url.path == '/manifest') return http.Response(manifest(), 200);
        listRequests.add(req.url);
        final host = req.url.host == 'api.github.com'
            ? 'github.com'
            : 'gitee.com';
        // A full page must not trigger a request for page 2.
        return http.Response(
          jsonEncode(List.filled(kReleasePageSize, release(host))),
          200,
        );
      }),
    );
    await repo.fetchReleases();
    expect(listRequests, hasLength(2));
    for (final uri in listRequests) {
      expect(uri.queryParameters['per_page'], '$kReleasePageSize');
      expect(uri.queryParameters['page'], '1');
    }
  });

  test('GitHub assets go through the API asset endpoint', () async {
    const apiBase = 'https://api.github.com/repos/o/r/releases/assets';
    String? manifestAccept;
    final repo = AppUpdateRepository(
      client: MockClient((req) async {
        if (req.url.toString() == '$apiBase/2') {
          manifestAccept = req.headers['Accept'];
          return http.Response(manifest(), 200);
        }
        if (req.url.host != 'api.github.com') throw Exception('offline');
        final j = release('github.com');
        final assets = j['assets'] as List;
        (assets[0] as Map)['url'] = '$apiBase/1';
        (assets[1] as Map)['url'] = '$apiBase/2';
        return http.Response(jsonEncode([j]), 200);
      }),
    );
    final result = AppUpdateLogic.selectRelease(
      await repo.fetchReleases(),
      '2077',
    );
    expect(manifestAccept, kOctetStream);
    expect(result.assets.single.candidates.single.url, '$apiBase/1');
  });

  test('one unavailable source does not block the other', () async {
    final repo = AppUpdateRepository(
      client: MockClient((req) async {
        if (req.url.host == 'api.github.com') throw Exception('offline');
        if (req.url.path == '/manifest') return http.Response(manifest(), 200);
        return http.Response(jsonEncode([release('gitee.com')]), 200);
      }),
    );
    final result = AppUpdateLogic.selectRelease(
      await repo.fetchReleases(),
      '2077',
    );
    expect(result.version, '3.0.0');
    expect(result.assets.single.candidates.single.source, UpdateSource.gitee);
  });

  test('merges identical mirrors using Gitee links response shape', () async {
    final repo = AppUpdateRepository(
      client: MockClient((req) async {
        if (req.url.path == '/manifest') return http.Response(manifest(), 200);
        final github = req.url.host == 'api.github.com';
        final j = release(github ? 'github.com' : 'gitee.com');
        if (!github) {
          j['assets'] = {
            'links': (j['assets'] as List)
                .map(
                  (a) => {'name': a['name'], 'url': a['browser_download_url']},
                )
                .toList(),
          };
        }
        return http.Response(jsonEncode([j]), 200);
      }),
    );
    final r = AppUpdateLogic.selectRelease(await repo.fetchReleases(), '2077');
    expect(r.assets.single.candidates.length, 2);
  });

  test('rejects conflicting digests for the same version', () async {
    final repo = AppUpdateRepository(
      client: MockClient((req) async {
        if (req.url.path == '/manifest') {
          return http.Response(
            manifest(sha: req.url.host == 'gitee.com' ? hash : 'b' * 64),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            release(req.url.host == 'gitee.com' ? 'gitee.com' : 'github.com'),
          ]),
          200,
        );
      }),
    );
    final result = await repo.fetchReleases();
    expect(
      () => AppUpdateLogic.selectRelease(result, '2077'),
      throwsStateError,
    );
  });

  for (final invalid in [
    'draft',
    'prerelease',
    'bad-version',
    'no-manifest',
    'bad-hash',
  ]) {
    test('rejects $invalid on both platforms', () async {
      final repo = AppUpdateRepository(
        client: MockClient((req) async {
          if (req.url.path == '/manifest') {
            return http.Response(
              manifest(sha: invalid == 'bad-hash' ? 'invalid' : null),
              200,
            );
          }
          final j = release('gitee.com');
          if (invalid == 'draft') j['draft'] = true;
          if (invalid == 'prerelease') j['prerelease'] = true;
          if (invalid == 'bad-version') j['tag_name'] = 'garbage';
          if (invalid == 'no-manifest') j['assets'] = [];
          return http.Response(jsonEncode([j]), 200);
        }),
      );
      await expectLater(repo.fetchReleases(), throwsException);
    });
  }

  test('selects newest ABI-compatible release before merging mirrors', () {
    LatestRelease r(String v, String abi) => LatestRelease(
      tagName: 'v$v',
      version: v,
      body: '',
      assets: [
        ReleaseAsset(
          name: 'FitnessPlan-$v-android-$abi.apk',
          downloadUrl: 'https://example.com/a',
          size: 100,
          sha256: hash,
        ),
      ],
    );
    final bundle = [
      r('4.0.0', 'x86_64'),
      r('3.0.0', 'arm64-v8a'),
      r('2.0.0', 'arm64-v8a'),
    ];
    expect(AppUpdateLogic.selectRelease(bundle, '2077').version, '3.0.0');
    expect(
      () => AppUpdateLogic.selectRelease(bundle, '1077'),
      throwsStateError,
    );
  });

  test('manual preference changes priority while retaining fallback', () async {
    final asset = ReleaseAsset(
      name: apk,
      downloadUrl: '',
      candidates: const [
        DownloadCandidate(UpdateSource.gitee, 'https://gitee.com/a'),
        DownloadCandidate(UpdateSource.github, 'https://github.com/a'),
      ],
    );
    final ranked = await AppUpdateRepository().rankCandidates(
      asset,
      UpdateSource.github,
    );
    expect(ranked.map((c) => c.source), [
      UpdateSource.github,
      UpdateSource.gitee,
    ]);
  });
  test(
    'automatic ranking uses throughput, failure falls behind usable source',
    () async {
      final asset = ReleaseAsset(
        name: apk,
        downloadUrl: '',
        candidates: const [
          DownloadCandidate(UpdateSource.gitee, 'gitee'),
          DownloadCandidate(UpdateSource.github, 'github'),
        ],
      );
      final repo = AppUpdateRepository(
        downloadProbe: (url) async => url == 'github' ? 100 : 10,
      );
      expect(
        (await repo.rankCandidates(asset, UpdateSource.auto)).first.source,
        UpdateSource.github,
      );
      final failed = AppUpdateRepository(downloadProbe: (_) async => -1);
      expect(
        (await failed.rankCandidates(asset, UpdateSource.auto)).first.source,
        UpdateSource.gitee,
      );
    },
  );

  test('source timeout does not discard healthy source', () async {
    final repo = AppUpdateRepository(
      sourceTimeout: const Duration(milliseconds: 20),
      client: MockClient((req) async {
        if (req.url.host == 'api.github.com') {
          return Completer<http.Response>().future;
        }
        if (req.url.path == '/manifest') return http.Response(manifest(), 200);
        return http.Response(jsonEncode([release('gitee.com')]), 200);
      }),
    );
    final r = AppUpdateLogic.selectRelease(await repo.fetchReleases(), '2077');
    expect(r.version, '3.0.0');
  });
  test(
    'real probe sends bounded Range and aborts a stalled endpoint',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final ranges = <String?>[];
      server.listen((request) async {
        ranges.add(request.headers.value('Range'));
        if (request.uri.path == '/slow') return;
        request.response.add(
          List.filled(512 * 1024, 1),
        ); // Ignores Range intentionally.
        try {
          await request.response.close();
        } catch (_) {
          /* Probe may abort early. */
        }
      });
      try {
        final base = 'http://127.0.0.1:${server.port}';
        final asset = ReleaseAsset(
          name: apk,
          downloadUrl: '',
          candidates: [
            DownloadCandidate(UpdateSource.gitee, '$base/slow'),
            DownloadCandidate(UpdateSource.github, '$base/fast'),
          ],
        );
        final repo = AppUpdateRepository(
          probeTimeout: const Duration(milliseconds: 200),
        );
        final result = await repo.rankCandidates(asset, UpdateSource.auto);
        expect(result.first.source, UpdateSource.github);
        expect(ranges, ['bytes=0-262143', 'bytes=0-262143']);
      } finally {
        await server.close(force: true);
      }
    },
  );

  group('releases before $kFirstManifestVersion', () {
    Map<String, dynamic> legacy(String version, {String? digest}) => {
      'tag_name': 'v$version',
      'body': 'old',
      'assets': [
        {
          'name': 'FitnessPlan-$version-android-arm64-v8a.apk',
          'browser_download_url': 'https://github.com/$version.apk',
          'size': 71472222,
          'digest': ?digest,
        },
      ],
    };

    AppUpdateRepository repoWith(List<Map<String, dynamic>> github) =>
        AppUpdateRepository(
          client: MockClient((req) async {
            if (req.url.host == 'api.github.com') {
              return http.Response(jsonEncode(github), 200);
            }
            return http.Response(jsonEncode([legacy('2.6.0')]), 200);
          }),
        );

    test('use GitHub asset digests without a manifest', () async {
      final repo = repoWith([legacy('2.6.0', digest: 'sha256:${'C' * 64}')]);
      final r = AppUpdateLogic.selectRelease(
        await repo.fetchReleases(),
        '2077',
      );
      expect(r.version, '2.6.0');
      final asset = r.assets.single;
      expect(asset.isVerified, isTrue);
      expect(asset.size, 71472222);
      expect(asset.sha256, 'c' * 64);
      // Gitee carried no digest, so only GitHub is a candidate.
      expect(asset.candidates.single.source, UpdateSource.github);
    });

    test('are skipped when GitHub reports no digest', () async {
      final repo = repoWith([legacy('2.6.0')]);
      expect(repo.fetchReleases(), throwsException);
    });

    test('from $kFirstManifestVersion on a manifest is required', () async {
      final repo = repoWith([
        legacy(kFirstManifestVersion, digest: 'sha256:${'c' * 64}'),
      ]);
      expect(repo.fetchReleases(), throwsException);
    });
  });
}
