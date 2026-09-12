/// 修仙境界（减脂玩法）：把累计减重换算成境界 / 层数进度。
///
/// 换算：每减少 7,700 kcal 热量缺口 ≈ 瘦 1 kg。境界突破门槛按累计减重
/// （从开始记录时算起，非逐境界叠加）：练气→筑基 3kg，筑基→结丹 10kg，
/// 结丹→元婴 20kg，元婴→化神 40kg。化神期为最高境界，不再突破。
/// 每个大境界再分 9 层小境界，按境界内的减重量线性均分。
library;

const double kKcalPerKg = 7700;
const int kCultivationLayers = 9;

enum CultivationRealm {
  qiRefining(floorKg: 0, ceilKg: 3),
  foundation(floorKg: 3, ceilKg: 10),
  coreFormation(floorKg: 10, ceilKg: 20),
  nascentSoul(floorKg: 20, ceilKg: 40),
  divineTransformation(floorKg: 40, ceilKg: double.infinity);

  const CultivationRealm({required this.floorKg, required this.ceilKg});

  /// 累计减重达到该境界所需的下限（kg，从 0 开始）。
  final double floorKg;

  /// 累计减重达到该境界后、突破至下一境界所需的上限（kg）。
  /// 化神期为 [double.infinity]：已是最高境界。
  final double ceilKg;

  bool get isMax => this == CultivationRealm.divineTransformation;

  CultivationRealm? get next {
    final i = CultivationRealm.values.indexOf(this);
    if (i + 1 >= CultivationRealm.values.length) return null;
    return CultivationRealm.values[i + 1];
  }

  /// 本境界内每一层对应的减重量（kg）。化神期无意义，返回 null。
  double? get perLayerKg =>
      isMax ? null : (ceilKg - floorKg) / kCultivationLayers;

  /// 本境界内每一层对应的 kcal 缺口。化神期无意义，返回 null。
  double? get perLayerKcal {
    final kg = perLayerKg;
    return kg == null ? null : kg * kKcalPerKg;
  }
}

/// 某一时刻的境界修行进度（由累计减重 [kgLost] 换算而来）。
class CultivationProgress {
  const CultivationProgress({
    required this.kgLost,
    required this.realm,
    required this.layer,
    required this.layerProgress,
    required this.kcalToNextLayer,
    required this.kcalToNextRealm,
  });

  /// 累计减重（kg），已 clamp 到 >= 0。
  final double kgLost;

  final CultivationRealm realm;

  /// 境界内层数，1..9。化神期固定为 9（圆满）。
  final int layer;

  /// 当前层内的进度，0..1。化神期固定为 1。
  final double layerProgress;

  /// 距离下一层还差多少 kcal；已至最高层/化神期时为 null。
  final double? kcalToNextLayer;

  /// 距离下一境界还差多少 kcal；已至化神期时为 null。
  final double? kcalToNextRealm;

  bool get isMax => realm.isMax;
}

/// 由累计减重（kg，允许为负——尚未产生净减重时按 0 处理）换算境界进度。
CultivationProgress computeCultivationProgress(double rawKgLost) {
  final kgLost = rawKgLost < 0 ? 0.0 : rawKgLost;

  CultivationRealm realm = CultivationRealm.qiRefining;
  for (final r in CultivationRealm.values) {
    if (kgLost >= r.floorKg) realm = r;
  }

  if (realm.isMax) {
    return CultivationProgress(
      kgLost: kgLost,
      realm: realm,
      layer: kCultivationLayers,
      layerProgress: 1,
      kcalToNextLayer: null,
      kcalToNextRealm: null,
    );
  }

  final perLayerKg = realm.perLayerKg!;
  final intoRealmKg = kgLost - realm.floorKg;
  final rawLayer = (intoRealmKg / perLayerKg).floor() + 1;
  final layer = rawLayer.clamp(1, kCultivationLayers);
  final layerStartKg = realm.floorKg + (layer - 1) * perLayerKg;
  final layerProgress = ((kgLost - layerStartKg) / perLayerKg).clamp(0.0, 1.0);

  final kcalToNextLayer = (perLayerKg * (1 - layerProgress)) * kKcalPerKg;
  final kcalToNextRealm = (realm.ceilKg - kgLost) * kKcalPerKg;

  return CultivationProgress(
    kgLost: kgLost,
    realm: realm,
    layer: layer,
    layerProgress: layerProgress,
    kcalToNextLayer: kcalToNextLayer,
    kcalToNextRealm: kcalToNextRealm < 0 ? 0 : kcalToNextRealm,
  );
}

/// 步数换算 kcal：每步 0.04 kcal。
double stepsToKcal(int steps) => steps * 0.04;
