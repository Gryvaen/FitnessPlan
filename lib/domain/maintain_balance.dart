/// 维持境界（维持玩法）：阴阳天秤 + 心境。
///
/// - **天秤**：从进入本次维持那天起按天结算。单日净值
///   `net = 摄入 − (TDEE + 步数 kcal) + 放纵日自定盈余`；net < 0 时把
///   |net| 放进左盘（亏），net > 0 时放进右盘（盈）。横梁倾斜 = 右 − 左。
/// - **心境**：单日 |net| 落在 [maintainBalanceThresholdKcal] 内即为一个
///   「平衡日」。平衡日越多心境越高，每个心境再分 9 层（同减脂境界）。
///
/// 只有「饮食被计入」（当日记录 ≥ 2 类餐次且有 TDEE、饮食开关开）或放纵日
/// 采用自定盈余的日子才上秤；没记饮食的日子只有步数，算不出真实盈亏，不计入。
library;

import 'dart:math' as math;

import 'cultivation.dart' show kCultivationLayers;
import 'cut_cultivation.dart';

/// 平衡日阈值下限（kcal）。
const double kMaintainBalancedMinKcal = 150;

/// 平衡日阈值占当日 TDEE 的比例。
const double kMaintainBalancedTdeeRatio = 0.1;

/// 天秤最大倾角（弧度），约 18°。
const double kBalanceMaxTiltRadians = 18 * math.pi / 180;

/// 倾角压缩尺度：累计净值约 3,850 kcal（≈0.5 kg）时接近最大倾角。
const double kBalanceTiltScaleKcal = 3850;

/// 单日平衡阈值：`max(150, 10% × TDEE)`。
double maintainBalanceThresholdKcal(double tdee) =>
    math.max(kMaintainBalancedMinKcal, tdee * kMaintainBalancedTdeeRatio);

/// 累计净值 → 横梁倾角（弧度）。正值 = 右盘（盈余）下沉，即顺时针。
double balanceTiltRadians(double netKcal) =>
    kBalanceMaxTiltRadians * _tanh(netKcal / kBalanceTiltScaleKcal);

double _tanh(double x) {
  if (x > 20) return 1;
  if (x < -20) return -1;
  final e2 = math.exp(2 * x);
  return (e2 - 1) / (e2 + 1);
}

/// 心境等级：按累计平衡日数划分。
enum MindRealm {
  restless(floorDays: 0, ceilDays: 7),
  settled(floorDays: 7, ceilDays: 21),
  tranquil(floorDays: 21, ceilDays: 60),
  stillWater(floorDays: 60, ceilDays: 120),
  clarity(floorDays: 120, ceilDays: null);

  const MindRealm({required this.floorDays, required this.ceilDays});

  final int floorDays;

  /// 突破至下一心境所需的平衡日数；最高心境为 null。
  final int? ceilDays;

  bool get isMax => ceilDays == null;

  MindRealm? get next {
    final i = MindRealm.values.indexOf(this);
    if (i + 1 >= MindRealm.values.length) return null;
    return MindRealm.values[i + 1];
  }

  /// 每层对应的平衡日数（可为小数）；最高心境为 null。
  double? get perLayerDays {
    final ceil = ceilDays;
    return ceil == null ? null : (ceil - floorDays) / kCultivationLayers;
  }
}

class MindProgress {
  const MindProgress({
    required this.balancedDays,
    required this.realm,
    required this.layer,
    required this.layerProgress,
    required this.daysToNextRealm,
  });

  final int balancedDays;
  final MindRealm realm;

  /// 1..9；最高心境固定 9。
  final int layer;

  /// 当前层内进度 0..1；最高心境固定 1。
  final double layerProgress;

  /// 距下一心境还差几个平衡日；最高心境为 null。
  final int? daysToNextRealm;

  bool get isMax => realm.isMax;
}

MindProgress computeMindProgress(int rawBalancedDays) {
  final days = rawBalancedDays < 0 ? 0 : rawBalancedDays;

  var realm = MindRealm.restless;
  for (final r in MindRealm.values) {
    if (days >= r.floorDays) realm = r;
  }

  if (realm.isMax) {
    return MindProgress(
      balancedDays: days,
      realm: realm,
      layer: kCultivationLayers,
      layerProgress: 1,
      daysToNextRealm: null,
    );
  }

  final perLayer = realm.perLayerDays!;
  final into = days - realm.floorDays;
  final layer = ((into / perLayer).floor() + 1).clamp(1, kCultivationLayers);
  final layerStart = (layer - 1) * perLayer;
  final layerProgress = ((into - layerStart) / perLayer).clamp(0.0, 1.0);

  return MindProgress(
    balancedDays: days,
    realm: realm,
    layer: layer,
    layerProgress: layerProgress,
    daysToNextRealm: realm.ceilDays! - days,
  );
}

/// 天秤上的一天。
class MaintainDayEntry {
  const MaintainDayEntry({
    required this.date,
    required this.netKcal,
    required this.balanced,
    required this.estimated,
  });

  /// 由当日修行记录换算；当日不上秤时返回 null。
  ///
  /// [totalKcal] 是减脂口径（正 = 亏空），这里取反成维持口径（正 = 盈余）。
  /// [dietCounted] 为饮食真正被计入；[cheatSurplusKcal] 为放纵日自定盈余
  /// （正数，0 = 未采用）。
  static MaintainDayEntry? fromContribution({
    required DateTime date,
    required double totalKcal,
    required bool dietCounted,
    required double? tdee,
    required double cheatSurplusKcal,
  }) {
    final estimated = cheatSurplusKcal > 0;
    if (!dietCounted && !estimated) return null;
    final net = -totalKcal;
    final balanced =
        dietCounted &&
        !estimated &&
        tdee != null &&
        net.abs() <= maintainBalanceThresholdKcal(tdee);
    return MaintainDayEntry(
      date: date,
      netKcal: net,
      balanced: balanced,
      estimated: estimated,
    );
  }

  final DateTime date;

  /// 正 = 盈余（右盘），负 = 亏空（左盘）。
  final double netKcal;

  /// 是否计为平衡日。
  final bool balanced;

  /// 是否用了放纵日自定盈余（估算值）。
  final bool estimated;
}

/// 一段维持期的天秤汇总。
class MaintainBalance {
  const MaintainBalance({
    this.leftKcal = 0,
    this.rightKcal = 0,
    this.balancedDays = 0,
    this.weighedDays = 0,
  });

  factory MaintainBalance.fromEntries(Iterable<MaintainDayEntry> entries) {
    var left = 0.0;
    var right = 0.0;
    var balanced = 0;
    var weighed = 0;
    for (final e in entries) {
      weighed++;
      if (e.balanced) balanced++;
      if (e.netKcal < 0) {
        left += -e.netKcal;
      } else {
        right += e.netKcal;
      }
    }
    return MaintainBalance(
      leftKcal: left,
      rightKcal: right,
      balancedDays: balanced,
      weighedDays: weighed,
    );
  }

  /// 左盘：累计亏空（正数）。
  final double leftKcal;

  /// 右盘：累计盈余（正数）。
  final double rightKcal;

  final int balancedDays;

  /// 上秤天数。
  final int weighedDays;

  /// 净值：正 = 整体盈余，负 = 整体亏空。
  double get netKcal => rightKcal - leftKcal;

  double get tiltRadians => balanceTiltRadians(netKcal);

  /// 左/右盘在总秤量中的占比 0..1（两盘皆空时为 0）。
  double get leftShare => _share(leftKcal);
  double get rightShare => _share(rightKcal);

  double _share(double kcal) {
    final total = leftKcal + rightKcal;
    return total <= 0 ? 0 : kcal / total;
  }
}

/// 维持玩法账本：已冻结的平衡日 + 维持时段（复用减脂的时段结构）。
class MaintainCultivationState {
  const MaintainCultivationState({
    this.frozenBalancedDays = 0,
    this.segments = const [],
  });

  /// 所有已关闭维持时段累计的平衡日。
  final int frozenBalancedDays;

  /// 时间顺序（旧在前），最多一个未关闭。
  final List<CutCultivationSegment> segments;

  CutCultivationSegment? get openSegment {
    for (final s in segments) {
      if (s.isOpen) return s;
    }
    return null;
  }

  MaintainCultivationState copyWith({
    int? frozenBalancedDays,
    List<CutCultivationSegment>? segments,
  }) {
    return MaintainCultivationState(
      frozenBalancedDays: frozenBalancedDays ?? this.frozenBalancedDays,
      segments: segments ?? this.segments,
    );
  }

  Map<String, dynamic> toJson() => {
    'frozenBalancedDays': frozenBalancedDays,
    'segments': [for (final s in segments) s.toJson()],
  };

  factory MaintainCultivationState.fromJson(Map<String, dynamic> json) {
    final raw = json['segments'];
    final segments = <CutCultivationSegment>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          segments.add(
            CutCultivationSegment.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return MaintainCultivationState(
      frozenBalancedDays: (json['frozenBalancedDays'] as num?)?.toInt() ?? 0,
      segments: segments,
    );
  }
}
