import 'package:dio/dio.dart';
import 'package:malclient/src/core/config.dart';
import 'package:malclient/src/core/demo/demo_data.dart';
import 'package:malclient/src/data/models/media.dart';

/// Jikan (https://api.jikan.moe/v4) — free, no key, rate-limited.
///
/// MAL API v2 does NOT provide reviews, recommendations or news, so those
/// come from Jikan. Works in demo mode too (falls back to bundled data
/// when the network call fails).
class JikanRepository {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: jikanApiBase,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'User-Agent': 'MALClient/1.2.1 (https://github.com/TheMDeA/TheMalClient)',
    },
  ));

  /// GET with retry on 429 (Jikan rate limit: 3 req/s). Waits and retries
  /// up to 3 times with exponential backoff before giving up.
  Future<Response> _get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    DioException? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await _dio.get(path, queryParameters: queryParameters);
      } on DioException catch (e) {
        lastError = e;
        if (e.response?.statusCode == 429 && attempt < 2) {
          // Exponential backoff: 1s, 2s.
          await Future.delayed(Duration(seconds: attempt + 1));
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

  /// Characters for a manga (`/manga/{id}/characters`).
  /// Throws on network/API errors so the UI can show the error state.
  Future<List<AnimeCharacter>> mangaCharacters(int malId) async {
    final res = await _get('/manga/$malId/characters');
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
    final all = <NewsItem>[];
    for (final id in ids) {
      final items = await animeNews(id, limit: 2);
      all.addAll(items);
      // Jikan rate limit: 3 req/s — be polite.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
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
    final all = <NewsItem>[];
    for (final id in ids) {
      final items = await animeNews(id, limit: 3);
      all.addAll(items);
      // Jikan rate limit: 3 req/s — be polite.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    if (all.isEmpty) return DemoData.news;
    // ISO dates: string comparison == chronological order.
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }
}
