import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/loading/swordsman_loading_page.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'ui/theme/app_theme.dart';
import 'ui/tools/workout_reminder_notifications.dart';

/// Skip the real bootstrap splash and open the in-app loading lab.
/// Usage: `flutter run --profile --dart-define=LOADING_LAB=true`
const _loadingLab = bool.fromEnvironment('LOADING_LAB');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // ReminderNotifications.ensureInitialized() already awaits
  // RestTimerNotifications.ensureInitialized() itself.
  await ReminderNotifications.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const _Bootstrap(),
    ),
  );
}

class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap();

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  /// The loading page is done (finished, skipped or bypassed).
  bool _ready = !kReleaseMode && _loadingLab;

  /// Build the real app behind the loading page so the hand-off is instant.
  bool _prewarm = false;

  void _enterHome() {
    if (mounted && !_ready) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    // The child list keeps a stable shape so the prewarmed [FitnessApp]
    // element survives when the loading overlay is removed.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_prewarm || _ready)
            const FitnessApp()
          else
            const SizedBox.shrink(),
          if (!_ready)
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: SwordsmanLoadingPage(
                onInitialize: () async {
                  ref.invalidate(foodsSeedProvider);
                  await ref.read(foodsSeedProvider.future);
                },
                onPrewarm: () {
                  if (mounted && !_prewarm) setState(() => _prewarm = true);
                },
                onFinished: _enterHome,
                onError: (_) {},
                onEnterAnyway: _enterHome,
              ),
            ),
        ],
      ),
    );
  }
}
