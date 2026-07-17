import 'package:flutter_test/flutter_test.dart';

import 'package:diet/data/repositories/app_update_repository.dart';

void main() {
  group('AppUpdateLogic.normalizeVersion', () {
    test('strips v prefix and build metadata', () {
      expect(AppUpdateLogic.normalizeVersion('v1.1.0'), '1.1.0');
      expect(AppUpdateLogic.normalizeVersion('V1.0.4'), '1.0.4');
      expect(AppUpdateLogic.normalizeVersion('1.1.0+5'), '1.1.0');
      expect(AppUpdateLogic.normalizeVersion(' 1.2.3-beta '), '1.2.3');
    });
  });

  group('AppUpdateLogic.isNewer', () {
    test('detects newer remote', () {
      expect(AppUpdateLogic.isNewer('1.0.4', 'v1.1.0'), isTrue);
      expect(AppUpdateLogic.isNewer('1.1.0', '1.1.1'), isTrue);
      expect(AppUpdateLogic.isNewer('1.1.0', '1.2.0'), isTrue);
    });

    test('same or older is not newer', () {
      expect(AppUpdateLogic.isNewer('1.1.0', 'v1.1.0'), isFalse);
      expect(AppUpdateLogic.isNewer('1.1.0+5', '1.1.0'), isFalse);
      expect(AppUpdateLogic.isNewer('1.2.0', '1.1.9'), isFalse);
    });
  });

  group('AppUpdateLogic.pickApkAsset', () {
    test('keeps an arm64 installation on the arm64 channel', () {
      final picked = AppUpdateLogic.pickApkAsset(
        const [
          ReleaseAsset(
            name: 'FitnessPlan-1.1.0-android.apk',
            downloadUrl: 'https://example.com/universal.apk',
          ),
          ReleaseAsset(
            name: 'FitnessPlan-1.1.0-android-arm64-v8a.apk',
            downloadUrl: 'https://example.com/arm64.apk',
          ),
          ReleaseAsset(
            name: 'FitnessPlan-1.1.0-android-armeabi-v7a.apk',
            downloadUrl: 'https://example.com/v7a.apk',
          ),
        ],
        version: '1.1.0',
        localBuildNumber: '2008',
      );
      expect(picked?.name, 'FitnessPlan-1.1.0-android-arm64-v8a.apk');
    });

    test('keeps a universal installation on the universal channel', () {
      final picked = AppUpdateLogic.pickApkAsset(
        const [
          ReleaseAsset(
            name: 'FitnessPlan-1.1.0-android-x86_64.apk',
            downloadUrl: 'https://example.com/x64.apk',
          ),
          ReleaseAsset(
            name: 'FitnessPlan-1.1.0-android.apk',
            downloadUrl: 'https://example.com/universal.apk',
          ),
        ],
        version: '1.1.0',
        localBuildNumber: '8',
      );
      expect(picked?.downloadUrl, 'https://example.com/universal.apk');
    });

    test('returns null when no suitable apk', () {
      expect(
        AppUpdateLogic.pickApkAsset(
          const [
            ReleaseAsset(
              name: 'notes.txt',
              downloadUrl: 'https://example.com/n',
            ),
          ],
          version: '1.1.0',
          localBuildNumber: '2008',
        ),
        isNull,
      );
    });

    test('does not fall back from split APK to universal APK', () {
      expect(
        AppUpdateLogic.pickApkAsset(
          const [
            ReleaseAsset(
              name: 'FitnessPlan-1.1.4-android.apk',
              downloadUrl: 'https://example.com/universal.apk',
            ),
          ],
          version: '1.1.4',
          localBuildNumber: '2008',
        ),
        isNull,
      );
    });

    test('does not select an APK belonging to another release version', () {
      expect(
        AppUpdateLogic.pickApkAsset(
          const [
            ReleaseAsset(
              name: 'FitnessPlan-1.1.3-android-arm64-v8a.apk',
              downloadUrl: 'https://example.com/old.apk',
            ),
          ],
          version: '1.1.4',
          localBuildNumber: '2008',
        ),
        isNull,
      );
    });
  });

  group('AppUpdateRepository.parseLatestReleaseJson', () {
    test('parses tag and assets', () {
      const json = '''
{
  "tag_name": "v1.1.0",
  "body": "## 更新\\n- 记录页",
  "assets": [
    {
      "name": "FitnessPlan-1.1.0-android-arm64-v8a.apk",
      "browser_download_url": "https://example.com/a.apk"
    }
  ]
}
''';
      final latest = AppUpdateRepository.parseLatestReleaseJson(json);
      expect(latest.version, '1.1.0');
      expect(latest.assets, hasLength(1));
      expect(latest.body, contains('记录页'));
    });
  });
}
