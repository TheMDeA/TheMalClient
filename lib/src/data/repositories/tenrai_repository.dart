import 'package:dio/dio.dart';
import 'package:malclient/src/core/config.dart';
import 'package:malclient/src/core/demo/demo_data.dart';
import 'package:malclient/src/data/models/media.dart';

/// Tenrai (https://api.tenrai.org/v1) — free, no key, Jikan-compatible.
///
/// MAL API v2 does NOT provide reviews, characters, staff or news, so those
/// come from Tenrai (Jikan's public API was discontinued Oct 2026).
/// Works in demo mode too (falls back to bundled data when the network
/// call fails).
class TenraiRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: tenraiApiBase,
    connectTimeout: const Duration(seconds: 15),
    // Tenrai serves cached data quickly.
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'User-Agent': 'MALClient/1.2.3 (https://github.com/TheMDeA/TheMalClient)',
    },
  ));

  /// GET with retry on 429s and transient network errors, up to
  /// 3 attempts with backoff, before giving up.
  Future<Response> _get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    DioException? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await _dio.get(path, queryParameters: queryParameters);
      } on DioException catch (e) {
        lastError = e;
        final retryable = e.response?.statusCode == 429 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError;
        if (retryable && attempt < 2) {
          // Backoff: 2s, 4s.
          await Future.delayed(Duration(seconds: (attempt + 1) * 2));
          continue;
        }
        rethrow;
      }
    }
    throw lastError!;
  }

  Future<List<Review>> animeReviews(int malId, {int limit = 10}) async {
    try {
      final res = await _get(
        '/anime/$malId/reviews',
        queryParameters: {'limit': limit, 'preliminary': false},
      );
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! List) return DemoData.reviews;
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) Review.fromJikan(e)
      ];
    } catch (_) {
      return DemoData.reviews;
    }
  }

  Future<List<AnimeSummary>> animeRecommendations(int malId,
      {int limit = 12}) async {
    try {
      final res = await _get('/anime/$malId/recommendations');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! List) return const [];
      final out = <AnimeSummary>[];
      for (final e in data) {
        if (e is! Map<String, dynamic>) continue;
        final entry = e['entry'];
        if (entry is! Map<String, dynamic>) continue;
        final images = entry['images'];
        out.add(AnimeSummary(
          id: (entry['mal_id'] as num).toInt(),
          title: (entry['title'] ?? '') as String,
          imageUrl: images is Map<String, dynamic>
              ? (images['jpg']?['image_url']) as String?
              : null,
        ));
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// News for one anime (used on the detail screen).
  Future<List<NewsItem>> animeNews(int malId, {int limit = 6}) async {
    try {
      final res = await _get('/anime/$malId/news');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! List) return const [];
      return [
        for (final e in data.take(limit))
          if (e is Map<String, dynamic>) NewsItem.fromJikan(e)
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Characters with voice actors (`/anime/{id}/characters`).
  /// Throws on network/API errors so the UI can show the error state
  /// (instead of the misleading "no characters found").
  Future<List<AnimeCharacter>> animeCharacters(int malId) async {
    final res = await _get('/anime/$malId/characters');
    final data = (res.data as Map<String, dynamic>)['data'];
    if (data is! List) return const [];
    final out = [
      for (final e in data)
        if (e is Map<String, dynamic>) AnimeCharacter.fromJikan(e)
    ];
    // Main characters first.
    out.sort((a, b) {
      int rank(String r) => r == 'Main' ? 0 : 1;
      return rank(a.role).compareTo(rank(b.role));
    });
    return out;
  }

  /// Staff (`/anime/{id}/staff`).
  /// Throws on network/API errors so the UI can show the error state.
  Future<List<AnimeStaff>> animeStaff(int malId) async {
    final res = await _get('/anime/$malId/staff');
    final data = (res.data as Map<String, dynamic>)['data'];
    if (data is! List) return const [];
    return [
      for (final e in data)
        if (e is Map<String, dynamic>) AnimeStaff.fromJikan(e)
    ];
  }

  /// Aggregate statistics (`/anime/{id}/statistics`).
  Future<AnimeStatistics?> animeStatistics(int malId) async {
    try {
      final res = await _get('/anime/$malId/statistics');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! Map<String, dynamic>) return null;
      return AnimeStatistics.fromJikan(data);
    } catch (_) {
      return null;
    }
  }

  /// Aggregate statistics (`/manga/{id}/statistics`). Same shape as the
  /// anime endpoint, with `reading`/`plan_to_read` keys (handled by
  /// [AnimeStatistics.fromJikan]).
  Future<AnimeStatistics?> mangaStatistics(int malId) async {
    try {
      final res = await _get('/manga/$malId/statistics');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! Map<String, dynamic>) return null;
      return AnimeStatistics.fromJikan(data);
    } catch (_) {
      return null;
    }
  }

  /// Manga reviews (`/manga/{id}/reviews`). Same shape as anime reviews.
  Future<List<Review>> mangaReviews(int malId, {int limit = 10}) async {
    try {
      final res = await _get(
        '/manga/$malId/reviews',
        queryParameters: {'limit': limit, 'preliminary': false},
      );
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! List) return DemoData.reviews;
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) Review.fromJikan(e)
      ];
    } catch (_) {
      return DemoData.reviews;
    }
  }

  /// Full character details (`/characters/{id}`).
  /// Returns null on network/API errors.
  Future<CharacterDetail?> characterDetail(int malId) async {
    try {
      final res = await _get('/characters/$malId');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! Map<String, dynamic>) return null;
      return CharacterDetail.fromJikan(data);
    } catch (_) {
      return null;
    }
  }

  /// Anime a character appears in (`/characters/{id}/anime`).
  Future<List<CharacterAnime>> characterAnime(int malId) async {
    try {
      final res = await _get('/characters/$malId/anime');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! List) return const [];
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) CharacterAnime.fromJikan(e),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Full staff/person details (`/people/{id}`).
  /// Returns null on network/API errors.
  Future<StaffDetail?> staffDetail(int malId) async {
    try {
      final res = await _get('/people/$malId');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! Map<String, dynamic>) return null;
      return StaffDetail.fromJikan(data);
    } catch (_) {
      return null;
    }
  }

  /// Anime a staff member worked on (`/people/{id}/anime`).
  Future<List<StaffAnime>> staffAnime(int malId) async {
    try {
      final res = await _get('/people/$malId/anime');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! List) return const [];
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) StaffAnime.fromJikan(e),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Picture URLs (large) for an anime or manga
  /// (`/anime/{id}/pictures` or `/manga/{id}/pictures`).
  /// Returns empty on network/API errors.
  Future<List<String>> pictures(int malId, {required bool isAnime}) async {
    try {
      final res = await _get('/${isAnime ? 'anime' : 'manga'}/$malId/pictures');
      final data = (res.data as Map<String, dynamic>)['data'];
      if (data is! List) return const [];
      return [
        for (final e in data)
          if (e is Map<String, dynamic>) _jpgLarge(e),
      ].whereType<String>().toList();
    } catch (_) {
      return const [];
    }
  }

  /// Picture URLs (large) for an anime (`/anime/{id}/pictures`).
  /// Returns empty on network/API errors.
  Future<List<String>> animePictures(int malId) =>
      pictures(malId, isAnime: true);

  /// Extracts the large (falling back to regular) jpg URL from a
  /// Jikan-style picture entry, or null.
  String? _jpgLarge(Map<String, dynamic> e) {
    final jpg = e['jpg'];
    if (jpg is! Map) return null;
    return (jpg['large_image_url'] ?? jpg['image_url']) as String?;
  }

  /// Characters for a manga (`/manga/{id}/characters`).
  /// Throws on network/API errors so the UI can show the error state.
  Future<List<AnimeCharacter>> mangaCharacters(int malId) async {    final res = await _get('/manga/$malId/characters');
    final data = (res.data as Map<String, dynamic>)['data'];
    if (data is! List) return const [];
    return [
      for (final e in data)
        if (e is Map<String, dynamic>) AnimeCharacter.fromJikan(e)
    ];
  }

  /// Aggregated news for the Home rail: pulls news for a few well-known
  /// currently-airing anime and merges the freshest items.
  Future<List<NewsItem>> homeNews() async {
    const ids = [52991, 21, 51009, 52034, 38000];
    final results = await Future.wait([
      for (final id in ids) animeNews(id, limit: 2),
    ]);
    final all = results.expand((e) => e).toList();
    if (all.isEmpty) return DemoData.news;
    return all.take(10).toList();
  }

  /// Full news feed for the News screen: pulls news for a wider set of
  /// popular anime and merges them newest-first.
  Future<List<NewsItem>> allNews() async {
    const ids = [
      52991, // Frieren
      21, // One Piece
      5114, // Fullmetal Alchemist: Brotherhood
      9253, // Steins;Gate
      38524, // Attack on Titan S3P2
      51009, // Jujutsu Kaisen 0
      52034, // Oshi no Ko
      38000, // Demon Slayer
      41467, // Bleach: Thousand-Year Blood War
      37430, // Bunny Girl Senpai
      32281, // Your Name
      28977, // Gintama°
    ];
    final results = await Future.wait([
      for (final id in ids) animeNews(id, limit: 3),
    ]);
    final all = results.expand((e) => e).toList();
    if (all.isEmpty) return DemoData.news;
    // ISO dates: string comparison == chronological order.
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }
}
