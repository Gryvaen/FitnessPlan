import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'ui/loading/discipline_freedom_loading_page.dart';
import 'ui/loading/loading_lab_page.dart';
import 'ui/theme/app_theme.dart';
import 'ui/tools/workout_reminder_notifications.dart';

/// Splash playground: loops opening UI without entering Home.
///
/// `flutter run --dart-define=LOADING_LAB=true`
const bool kLoadingLab = bool.fromEnvironment('LOADING_LAB');

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native launch screen until Flutter has decoded the opening frame.
  // Lab uses the same gate so the first painted frame is progress 0, not a
  // blank window or a frame that already moved.
  binding.deferFirstFrame();
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
  bool _ready = false;

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
              home: kLoadingLab
                  ? const LoadingLabPage()
                  : DisciplineFreedomLoadingPage(
                      releaseDeferredFirstFrame: true,
                      onInitialize: () async {
                        // Kick the seed sync off but don't block the splash
                        // on it: it can take longer than the 1.4s entrance
                        // on a cold DB (batch upsert + obsolete-row cleanup),
                        // and every screen that reads foods already awaits
                        // this same future before showing food data.
                        ref.invalidate(foodsSeedProvider);
                        unawaited(ref.read(foodsSeedProvider.future));
                      },
                      onPrewarm: () {
                        if (mounted && !_prewarm) {
                          setState(() => _prewarm = true);
                        }
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
