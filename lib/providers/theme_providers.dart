import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/theme/app_theme.dart';
import 'core_providers.dart';

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeId>(
  ThemeNotifier.new,
);

class ThemeNotifier extends Notifier<AppThemeId> {
  @override
  AppThemeId build() {
    return ref.read(themeRepositoryProvider).load();
  }

  Future<void> select(AppThemeId id) async {
    if (state == id) return;
    await ref.read(themeRepositoryProvider).save(id);
    state = id;
  }
}
