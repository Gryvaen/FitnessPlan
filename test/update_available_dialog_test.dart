import 'package:diet/data/repositories/app_update_repository.dart';
import 'package:diet/l10n/app_localizations.dart';
import 'package:diet/ui/profile/update_available_dialog.dart';
import 'package:diet/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _asset = ReleaseAsset(
  name: 'FitnessPlan-2.7.0-android-arm64-v8a.apk',
  downloadUrl: 'https://example.com/a.apk',
  size: 28 * 1024 * 1024,
  sha256: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
);

LatestRelease _release(String body) => LatestRelease(
  tagName: 'v2.7.0',
  version: '2.7.0',
  body: body,
  assets: const [_asset],
);

/// Pumps a button that opens the dialog and records what it returns.
Future<List<UpdateSource?>> _open(
  WidgetTester tester, {
  String body = '## 食材库\n- **新增** x',
  UpdateSource initial = UpdateSource.auto,
}) async {
  final results = <UpdateSource?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => results.add(
              await showUpdateAvailableDialog(
                context,
                release: _release(body),
                asset: _asset,
                localVersion: '2.6.0',
                initialSource: initial,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('source picker is folded by default and shows the current one', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('发现新版本 2.7.0'), findsOneWidget);
    expect(find.text('当前 2.6.0 · 安装包 28.0 MB'), findsOneWidget);
    expect(find.text('下载源'), findsOneWidget);
    expect(find.text('自动选择'), findsOneWidget); // summary only
    expect(find.text('Gitee'), findsNothing);
    expect(find.text('GitHub'), findsNothing);
  });

  testWidgets('picking a source folds the picker and returns it', (
    tester,
  ) async {
    final results = await _open(tester);

    await tester.tap(find.text('下载源'));
    await tester.pumpAndSettle();
    expect(find.text('Gitee'), findsOneWidget);
    expect(find.text('海外网络通常更快'), findsOneWidget);

    await tester.tap(find.text('GitHub'));
    await tester.pumpAndSettle();
    expect(find.text('Gitee'), findsNothing);
    expect(find.text('GitHub'), findsOneWidget); // now the summary

    await tester.tap(find.text('下载并安装'));
    await tester.pumpAndSettle();
    expect(results, [UpdateSource.github]);
  });

  testWidgets('稍后 returns null', (tester) async {
    final results = await _open(tester, initial: UpdateSource.gitee);
    expect(find.text('Gitee'), findsOneWidget); // saved choice in summary

    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });

  testWidgets('release notes render without Markdown markers', (tester) async {
    await _open(tester, body: '## 食材库\n- **新增** x 和 `code`\n\n普通段落');

    expect(find.text('食材库'), findsOneWidget);
    expect(find.text('新增 x 和 code', findRichText: true), findsOneWidget);
    expect(find.text('普通段落', findRichText: true), findsOneWidget);
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);
  });

  testWidgets('empty notes fall back to the ask text', (tester) async {
    await _open(tester, body: '');
    expect(find.text('发现新版本 2.7.0，是否下载并安装？'), findsOneWidget);
  });

  testWidgets('long notes scroll instead of overflowing', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await _open(
      tester,
      body: List.generate(80, (i) => '- 第 $i 条更新说明，内容比较长一些').join('\n'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('下载并安装'), findsOneWidget);
    expect(find.text('下载源'), findsOneWidget);
  });
}
