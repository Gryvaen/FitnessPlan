/// Local calendar-day helpers (time-of-day stripped).
abstract final class CalendarDay {
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// [d]'s calendar day shifted by [n] days. Unlike `add(Duration(days: n))`
  /// this stays on local midnight across daylight-saving changes.
  static DateTime addDays(DateTime d, int n) =>
      DateTime(d.year, d.month, d.day + n);

  /// Whole calendar days from [from] to [to], ignoring time of day and
  /// daylight-saving changes (a 23- or 25-hour local day still counts as 1).
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  static DateTime todayLocal([DateTime? now]) {
    final n = now ?? DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static bool isLocalToday(DateTime d, [DateTime? now]) =>
      dayOnly(d) == todayLocal(now);

  /// Throws if [d] is not today's local calendar day.
  static void ensureEditableDay(DateTime d, [DateTime? now]) {
    if (!isLocalToday(d, now)) {
      throw StateError('只能编辑今天的记录');
    }
  }
}
