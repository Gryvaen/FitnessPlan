import 'dart:convert';

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

enum ApkDownloadState { running, success, failed, missing }

class ApkDownloadInfo {
  const ApkDownloadInfo({
    required this.state,
    required this.bytesDownloaded,
    required this.totalBytes,
    this.localPath,
    this.reason,
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
    );
  }

  final ApkDownloadState state;
  final int bytesDownloaded;
  final int totalBytes;
  final String? localPath;
  final int? reason;

  double get progress => totalBytes > 0 ? bytesDownloaded / totalBytes : 0;
}

class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.downloadUrl});

  final String name;
  final String downloadUrl;
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
  AppUpdateRepository({http.Client? client, this.userAgentVersion = '0.0.0'})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String userAgentVersion;

  static final _latestUri = Uri.https(
    'api.github.com',
    '/repos/$kGithubOwner/$kGithubRepo/releases/latest',
  );

  Map<String, String> _headers([String? version]) => {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'FitnessPlan/${version ?? userAgentVersion}',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  Future<LatestRelease> fetchLatest({String? localVersion}) async {
    final res = await _client.get(_latestUri, headers: _headers(localVersion));
    if (res.statusCode != 200) {
      throw Exception('检查更新失败（HTTP ${res.statusCode}）');
    }
    return parseLatestReleaseJson(res.body);
  }

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
  }) async {
    final id = await _apkDownloaderChannel.invokeMethod<int>('enqueue', {
      'url': url,
      'fileName': fileName,
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
