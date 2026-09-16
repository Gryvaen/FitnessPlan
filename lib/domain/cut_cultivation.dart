import '../domain/calendar_day.dart';

/// One continuous stretch of days while the user was on the cut goal.
class CutCultivationSegment {
  const CutCultivationSegment({required this.start, this.end});

  /// Inclusive local calendar day when this cut stretch began.
  final DateTime start;

  /// Inclusive local calendar day when the user left cut; `null` = still on cut.
  final DateTime? end;

  bool get isOpen => end == null;

  bool containsDay(DateTime day) {
    final d = CalendarDay.dayOnly(day);
    final s = CalendarDay.dayOnly(start);
    if (d.isBefore(s)) return false;
    final e = end;
    if (e == null) return true;
    return !d.isAfter(CalendarDay.dayOnly(e));
  }

  CutCultivationSegment closeOn(DateTime day) => CutCultivationSegment(
    start: CalendarDay.dayOnly(start),
    end: CalendarDay.dayOnly(day),
  );

  Map<String, dynamic> toJson() => {
    'start': _dayToJson(start),
    'end': end == null ? null : _dayToJson(end!),
  };

  factory CutCultivationSegment.fromJson(Map<String, dynamic> json) {
    return CutCultivationSegment(
      start: _dayFromJson(json['start'] as String)!,
      end: _dayFromJson(json['end'] as String?),
    );
  }

  static String _dayToJson(DateTime d) {
    final day = CalendarDay.dayOnly(d);
    final m = day.month.toString().padLeft(2, '0');
    final dd = day.day.toString().padLeft(2, '0');
    return '${day.year}-$m-$dd';
  }

  static DateTime? _dayFromJson(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return CalendarDay.dayOnly(parsed);
  }
}

/// Persisted cut-cultivation ledger: banked kcal from closed stretches plus
/// zero-or-one open stretch while the user is currently cutting.
class CutCultivationState {
  const CutCultivationState({
    this.frozenKcal = 0,
    this.segments = const [],
  });

  /// Total kcal banked from all **closed** cut stretches.
  final double frozenKcal;

  /// Chronological cut stretches (oldest first). At most one [isOpen].
  final List<CutCultivationSegment> segments;

  CutCultivationSegment? get openSegment {
    for (final s in segments) {
      if (s.isOpen) return s;
    }
    return null;
  }

  List<CutCultivationSegment> get closedSegments => [
    for (final s in segments)
      if (!s.isOpen) s,
  ];

  CutCultivationState copyWith({
    double? frozenKcal,
    List<CutCultivationSegment>? segments,
  }) {
    return CutCultivationState(
      frozenKcal: frozenKcal ?? this.frozenKcal,
      segments: segments ?? this.segments,
    );
  }

  Map<String, dynamic> toJson() => {
    'frozenKcal': frozenKcal,
    'segments': [for (final s in segments) s.toJson()],
  };

  factory CutCultivationState.fromJson(Map<String, dynamic> json) {
    final raw = json['segments'];
    final segments = <CutCultivationSegment>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          segments.add(CutCultivationSegment.fromJson(item));
        } else if (item is Map) {
          segments.add(
            CutCultivationSegment.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return CutCultivationState(
      frozenKcal: (json['frozenKcal'] as num?)?.toDouble() ?? 0,
      segments: segments,
    );
  }
}
