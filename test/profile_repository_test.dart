import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitness_plan/data/repositories/profile_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corrupted profile JSON returns null instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      'user_profile': '{not-json',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = ProfileRepository(prefs);
    expect(repo.load(), isNull);
  });
}
