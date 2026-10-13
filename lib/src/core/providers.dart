import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:malclient/src/core/api/mal_api_client.dart';
import 'package:malclient/src/core/theme/app_theme.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/data/repositories/auth_repository.dart';
import 'package:malclient/src/data/repositories/jikan_repository.dart';
import 'package:malclient/src/data/repositories/list_repository.dart';
import 'package:malclient/src/data/repositories/media_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------- platform services ----------

/// Overridden in main() with the real instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('sharedPrefsProvider not initialized'),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

// ---------- auth ----------

enum AuthStatus { unknown, loggedOut, demo, authenticated }

class AuthState {
  final AuthStatus status;
  final MalUser? user;

  /// True right after a fresh OAuth login — shows the welcome confirmation
  /// page once, then cleared.
  final bool freshLogin;

  const AuthState(this.status, [this.user, this.freshLogin = false]);

  bool get isDemo => status == AuthStatus.demo;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoggedIn => isDemo || isAuthenticated;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(secureStorageProvider),
    ref.watch(sharedPrefsProvider),
  );
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    if (await repo.isDemoMode()) {
      return const AuthState(AuthStatus.demo);
    }
    if (await repo.hasTokens()) {
      try {
        final user = await ref.watch(mediaRepositoryProvider).myUser();
        return AuthState(AuthStatus.authenticated, user);
      } catch (_) {
        // Tokens invalid and refresh failed -> fall through to logged out.
        await repo.logout();
      }
    }
    return const AuthState(AuthStatus.loggedOut);
  }

  Future<void> continueAsDemo() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.setDemoMode(true);
    _invalidateRepos();
    state = const AsyncData(AuthState(AuthStatus.demo));
  }

  /// Called when the `malclient://oauth?code=...` redirect is captured.
  Future<void> completeOAuth(String code) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.exchangeCode(code);
      _invalidateRepos();
      final user = await ref.read(mediaRepositoryProvider).myUser();
      state = AsyncData(AuthState(AuthStatus.authenticated, user, true));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Clears the one-time welcome flag after the confirmation page is done.
  Future<void> dismissWelcome() async {
    final current = state.value;
    if (current != null && current.freshLogin) {
      state = AsyncData(AuthState(current.status, current.user));
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    _invalidateRepos();
    state = const AsyncData(AuthState(AuthStatus.loggedOut));
  }

  void _invalidateRepos() {
    ref.invalidate(mediaRepositoryProvider);
    ref.invalidate(listRepositoryProvider);
    ref.invalidate(myAnimeListProvider);
    ref.invalidate(myMangaListProvider);
  }
}

// ---------- api + repositories ----------

final malApiClientProvider = Provider<MalApiClient>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return MalApiClient(
    getAccessToken: repo.getValidAccessToken,
    refreshToken: repo.refresh,
  );
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  // Demo mode is a plain shared-preferences flag (synchronous read);
  // AuthController invalidates this provider whenever it changes.
  final demo = ref.watch(sharedPrefsProvider).getBool('demo_mode') ?? false;
  return MediaRepository(ref.watch(malApiClientProvider), demo: demo);
});

final listRepositoryProvider = Provider<ListRepository>((ref) {
  final demo = ref.watch(sharedPrefsProvider).getBool('demo_mode') ?? false;
  return ListRepository(ref.watch(malApiClientProvider), demo: demo);
});

final jikanRepositoryProvider = Provider<JikanRepository>(
  (_) => JikanRepository(),
);

// ---------- theme ----------

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(
          _key,
          switch (mode) {
            ThemeMode.light => 'light',
            ThemeMode.dark => 'dark',
            ThemeMode.system => 'system',
          },
        );
  }
}

final accentProvider =
    NotifierProvider<AccentNotifier, AppAccent>(AccentNotifier.new);

class AccentNotifier extends Notifier<AppAccent> {
  static const _key = 'accent';

  @override
  AppAccent build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    return AppAccent.values.asNameMap()[raw] ?? AppAccent.ember;
  }

  Future<void> set(AppAccent accent) async {
    state = accent;
    await ref.read(sharedPrefsProvider).setString(_key, accent.name);
  }
}

// ---------- feature data ----------

final seasonalAnimeProvider = FutureProvider<List<AnimeSummary>>((ref) {
  return ref.watch(mediaRepositoryProvider).seasonalAnime();
});

final topAnimeProvider = FutureProvider<List<AnimeSummary>>((ref) {
  return ref.watch(mediaRepositoryProvider).topAnime();
});

final topMangaProvider = FutureProvider<List<MangaSummary>>((ref) {
  return ref.watch(mediaRepositoryProvider).topManga();
});

final homeNewsProvider = FutureProvider<List<NewsItem>>((ref) {
  return ref.watch(jikanRepositoryProvider).homeNews();
});

/// My anime list, filtered by status (null = all).
final myAnimeListProvider =
    FutureProvider.family<List<AnimeListEntry>, String?>((ref, status) {
  return ref.watch(listRepositoryProvider).animeList(status: status);
});

/// My manga list, filtered by status (null = all).
final myMangaListProvider =
    FutureProvider.family<List<MangaListEntry>, String?>((ref, status) {
  return ref.watch(listRepositoryProvider).mangaList(status: status);
});

/// Refreshes both list providers after an edit.
void invalidateMyLists(WidgetRef ref) {
  ref.invalidate(myAnimeListProvider);
  ref.invalidate(myMangaListProvider);
}
