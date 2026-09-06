import 'package:diet/data/services/steps_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StepsSyncStatus includes empty for zero-step guidance', () {
    expect(StepsSyncStatus.values, contains(StepsSyncStatus.empty));
  });
}
