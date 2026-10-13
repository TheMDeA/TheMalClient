import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:malclient/src/core/api/mal_api_client.dart';
import 'package:malclient/src/core/theme/app_theme.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/data/repositories/auth_repository.dart';
import 'package:malclient/src/data/repositories/tenrai_repository.dart';
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

final tenraiRepositoryProvider = Provider<TenraiRepository>(
  (_) => TenraiRepository(),
);

// ---------- theme ----------

/// Theme mode options: auto (follow system), light, dark, and black
/// (AMOLED pure-black dark).
enum AppThemeMode { auto, light, dark, black }

extension AppThemeModeX on AppThemeMode {
  String get label => switch (this) {
        AppThemeMode.auto => 'Auto',
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
        AppThemeMode.black => 'Black',
      };

  ThemeMode get flutterMode => switch (this) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark || AppThemeMode.black => ThemeMode.dark,
        AppThemeMode.auto => ThemeMode.system,
      };

  bool get amoled => this == AppThemeMode.black;
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, AppThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  static const _key = 'theme_mode';

  @override
  AppThemeMode build() {
    // Migrates the old ThemeMode keys ('system' -> auto).
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    return switch (raw) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      'black' => AppThemeMode.black,
      _ => AppThemeMode.auto,
    };
  }

  Future<void> set(AppThemeMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(_key, mode.name);
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

/// App font: 'system' for the default, otherwise a Google Fonts family name.
final appFontProvider =
    NotifierProvider<AppFontNotifier, String>(AppFontNotifier.new);

class AppFontNotifier extends Notifier<String> {
  static const _key = 'app_font';

  /// Fonts offered in the picker (Google Fonts family names).
  static const options = ['Inter', 'Nunito', 'Poppins', 'Rubik', 'Lora'];

  @override
  String build() =>
      ref.watch(sharedPrefsProvider).getString(_key) ?? 'system';

  Future<void> set(String font) async {
    state = font;
    await ref.read(sharedPrefsProvider).setString(_key, font);
  }
}

/// Start/end date auto-setters for list entries.
///
/// When enabled, saving an entry with a given status automatically stamps
/// the start/finish date with today. If [allowOverride] is on, a manually
/// chosen date is never overwritten — the auto-setter only fills empty dates.
class DateAutoSet {
  final bool startOnAdd;
  final bool startOnWatching;
  final bool endOnCompleted;
  final bool endOnDropped;
  final bool allowOverride;

  const DateAutoSet({
    this.startOnAdd = false,
    this.startOnWatching = false,
    this.endOnCompleted = false,
    this.endOnDropped = false,
    this.allowOverride = false,
  });

  DateAutoSet copyWith({
    bool? startOnAdd,
    bool? startOnWatching,
    bool? endOnCompleted,
    bool? endOnDropped,
    bool? allowOverride,
  }) =>
      DateAutoSet(
        startOnAdd: startOnAdd ?? this.startOnAdd,
        startOnWatching: startOnWatching ?? this.startOnWatching,
        endOnCompleted: endOnCompleted ?? this.endOnCompleted,
        endOnDropped: endOnDropped ?? this.endOnDropped,
        allowOverride: allowOverride ?? this.allowOverride,
      );
}

final dateAutoSetProvider =
    NotifierProvider<DateAutoSetNotifier, DateAutoSet>(
        DateAutoSetNotifier.new);

class DateAutoSetNotifier extends Notifier<DateAutoSet> {
  static const _p = 'date_auto_';

  @override
  DateAutoSet build() {
    final prefs = ref.watch(sharedPrefsProvider);
    return DateAutoSet(
      startOnAdd: prefs.getBool('${_p}start_on_add') ?? false,
      startOnWatching: prefs.getBool('${_p}start_on_watching') ?? false,
      endOnCompleted: prefs.getBool('${_p}end_on_completed') ?? false,
      endOnDropped: prefs.getBool('${_p}end_on_dropped') ?? false,
      allowOverride: prefs.getBool('${_p}allow_override') ?? false,
    );
  }

  Future<void> _set(String key, bool value,
      DateAutoSet Function(DateAutoSet) apply) async {
    state = apply(state);
    await ref.read(sharedPrefsProvider).setBool('$_p$key', value);
  }

  Future<void> setStartOnAdd(bool v) =>
      _set('start_on_add', v, (s) => s.copyWith(startOnAdd: v));
  Future<void> setStartOnWatching(bool v) => _set(
      'start_on_watching', v, (s) => s.copyWith(startOnWatching: v));
  Future<void> setEndOnCompleted(bool v) =>
      _set('end_on_completed', v, (s) => s.copyWith(endOnCompleted: v));
  Future<void> setEndOnDropped(bool v) =>
      _set('end_on_dropped', v, (s) => s.copyWith(endOnDropped: v));
  Future<void> setAllowOverride(bool v) =>
      _set('allow_override', v, (s) => s.copyWith(allowOverride: v));
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
  return ref.watch(tenraiRepositoryProvider).homeNews();
});

/// Full news feed for the News screen.
final newsProvider = FutureProvider<List<NewsItem>>((ref) {
  return ref.watch(tenraiRepositoryProvider).allNews();
});

/// Characters for an anime (Jikan).
final animeCharactersProvider =
    FutureProvider.family<List<AnimeCharacter>, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).animeCharacters(id);
});

/// Staff for an anime (Jikan).
final animeStaffProvider =
    FutureProvider.family<List<AnimeStaff>, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).animeStaff(id);
});

/// Aggregate statistics for an anime (Jikan).
final animeStatisticsProvider =
    FutureProvider.family<AnimeStatistics?, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).animeStatistics(id);
});

/// Characters for a manga (Jikan).
final mangaCharactersProvider =
    FutureProvider.family<List<AnimeCharacter>, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).mangaCharacters(id);
});

/// Pictures for an anime or manga (Tenrai).
final animePicturesProvider =
    FutureProvider.family<List<String>, ({int id, bool isAnime})>((ref, args) {
  return ref.watch(tenraiRepositoryProvider).pictures(
        args.id,
        isAnime: args.isAnime,
      );
});

/// Full character details (Tenrai).
final characterDetailProvider =
    FutureProvider.family<CharacterDetail?, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).characterDetail(id);
});

/// Anime a character appears in (Tenrai).
final characterAnimeProvider =
    FutureProvider.family<List<CharacterAnime>, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).characterAnime(id);
});

/// Full staff/person details (Tenrai).
final staffDetailProvider = FutureProvider.family<StaffDetail?, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).staffDetail(id);
});

/// Anime a staff member worked on (Tenrai).
final staffAnimeProvider = FutureProvider.family<List<StaffAnime>, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).staffAnime(id);
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
