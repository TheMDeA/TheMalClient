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
  ));

  Future<List<Review>> animeReviews(int malId, {int limit = 10}) async {
    try {
      final res = await _dio.get(
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
      final res = await _dio.get('/anime/$malId/recommendations');
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
      final res = await _dio.get('/anime/$malId/news');
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
}
