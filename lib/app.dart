import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/app_providers.dart';
import 'ui/foods/food_category_page.dart';
import 'ui/foods/food_detail_page.dart';
import 'ui/foods/foods_page.dart';
import 'ui/meals/log_meal_page.dart';
import 'ui/meals/meal_detail_page.dart';
import 'ui/onboarding/onboarding_page.dart';
import 'ui/profile/profile_page.dart';
import 'ui/shell/main_shell.dart';
import 'ui/today/today_page.dart';
import 'ui/theme/app_theme.dart';
import 'ui/weight/weight_page.dart';

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
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
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
                    path: ':id',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '');
                      if (id == null) {
                        return const Scaffold(
                          body: Center(child: Text('无效的食材')),
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
                path: '/weight',
                builder: (context, state) => const WeightPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
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
            return const Scaffold(
              body: Center(child: Text('无效的记录')),
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
      title: '健身饮食',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
