import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_providers.dart';
import 'ui/loading/discipline_freedom_loading_page.dart';
import 'ui/theme/app_theme.dart';
import 'ui/tools/rest_timer_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await RestTimerNotifications.ensureInitialized();

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
  bool _enterAnyway = false;

  @override
  Widget build(BuildContext context) {
    if (_enterAnyway) return const FitnessApp();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: DisciplineFreedomLoadingPage(
        onInitialize: () async {
          ref.invalidate(foodsSeedProvider);
          await ref.read(foodsSeedProvider.future);
        },
        onFinished: () {
          if (mounted) setState(() => _enterAnyway = true);
        },
        onError: (_) {},
        onEnterAnyway: () {
          if (mounted) setState(() => _enterAnyway = true);
        },
      ),
    );
  }
}
