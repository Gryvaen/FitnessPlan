/// Local calendar-day helpers (time-of-day stripped).
abstract final class CalendarDay {
  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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
