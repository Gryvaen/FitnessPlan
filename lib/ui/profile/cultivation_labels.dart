import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/cultivation.dart';
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

  /// 该境界第 [layer] 层（1-9）的原画资源路径；化神期忽略 [layer]，只有一张。
  String artAsset(int layer) {
    if (isMax) return 'assets/cultivation/huashen.jpg';
    final clamped = layer.clamp(1, kCultivationLayers);
    return 'assets/cultivation/${_assetFolder}_$clamped.jpg';
  }
}

final _kcalFormat = NumberFormat.decimalPattern();

/// 四舍五入到整数并加千分位分隔符，例如 2,276。
String formatKcal(double kcal) => _kcalFormat.format(kcal.round());

/// 保留一位小数，例如 6.8。
String formatKg(double kg) => kg.toStringAsFixed(1);
