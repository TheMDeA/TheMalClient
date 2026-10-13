import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/features/detail/detail_screen.dart';
import 'package:malclient/src/features/discover/discover_screen.dart';
import 'package:malclient/src/features/history/history_screen.dart';
import 'package:malclient/src/features/home/home_screen.dart';
import 'package:malclient/src/features/login/login_screen.dart';
import 'package:malclient/src/features/mylist/mylist_screen.dart';
import 'package:malclient/src/features/profile/profile_screen.dart';
import 'package:malclient/src/features/schedule/schedule_screen.dart';
import 'package:malclient/src/features/news/news_screen.dart';
import 'package:malclient/src/features/settings/about_screen.dart';
import 'package:malclient/src/features/settings/list_preferences_screen.dart';
import 'package:malclient/src/features/settings/settings_screen.dart';
import 'package:malclient/src/features/settings/theme_settings_screen.dart';
import 'package:malclient/src/features/setup/setup_screen.dart';
import 'package:malclient/src/features/welcome/welcome_screen.dart';
import 'package:malclient/src/widgets/app_shell.dart';

/// Bridges the Riverpod auth state into go_router's [refreshListenable] so
/// `redirect` re-runs when login completes, fails, or the user logs out —
/// otherwise the app would sit on /login forever after a successful OAuth
/// exchange because no navigation event fires.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

/// Shared page transition: fade + slight slide-up, used for pushed routes
/// (detail, settings, news, history) so navigation feels designed rather
/// than the platform default.
CustomTransitionPage<T> _fadeSlidePage<T>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(fade);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      // The OAuth redirect (malclient://oauth?code=...) is captured and
      // completed by the app_links listener in main.dart. Stop go_router
      // from treating it as a navigation location first — no route matches
      // a custom-scheme URI, and it would throw "no routes for location".
      if (state.uri.scheme == 'malclient') return '/login';

      final authValue = ref.read(authControllerProvider);
      // While auth state is still loading, don't redirect anywhere.
      if (authValue.isLoading || authValue.hasError) return null;
      final auth = authValue.value;
      final status = auth?.status ?? AuthStatus.loggedOut;
      final loggedIn =
          status == AuthStatus.authenticated || status == AuthStatus.demo;
      final loc = state.matchedLocation;
      final onLogin = loc == '/login';
      final onWelcome = loc == '/welcome';
      final onSetup = loc == '/setup';

      if (!loggedIn && !onLogin) return '/login';
      // Fresh OAuth login lands on the welcome confirmation once, then the
      // theme setup; every other entry goes straight home.
      if (loggedIn && onLogin) {
        return (auth?.freshLogin ?? false) ? '/welcome' : '/home';
      }
      if (onWelcome && (!loggedIn || !(auth?.freshLogin ?? false))) {
        return '/home';
      }
      // Setup is part of onboarding (freshLogin) or reachable from Settings.
      if (onSetup && !loggedIn) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) {
                  final q = state.uri.queryParameters;
                  return DiscoverScreen(
                    initialTab: q['tab'],
                    focusSearch: q['focusSearch'] == 'true',
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mylist',
                builder: (context, state) => const MyListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/detail/anime/:id',
        pageBuilder: (context, state) => _fadeSlidePage(
          context,
          state,
          DetailScreen(
            kind: ListKind.anime,
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/detail/manga/:id',
        pageBuilder: (context, state) => _fadeSlidePage(
          context,
          state,
          DetailScreen(
            kind: ListKind.manga,
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/settings/theme',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const ThemeSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/list',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const ListPreferencesScreen()),
      ),
      GoRoute(
        path: '/settings/about',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const AboutScreen()),
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const HistoryScreen()),
      ),
      GoRoute(
        path: '/news',
        pageBuilder: (context, state) =>
            _fadeSlidePage(context, state, const NewsScreen()),
      ),
    ],
  );
});
