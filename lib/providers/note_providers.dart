import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import 'core_providers.dart';

final dailyNotesProvider = StreamProvider<List<DailyNote>>((ref) {
  return ref.watch(noteRepositoryProvider).watchAll();
});
