/// Plateau detection for weight logs.
class Plateau {
  const Plateau._();

  static const days = 14;
  static const maxKgChange = 0.3;

  /// True when there are logs spanning at least [days] and the absolute
  /// weight change between the earliest-in-window and latest log is
  /// less than [maxKgChange].
  static bool detect(
    List<({DateTime date, double weightKg})> logs, {
    DateTime? now,
    int windowDays = days,
    double maxChangeKg = maxKgChange,
  }) {
    if (logs.length < 2) return false;
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    final end = now ?? DateTime.now();
    final start = end.subtract(Duration(days: windowDays));

    final inWindow =
        sorted.where((e) => !e.date.isBefore(start) && !e.date.isAfter(end));
    final list = inWindow.toList();
    if (list.length < 2) return false;

    final earliest = list.first;
    final latest = list.last;
    final spanDays = latest.date.difference(earliest.date).inDays;
    if (spanDays < windowDays - 1) return false;

    return (latest.weightKg - earliest.weightKg).abs() < maxChangeKg;
  }
}
