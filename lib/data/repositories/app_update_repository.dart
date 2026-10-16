import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const kGithubOwner = 'Gryvaen';
const kGithubRepo = 'FitnessPlan';

/// Native side of the update download: hands the APK URL to Android's
/// system [DownloadManager] instead of streaming it over a plain Dart HTTP
/// client, so the download keeps running (and the OS shows its own
/// progress notification) even if this app's process is backgrounded or
/// killed. See `ApkDownloader.kt` / `ApkDownloadCompleteReceiver.kt`.
const _apkDownloaderChannel = MethodChannel('fitness_plan/apk_downloader');

enum UpdateSource { auto, gitee, github }

/// First release published with `update-manifest.json`. Older GitHub
/// releases are verified with the size/sha256 digest GitHub reports per
/// asset instead; older Gitee releases carry no digest and are skipped.
const kFirstManifestVersion = '2.6.1';

class DownloadCandidate {
  const DownloadCandidate(this.source, this.url);
  final UpdateSource source;
  final String url;
  Map<String, dynamic> toJson() => {'source': source.name, 'url': url};
  factory DownloadCandidate.fromJson(Map<String, dynamic> json) =>
      DownloadCandidate(
        UpdateSource.values.byName(json['source'] as String),
        json['url'] as String,
      );
}

enum ApkDownloadState { running, success, failed, missing }

class ApkDownloadInfo {
  const ApkDownloadInfo({
    required this.state,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.localPath,
    this.reason,
    this.waitingForNetwork = false,
  });

  factory ApkDownloadInfo.fromMap(Map<dynamic, dynamic> map) {
    final state = switch (map['status']) {
      'success' => ApkDownloadState.success,
      'failed' => ApkDownloadState.failed,
      'missing' => ApkDownloadState.missing,
      _ => ApkDownloadState.running,
    };
    return ApkDownloadInfo(
      state: state,
      bytesDownloaded: (map['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      localPath: map['localPath'] as String?,
      reason: (map['reason'] as num?)?.toInt(),
      waitingForNetwork: map['waitingForNetwork'] == true,
    );
  }

  final ApkDownloadState state;
  final int bytesDownloaded;
  final int totalBytes;
  final String? localPath;
  final int? reason;
  final bool waitingForNetwork;

  double get progress => totalBytes > 0 ? bytesDownloaded / totalBytes : 0;
}

class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    this.size = 0,
    this.sha256 = '',
    this.candidates = const [],
  });
  final String name;
  final String downloadUrl;
  final int size;
  final String sha256;
  final List<DownloadCandidate> candidates;
  bool get isVerified =>
      size > 0 && RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256);
  Map<String, dynamic> toJson() => {
    'name': name,
    'url': downloadUrl,
    'size': size,
    'sha256': sha256,
    'candidates': candidates.map((c) => c.toJson()).toList(),
  };
  factory ReleaseAsset.fromJson(Map<String, dynamic> j) => ReleaseAsset(
    name: j['name'] as String,
    downloadUrl: j['url'] as String,
    size: j['size'] as int,
    sha256: j['sha256'] as String,
    candidates: (j['candidates'] as List)
        .map(
          (c) =>
              DownloadCandidate.fromJson(Map<String, dynamic>.from(c as Map)),
        )
        .toList(),
  );
}

class LatestRelease {
  const LatestRelease({
    required this.tagName,
    required this.version,
    required this.body,
    required this.assets,
  });

  final String tagName;
  final String version;
  final String body;
  final List<ReleaseAsset> assets;
}

/// Pure helpers for version compare / APK asset selection (unit-testable).
abstract final class AppUpdateLogic {
  /// Strips optional leading `v`/`V` and trims.
  static String normalizeVersion(String raw) {
    var s = raw.trim();
    if (s.startsWith('v') || s.startsWith('V')) {
      s = s.substring(1);
    }
    // Drop build metadata / pre-release for compare: 1.1.0+5 → 1.1.0
    final plus = s.indexOf('+');
    if (plus >= 0) s = s.substring(0, plus);
    final dash = s.indexOf('-');
    if (dash >= 0) s = s.substring(0, dash);
    return s.trim();
  }

  /// Returns true when [remote] is strictly newer than [local] (semver).
  static bool isNewer(String local, String remote) {
    final a = _parse(normalizeVersion(local));
    final b = _parse(normalizeVersion(remote));
    for (var i = 0; i < 3; i++) {
      if (b[i] > a[i]) return true;
      if (b[i] < a[i]) return false;
    }
    return false;
  }

  static List<int> _parse(String version) {
    final parts = version.split('.');
    return [
      for (var i = 0; i < 3; i++)
        i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
    ];
  }

  static LatestRelease selectRelease(
    List<LatestRelease> releases,
    String buildNumber,
  ) {
    final usable = releases
        .where(
          (r) =>
              pickApkAsset(
                r.assets,
                version: r.version,
                localBuildNumber: buildNumber,
              ) !=
              null,
        )
        .toList();
    if (usable.isEmpty) throw StateError('no_apk');
    usable.sort(
      (a, b) => isNewer(a.version, b.version)
          ? 1
          : isNewer(b.version, a.version)
          ? -1
          : 0,
    );
    final latest = usable.first;
    final selected = pickApkAsset(
      latest.assets,
      version: latest.version,
      localBuildNumber: buildNumber,
    )!;
    final mirrors = <DownloadCandidate>[];
    for (final release in usable.where((r) => r.version == latest.version)) {
      final asset = pickApkAsset(
        release.assets,
        version: release.version,
        localBuildNumber: buildNumber,
      )!;
      if (asset.name != selected.name ||
          asset.size != selected.size ||
          asset.sha256 != selected.sha256) {
        throw StateError('同版本安装包校验信息冲突，请联系开发者');
      }
      for (final candidate in asset.candidates) {
        if (!mirrors.any((existing) => existing.source == candidate.source)) {
          mirrors.add(candidate);
        }
      }
    }
    return LatestRelease(
      tagName: latest.tagName,
      version: latest.version,
      body: latest.body,
      assets: [
        ReleaseAsset(
          name: selected.name,
          downloadUrl: selected.downloadUrl,
          size: selected.size,
          sha256: selected.sha256,
          candidates: mirrors,
        ),
      ],
    );
  }

  /// Selects the APK from the same version-code channel as the installed app.
  ///
  /// Flutter adds an ABI prefix to split APK version codes (1xxx for
  /// armeabi-v7a, 2xxx for arm64-v8a and 4xxx for x86_64 — 3xxx was x86,
  /// removed from Flutter's ABI_VERSION map; see
  /// packages/flutter_tools/gradle FlutterPluginConstants.kt). Switching from
  /// a split APK to a universal APK would therefore look like a downgrade to
  /// Android even when its version name is newer, and Android's installer
  /// then refuses it as "already installed".
  static ReleaseAsset? pickApkAsset(
    List<ReleaseAsset> assets, {
    required String version,
    required String localBuildNumber,
  }) {
    final buildNumber = int.tryParse(localBuildNumber) ?? 0;
    final channel = switch (buildNumber ~/ 1000) {
      1 => 'armeabi-v7a',
      2 => 'arm64-v8a',
      4 => 'x86_64',
      _ => null,
    };
    final normalized = normalizeVersion(version);
    final expectedName = channel == null
        ? 'FitnessPlan-$normalized-android.apk'
        : 'FitnessPlan-$normalized-android-$channel.apk';
    for (final a in assets) {
      if (a.name == expectedName) return a;
    }
    return null;
  }
}

class AppUpdateRepository {
  AppUpdateRepository({
    this._client,
    this.userAgentVersion = '0.0.0',
    this.downloadProbe,
    this.sourceTimeout = const Duration(seconds: 10),
    this.probeTimeout = const Duration(seconds: 5),
  });

  final http.Client? _client;
  final String userAgentVersion;
  final Future<double> Function(String url)? downloadProbe;
  final Duration sourceTimeout;
  final Duration probeTimeout;

  Map<String, String> _headers([String? version]) => {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'FitnessPlan/${version ?? userAgentVersion}',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  Future<List<LatestRelease>> fetchReleases({String? localVersion}) async {
    final results = await Future.wait([
      _fetchSource(UpdateSource.gitee),
      _fetchSource(UpdateSource.github),
    ]);
    final releases = results.expand((r) => r).toList();
    if (releases.isEmpty) throw Exception('所有更新源均不可用或没有有效的更新清单');
    // ABI selection happens after both sources have been collected.
    return releases;
  }

  Future<List<LatestRelease>> _fetchSource(UpdateSource source) async {
    final client = _client ?? http.Client();
    try {
      return await _fetchSourceInner(source, client).timeout(sourceTimeout);
    } catch (_) {
      return [];
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<List<LatestRelease>> _fetchSourceInner(
    UpdateSource source,
    http.Client client,
  ) async {
    final github = source == UpdateSource.github;
    final releases = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final uri = Uri.https(
        github ? 'api.github.com' : 'gitee.com',
        github
            ? '/repos/$kGithubOwner/$kGithubRepo/releases'
            : '/api/v5/repos/Gryvaen/FitnessPlan/releases',
        {'per_page': '100', 'page': '$page'},
      );
      final response = await client.get(
        uri,
        headers: github ? _headers() : {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      final items = decoded is List ? decoded : [decoded];
      releases.addAll(
        items.whereType<Map>().map((j) => Map<String, dynamic>.from(j)),
      );
      if (items.length < 100) break;
      page++;
    }
    final parsed = await Future.wait(
      releases.map((j) async {
        try {
          return await _parseVerifiedRelease(j, source, client);
        } catch (_) {
          return null;
        }
      }),
    );
    return parsed.whereType<LatestRelease>().toList();
  }

  Future<LatestRelease?> _parseVerifiedRelease(
    Map<String, dynamic> j,
    UpdateSource source,
    http.Client client,
  ) async {
    if (j['draft'] == true || j['prerelease'] == true) return null;
    final tag = j['tag_name'] as String? ?? '';
    if (!RegExp(r'^v?\d+\.\d+\.\d+$').hasMatch(tag)) return null;
    final raw = j['assets'];
    final items = raw is List
        ? raw
        : (raw is Map ? raw['links'] as List? ?? [] : []);
    final links = <String, String>{};
    final legacy = <ReleaseAsset>[];
    for (final item in items) {
      if (item is! Map) continue;
      final name = item['name'];
      final url =
          item['browser_download_url'] ??
          item['direct_asset_url'] ??
          item['url'];
      if (name is String &&
          url is String &&
          Uri.tryParse(url)?.scheme == 'https') {
        links[name] = url;
        final digest = item['digest'];
        final size = item['size'];
        if (digest is String && digest.startsWith('sha256:') && size is int) {
          legacy.add(
            ReleaseAsset(
              name: name,
              downloadUrl: url,
              size: size,
              sha256: digest.substring('sha256:'.length).toLowerCase(),
              candidates: [DownloadCandidate(source, url)],
            ),
          );
        }
      }
    }
    final version = AppUpdateLogic.normalizeVersion(tag);
    final manifestUrl = links['update-manifest.json'];
    if (manifestUrl == null) {
      // Releases before [kFirstManifestVersion]: the GitHub path used before
      // manifests existed, still integrity-checked via GitHub's digests.
      final isLegacy = AppUpdateLogic.isNewer(version, kFirstManifestVersion);
      if (source != UpdateSource.github || !isLegacy) return null;
      final verified = legacy.where((a) => a.isVerified).toList();
      if (verified.isEmpty) return null;
      return LatestRelease(
        tagName: tag,
        version: version,
        body: (j['body'] as String? ?? '').trim(),
        assets: verified,
      );
    }
    final manifestResponse = await client.get(Uri.parse(manifestUrl));
    if (manifestResponse.statusCode != 200) return null;
    final manifest = jsonDecode(manifestResponse.body) as Map<String, dynamic>;
    if (manifest['version'] != version || manifest['schemaVersion'] != 1) {
      return null;
    }
    final assets = <ReleaseAsset>[];
    for (final entry in manifest['assets'] as List) {
      final name = entry['name'] as String;
      final url = links[name];
      if (url == null) continue;
      final asset = ReleaseAsset(
        name: name,
        downloadUrl: url,
        size: entry['size'] as int,
        sha256: (entry['sha256'] as String).toLowerCase(),
        candidates: [DownloadCandidate(source, url)],
      );
      if (asset.isVerified) assets.add(asset);
    }
    if (assets.isEmpty) return null;
    return LatestRelease(
      tagName: tag,
      version: version,
      body: (j['body'] as String? ?? '').trim(),
      assets: assets,
    );
  }

  Future<List<DownloadCandidate>> rankCandidates(
    ReleaseAsset asset,
    UpdateSource preference,
  ) async {
    final candidates = [...asset.candidates];
    if (preference != UpdateSource.auto) {
      candidates.sort(
        (a, b) => (a.source == preference ? 0 : 1).compareTo(
          b.source == preference ? 0 : 1,
        ),
      );
      return candidates;
    }
    final scores = await Future.wait(
      candidates.map(
        (c) async => MapEntry(c, await (downloadProbe ?? _probe)(c.url)),
      ),
    );
    scores.sort((a, b) {
      final score = b.value.compareTo(a.value);
      return score != 0 ? score : (a.key.source == UpdateSource.gitee ? -1 : 1);
    });
    return scores.map((e) => e.key).toList();
  }

  Future<double> _probe(String url) async {
    final client = HttpClient()..connectionTimeout = probeTimeout;
    try {
      return await (() async {
        final watch = Stopwatch()..start();
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set('Range', 'bytes=0-262143');
        final response = await request.close();
        if (response.statusCode != 200 && response.statusCode != 206) {
          return -1.0;
        }
        var bytes = 0;
        await for (final chunk in response) {
          bytes += chunk.length.clamp(0, 262144 - bytes);
          if (bytes >= 262144) break;
        }
        return bytes > 0 ? bytes / (watch.elapsedMicroseconds + 1) : -1.0;
      })().timeout(probeTimeout);
    } catch (_) {
      return -1;
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> verifyDownload(int downloadId) async =>
      await _apkDownloaderChannel.invokeMethod<bool>('verify', {
        'downloadId': downloadId,
      }) ??
      false;

  /// Exposed for tests.
  static LatestRelease parseLatestReleaseJson(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    final tag = map['tag_name'] as String? ?? '';
    final notes = map['body'] as String? ?? '';
    final rawAssets = map['assets'] as List<dynamic>? ?? const [];
    final assets = <ReleaseAsset>[];
    for (final item in rawAssets) {
      if (item is! Map) continue;
      final name = item['name'] as String?;
      final url = item['browser_download_url'] as String?;
      if (name == null || url == null) continue;
      assets.add(ReleaseAsset(name: name, downloadUrl: url));
    }
    return LatestRelease(
      tagName: tag,
      version: AppUpdateLogic.normalizeVersion(tag),
      body: notes.trim(),
      assets: assets,
    );
  }

  /// Enqueues the APK with the system [DownloadManager] (via
  /// [_apkDownloaderChannel]) and returns its download id.
  Future<int> enqueueDownload({
    required String url,
    String fileName = 'FitnessPlan-update.apk',
    int size = 0,
    String sha256 = '',
  }) async {
    final id = await _apkDownloaderChannel.invokeMethod<int>('enqueue', {
      'url': url,
      'fileName': fileName,
      'size': size,
      'sha256': sha256,
    });
    if (id == null) throw Exception('下载未能开始');
    return id;
  }

  Future<ApkDownloadInfo> queryDownload(int downloadId) async {
    final map = await _apkDownloaderChannel.invokeMethod<Map<dynamic, dynamic>>(
      'query',
      {'downloadId': downloadId},
    );
    return ApkDownloadInfo.fromMap(map ?? const {});
  }

  Future<void> cancelDownload(int downloadId) {
    return _apkDownloaderChannel.invokeMethod('cancel', {
      'downloadId': downloadId,
    });
  }
}
