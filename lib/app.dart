import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'l10n/app_localizations_ext.dart';
import 'providers/app_providers.dart';
import 'ui/foods/custom_food_edit_page.dart';
import 'ui/foods/food_category_page.dart';
import 'ui/foods/food_detail_page.dart';
import 'ui/foods/food_favorites_page.dart';
import 'ui/foods/foods_page.dart';
import 'ui/meals/log_meal_page.dart';
import 'ui/meals/meal_detail_page.dart';
import 'ui/onboarding/onboarding_page.dart';
import 'ui/profile/profile_edit_page.dart';
import 'ui/profile/profile_page.dart';
import 'ui/records/note_edit_page.dart';
import 'ui/records/plan_edit_page.dart';
import 'ui/records/records_page.dart';
import 'ui/shell/main_shell.dart';
import 'ui/shell/swipeable_branch_container.dart';
import 'ui/today/today_page.dart';
import 'ui/theme/app_theme.dart';
import 'ui/tools/body_fat_page.dart';
import 'ui/tools/body_metrics_page.dart';
import 'ui/tools/calculator_page.dart';
import 'ui/tools/food_convert_page.dart';
import 'ui/tools/rest_timer_page.dart';
import 'ui/tools/tools_hub_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(profileProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/today',
    refreshListenable: refresh,
    redirect: (context, state) {
      final profile = ref.read(profileProvider);
      final onboarding = state.matchedLocation == '/onboarding';
      if (profile == null && !onboarding) return '/onboarding';
      if (profile != null && onboarding) return '/today';
      if (state.matchedLocation == '/weight') return '/records';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return SwipeableBranchContainer(
            currentIndex: navigationShell.currentIndex,
            onIndexChanged: (index) => navigationShell.goBranch(index),
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/foods',
                builder: (context, state) => const FoodsPage(),
                routes: [
                  GoRoute(
                    path: 'category',
                    builder: (context, state) {
                      final category =
                          state.uri.queryParameters['name'] ?? '';
                      return FoodCategoryPage(category: category);
                    },
                  ),
                  GoRoute(
                    path: 'favorites',
                    builder: (context, state) => const FoodFavoritesPage(),
                  ),
                  GoRoute(
                    path: 'custom',
                    builder: (context, state) {
                      final idStr = state.uri.queryParameters['id'];
                      final id = idStr == null ? null : int.tryParse(idStr);
                      return CustomFoodEditPage(foodId: id);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return Scaffold(
                          body: Center(
                            child: Text(context.l10n.invalidFood),
                          ),
                        );
                      }
                      return FoodDetailPage(foodId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/records',
                builder: (context, state) {
                  final tab = state.uri.queryParameters['tab'];
                  final segment = switch (tab) {
                    'train' => RecordsSegment.train,
                    'notes' => RecordsSegment.notes,
                    _ => RecordsSegment.body,
                  };
                  return RecordsPage(initialSegment: segment);
                },
                routes: [
                  GoRoute(
                    path: 'plan',
                    builder: (context, state) {
                      final idStr = state.uri.queryParameters['id'];
                      final id = idStr == null ? null : int.tryParse(idStr);
                      return PlanEditPage(planId: id);
                    },
                  ),
                  GoRoute(
                    path: 'notes/edit',
                    builder: (context, state) {
                      final raw = state.uri.queryParameters['date'];
                      DateTime? day;
                      if (raw != null && raw.isNotEmpty) {
                        day = DateTime.tryParse(raw);
                      }
                      return NoteEditPage(date: day);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const ProfileEditPage(),
                  ),
                  GoRoute(
                    path: 'tools',
                    builder: (context, state) => const ToolsHubPage(),
                    routes: [
                      GoRoute(
                        path: 'body-fat',
                        builder: (context, state) => const BodyFatPage(),
                      ),
                      GoRoute(
                        path: 'body-metrics',
                        builder: (context, state) => const BodyMetricsPage(),
                      ),
                      GoRoute(
                        path: 'food-convert',
                        builder: (context, state) => const FoodConvertPage(),
                      ),
                      GoRoute(
                        path: 'rest-timer',
                        builder: (context, state) => const RestTimerPage(),
                      ),
                      GoRoute(
                        path: 'calculator',
                        builder: (context, state) => const CalculatorPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/log-meal',
        builder: (context, state) {
          final idStr = state.uri.queryParameters['foodId'];
          final id = idStr == null ? null : int.tryParse(idStr);
          return LogMealPage(initialFoodId: id);
        },
      ),
      GoRoute(
        path: '/meal/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return Scaffold(
              body: Center(
                child: Text(context.l10n.invalidRecord),
              ),
            );
          }
          return MealDetailPage(entryId: id);
        },
      ),
    ],
  );
});

class FitnessApp extends ConsumerStatefulWidget {
  const FitnessApp({super.key});

  @override
  ConsumerState<FitnessApp> createState() => _FitnessAppState();
}

class _FitnessAppState extends ConsumerState<FitnessApp> {
  @override
  void reassemble() {
    super.reassemble();
    // Hot reload can leave UserProfile instances with uninitialized new fields;
    // rehydrate from SharedPreferences.
    ref.read(profileProvider.notifier).reload();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appTitle,
      localeResolutionCallback: (locale, supported) {
        // Follow system language; fall back to English when unsupported.
        if (locale == null) return const Locale('en');
        for (final s in supported) {
          if (s.languageCode == locale.languageCode) return locale;
        }
        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
