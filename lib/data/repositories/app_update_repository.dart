import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const kGithubOwner = 'Gryvaen';
const kGithubRepo = 'FitnessPlan';

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
  /// armeabi-v7a, 2xxx for arm64-v8a and 3xxx for x86_64). Switching from a
  /// split APK to a universal APK would therefore look like a downgrade to
  /// Android even when its version name is newer.
  static ReleaseAsset? pickApkAsset(
    List<ReleaseAsset> assets, {
    required String version,
    required String localBuildNumber,
  }) {
    final buildNumber = int.tryParse(localBuildNumber) ?? 0;
    final channel = switch (buildNumber ~/ 1000) {
      1 => 'armeabi-v7a',
      2 => 'arm64-v8a',
      3 => 'x86_64',
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

  Future<String> downloadApk(
    String url, {
    String? localVersion,
    void Function(double progress)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(url));
    request.headers.addAll(_headers(localVersion));
    final streamed = await _client.send(request);
    if (streamed.statusCode != 200) {
      throw Exception('下载失败（HTTP ${streamed.statusCode}）');
    }
    final total = streamed.contentLength ?? 0;
    final dir = await getTemporaryDirectory();
    final path = p.join(dir.path, 'FitnessPlan-update.apk');
    final file = File(path);
    final sink = file.openWrite();
    var received = 0;
    try {
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && onProgress != null) {
          onProgress((received / total).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    if (total > 0 && onProgress != null) {
      onProgress(1.0);
    }
    return path;
  }
}
