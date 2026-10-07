import 'package:diet/l10n/app_localizations_en.dart';
import 'package:diet/l10n/app_localizations_zh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('yesterday actions and feedback say append in both locales', () {
    final zh = AppLocalizationsZh();
    final en = AppLocalizationsEn();
    expect(zh.copyYesterday, '追加昨日');
    expect(zh.copyNamed('昨日午餐'), '追加昨日午餐');
    expect(zh.copyYesterdayWorkout, '追加昨日训练');
    expect(zh.copiedItems(2, ''), '已追加 2 项');
    expect(zh.copiedWorkoutItems(2), '已追加 2 个动作');
    expect(en.copyYesterday, 'Append yesterday');
    expect(en.copyNamed('yesterday lunch'), 'Append yesterday lunch');
    expect(en.copyYesterdayWorkout, "Append yesterday's workout");
    expect(en.copiedItems(2, ''), 'Appended 2');
    expect(en.copiedWorkoutItems(2), 'Appended 2 exercises');
    expect(zh.nothingNewToAppend, isNotEmpty);
    expect(en.nothingNewToAppend, isNotEmpty);
  });
}
