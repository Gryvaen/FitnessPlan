import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db.dart';
import 'core_providers.dart';

final weightLogsProvider = StreamProvider<List<WeightLog>>((ref) {
  return ref.watch(weightRepositoryProvider).watchAll();
});
