import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/cultivation.dart';
import '../../domain/maintain_balance.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations_ext.dart';

extension CultivationRealmL10n on CultivationRealm {
  String label(AppLocalizations l10n) => switch (this) {
    CultivationRealm.qiRefining => l10n.cultivationRealmQiRefining,
    CultivationRealm.foundation => l10n.cultivationRealmFoundation,
    CultivationRealm.coreFormation => l10n.cultivationRealmCoreFormation,
    CultivationRealm.nascentSoul => l10n.cultivationRealmNascentSoul,
    CultivationRealm.divineTransformation =>
      l10n.cultivationRealmDivineTransformation,
  };

  /// 与设计稿保持一致的境界名称配色：练气绿 / 筑基蓝 / 结丹金 / 元婴紫 / 化神红。
  Color get textColor => switch (this) {
    CultivationRealm.qiRefining => const Color(0xFF2F7A46),
    CultivationRealm.foundation => const Color(0xFF2E6FD6),
    CultivationRealm.coreFormation => const Color(0xFFB8860B),
    CultivationRealm.nascentSoul => const Color(0xFF7C4DCF),
    CultivationRealm.divineTransformation => const Color(0xFFC23B2E),
  };

  String get _assetFolder => switch (this) {
    CultivationRealm.qiRefining => 'lianqi',
    CultivationRealm.foundation => 'zhuji',
    CultivationRealm.coreFormation => 'jiedan',
    CultivationRealm.nascentSoul => 'yuanying',
    CultivationRealm.divineTransformation => 'huashen',
  };

  /// 该境界第 [layer] 层（1-9）的立绘资源路径；化神期忽略 [layer]。
  String artAsset(int layer, {bool animated = false}) {
    final clamped = layer.clamp(1, kCultivationLayers);
    final name = isMax ? _assetFolder : '${_assetFolder}_$clamped';
    final extension = animated && kAnimatedRealmArt.contains(name)
        ? 'webp'
        : 'jpg';
    return 'assets/cultivation/realms/$name.$extension';
  }
}

/// 已经有动图（同名 `.webp`）的境界场景。其余场景（以及系统开启「减少动画」
/// 时）一律显示同名静态 `.jpg`。新动图放进 `assets/cultivation/realms/`
/// 后，把场景名（如 `lianqi_1`、`huashen`）加进这里即可。
const kAnimatedRealmArt = <String>{};

extension MindRealmL10n on MindRealm {
  String label(AppLocalizations l10n) => switch (this) {
    MindRealm.restless => l10n.mindRealmRestless,
    MindRealm.settled => l10n.mindRealmSettled,
    MindRealm.tranquil => l10n.mindRealmTranquil,
    MindRealm.stillWater => l10n.mindRealmStillWater,
    MindRealm.clarity => l10n.mindRealmClarity,
  };

  /// 心浮灰褐 → 心定湖青 → 心静靛蓝 → 心如止水深靛 → 道心通明金。
  Color get textColor => switch (this) {
    MindRealm.restless => const Color(0xFF7A6A55),
    MindRealm.settled => const Color(0xFF2E7D74),
    MindRealm.tranquil => const Color(0xFF2E6FA8),
    MindRealm.stillWater => const Color(0xFF4B5FB8),
    MindRealm.clarity => const Color(0xFFB8860B),
  };
}

/// 天秤左盘（亏空）与右盘（盈余）的配色：冷青 / 暖橙，不用红绿以免带
/// 「好坏」评判——维持期两边都只是偏离。
const kBalanceDeficitColor = Color(0xFF2E6FA8);
const kBalanceSurplusColor = Color(0xFFC0662B);

/// 三大目标体系（减脂/增肌/维持）的画轴选择页与「尚未开启」占位页共用的
/// 主题素材：每个目标一幅去底的画卷立绘（黑底抠图，画轴选择页用，见
/// [cultivationScrollAsset]）+ 一张场景图（本目标专属的「尚未开启」/
/// 「开发中」占位页背景）+ 一个强调色。目前只有减脂 ([CultivationRealm])
/// 实现了逐境界逐层的原画与真实玩法；增肌/维持的玩法与境界体系尚未设计，
/// 先只做画轴选择 + 占位页 UI。
extension CultivationGoalTheme on FitnessGoal {
  /// 去掉厅堂背景、只留画卷本体（含流苏玉坠，四边不规则）的立绘，黑底。
  /// 画轴选择页直接铺在纯黑页面上，不做矩形裁切，让卷轴的真实轮廓露出来。
  String get cultivationScrollAsset => switch (this) {
    FitnessGoal.cut => 'assets/cultivation/goals/goal_cut_scroll.png',
    FitnessGoal.bulk => 'assets/cultivation/goals/goal_bulk_scroll.png',
    FitnessGoal.maintain => 'assets/cultivation/goals/goal_maintain_scroll.png',
  };

  String get cultivationBackgroundAsset => switch (this) {
    FitnessGoal.cut => 'assets/cultivation/goals/goal_cut_background.jpg',
    FitnessGoal.bulk => 'assets/cultivation/goals/goal_bulk_background.jpg',
    FitnessGoal.maintain =>
      'assets/cultivation/goals/goal_maintain_background.jpg',
  };

  /// 与 [CultivationRealm.textColor] 的练气绿保持一致；增肌取器械房的
  /// 冷灰蓝，维持取湖畔打坐的静谧青。
  Color get cultivationAccentColor => switch (this) {
    FitnessGoal.cut => const Color(0xFF2F7A46),
    FitnessGoal.bulk => const Color(0xFF3A4A63),
    FitnessGoal.maintain => const Color(0xFF2E7D74),
  };
}

final _kcalFormat = NumberFormat.decimalPattern();

/// 四舍五入到整数并加千分位分隔符，例如 2,276。
String formatKcal(double kcal) => _kcalFormat.format(kcal.round());

/// 同 [formatKcal]，但正值显式加上「+」——今日贡献值可能为负（饮食超过
/// TDEE 的倒退），需要让正负一眼可辨。负值 / 0 本就带着自己的符号，不再处理。
String formatSignedKcal(double kcal) {
  final rounded = kcal.round();
  return rounded > 0
      ? '+${_kcalFormat.format(rounded)}'
      : _kcalFormat.format(rounded);
}

/// 保留一位小数，例如 6.8。
String formatKg(double kg) => kg.toStringAsFixed(1);

/// 同 [formatKg]，正值显式加「+」，例如 +0.3 / -0.2。
String formatSignedKg(double kg) {
  final text = kg.toStringAsFixed(1);
  if (text == '0.0' || text == '-0.0') return '0.0';
  return kg > 0 ? '+$text' : text;
}
