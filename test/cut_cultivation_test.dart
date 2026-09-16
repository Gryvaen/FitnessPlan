import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diet/data/repositories/cultivation_repository.dart';
import 'package:diet/domain/cut_cultivation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CultivationRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = CultivationRepository(prefs);
  });

  test('freeze banks open kcal and closes segment', () async {
    await repo.openSegment(preferredStart: DateTime(2026, 1, 1));
    var state = repo.load();
    expect(state.openSegment, isNotNull);

    state = await repo.freezeOpenSegment(
      openSegmentKcal: 7700,
      endDay: DateTime(2026, 2, 1),
    );
    expect(state.openSegment, isNull);
    expect(state.frozenKcal, 7700);
    expect(state.segments.single.end, DateTime(2026, 2, 1));
  });

  test('resume continues from frozen and avoids same-day overlap', () async {
    await repo.openSegment(preferredStart: DateTime(2026, 1, 1));
    await repo.freezeOpenSegment(
      openSegmentKcal: 15400,
      endDay: DateTime(2026, 3, 10),
    );
    final again = await repo.openSegment(
      preferredStart: DateTime(2026, 3, 10),
    );
    expect(again.frozenKcal, 15400);
    expect(again.openSegment?.start, DateTime(2026, 3, 11));
  });

  test('segment containsDay respects bounds', () {
    final closed = CutCultivationSegment(
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 1, 10),
    );
    expect(closed.containsDay(DateTime(2026, 1, 1)), isTrue);
    expect(closed.containsDay(DateTime(2026, 1, 10)), isTrue);
    expect(closed.containsDay(DateTime(2026, 1, 11)), isFalse);
  });
}
