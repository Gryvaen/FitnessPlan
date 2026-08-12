import 'package:shared_preferences/shared_preferences.dart';

import '../../ui/theme/app_theme.dart';

const _themeIdKey = 'app_theme_id';

class ThemeRepository {
  ThemeRepository(this._prefs);

  final SharedPreferences _prefs;

  AppThemeId load() => AppThemeId.fromStorage(_prefs.getString(_themeIdKey));

  Future<void> save(AppThemeId id) async {
    await _prefs.setString(_themeIdKey, id.name);
  }
}
