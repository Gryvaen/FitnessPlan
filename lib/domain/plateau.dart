/// Plateau detection for weight logs.
class Plateau {
  const Plateau._();

  /// Number of most-recent weight logs required.
  static const recentCount = 7;

  /// Kg threshold for "barely changed" / resumed decline.
  static const maxKgChange = 0.3;

  /// True when there are at least [count] logs and, among the [count] most
  /// recent (by date), weight has barely moved between the earliest and
  /// latest entry.
  ///
  /// Clears once cutting resumes: latest is ≥ [maxChangeKg] below the
  /// earliest of those logs. A rise of ≥ [maxChangeKg] also clears it.
  static bool detect(
    List<({DateTime date, double weightKg})> logs, {
    int count = recentCount,
    double maxChangeKg = maxKgChange,
  }) {
    if (logs.length < count) return false;
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.sublist(sorted.length - count);
    // Compare in centigrams to avoid binary-float noise (e.g. 70.0 − 69.7).
    final deltaCg = _centigrams(recent.last.weightKg) -
        _centigrams(recent.first.weightKg);
    final thresholdCg = (maxChangeKg * 100).round();
    if (deltaCg <= -thresholdCg) return false;
    if (deltaCg >= thresholdCg) return false;
    return true;
  }

  static int _centigrams(double kg) => (kg * 100).round();
}
