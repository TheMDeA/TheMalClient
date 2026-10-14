import 'package:malclient/src/core/api/mal_api_client.dart';
import 'package:malclient/src/core/config.dart';
import 'package:malclient/src/core/demo/demo_data.dart';
import 'package:malclient/src/data/models/media.dart';

const _animeFields =
    'id,title,main_picture,mean,rank,popularity,num_episodes,media_type,'
    'status,genres,synopsis,start_season,start_date,end_date,broadcast,studios,num_list_users';

const _mangaFields =
    'id,title,main_picture,mean,rank,popularity,num_chapters,num_volumes,'
    'media_type,status,genres,synopsis,num_list_users';

const _animeDetailFields =
    '$_animeFields,alternative_titles,source,average_episode_duration,rating,'
    'related_anime,recommendations,my_list_status';

const _mangaDetailFields =
    '$_mangaFields,alternative_titles,authors,related_manga,recommendations,'
    'my_list_status';

/// Browse/search/details for anime + manga.
///
/// Source: MAL API v2 when authenticated with a real client ID,
/// otherwise the bundled demo data.
class MediaRepository {
  final MalApiClient _client;
  final bool _demo;

  MediaRepository(this._client, {required this._demo});

  bool get isDemo => _demo || !hasRealClientId;

  // ---------- anime ----------

  Future<List<AnimeSummary>> seasonalAnime({int limit = 24}) async {
    if (isDemo) return DemoData.seasonalAnime;
    final now = DateTime.now();
    final season = _seasonOf(now.month);
    final res = await _client.dio.get(
      '/anime/season/${now.year}/$season',
      queryParameters: {
        'sort': 'anime_num_list_users',
        'fields': _animeFields,
        'limit': limit,
      },
    );
    return _animeList(res.data);
  }

  Future<List<AnimeSummary>> topAnime({int limit = 24}) async {
    if (isDemo) return DemoData.seasonalAnime;
    final res = await _client.dio.get(
      '/anime/ranking',
      queryParameters: {
        'ranking_type': 'all',
        'fields': _animeFields,
        'limit': limit,
      },
    );
    return _animeList(res.data);
  }

  Future<List<AnimeSummary>> searchAnime(
    String query, {
    int limit = 24,
    String? type,
    String? status,
    String? rating,
    String? genres,
  }) async {
    if (isDemo) {
      final q = query.toLowerCase();
      return DemoData.seasonalAnime
          .where((a) => a.title.toLowerCase().contains(q))
          .toList();
    }
    final params = <String, dynamic>{
      'q': query,
      'fields': _animeFields,
      'limit': limit,
    };
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (rating != null && rating.isNotEmpty) params['rating'] = rating;
    if (genres != null && genres.isNotEmpty) params['genres'] = genres;
    final res = await _client.dio.get('/anime', queryParameters: params);
    return _animeList(res.data);
  }

  Future<AnimeDetail> animeDetail(int id) async {
    if (isDemo) {
      final base = DemoData.seasonalAnime.firstWhere(
        (a) => a.id == id,
        orElse: () => DemoData.seasonalAnime.first,
      );
      return AnimeDetail(
        id: base.id,
        title: base.title,
        imageUrl: base.imageUrl,
        mean: base.mean,
        rank: base.rank,
        popularity: base.popularity,
        numEpisodes: base.numEpisodes,
        mediaType: base.mediaType,
        status: base.status,
        season: base.season,
        seasonYear: base.seasonYear,
        genres: base.genres,
        synopsis: base.synopsis,
        broadcastDay: base.broadcastDay,
        broadcastTime: base.broadcastTime,
        studio: base.studio,
        numListUsers: base.numListUsers,
        related: [
          for (final a
              in DemoData.seasonalAnime.where((a) => a.id != id).take(6))
            RelatedEntry(anime: a),
        ],
        recommendations:
            DemoData.seasonalAnime.where((a) => a.id != id).take(6).toList(),
      );
    }
    final res = await _client.dio.get(
      '/anime/$id',
      queryParameters: {'fields': _animeDetailFields},
    );
    return AnimeDetail.fromMal(res.data as Map<String, dynamic>);
  }

  // ---------- manga ----------

  Future<MangaDetail> mangaDetail(int id) async {
    if (isDemo) {
      final base = DemoData.topManga.firstWhere(
        (m) => m.id == id,
        orElse: () => DemoData.topManga.first,
      );
      return MangaDetail(
        id: base.id,
        title: base.title,
        imageUrl: base.imageUrl,
        mean: base.mean,
        rank: base.rank,
        popularity: base.popularity,
        numChapters: base.numChapters,
        numVolumes: base.numVolumes,
        mediaType: base.mediaType,
        status: base.status,
        genres: base.genres,
        synopsis: base.synopsis,
        numListUsers: base.numListUsers,
        authors: const ['Demo Author'],
        related: [
          for (final m in DemoData.topManga.where((m) => m.id != id).take(6))
            MangaRelatedEntry(manga: m),
        ],
        recommendations:
            DemoData.topManga.where((m) => m.id != id).take(6).toList(),
      );
    }
    final res = await _client.dio.get(
      '/manga/$id',
      queryParameters: {'fields': _mangaDetailFields},
    );
    return MangaDetail.fromMal(res.data as Map<String, dynamic>);
  }

  Future<List<MangaSummary>> topManga({int limit = 24}) async {
    if (isDemo) return DemoData.topManga;
    final res = await _client.dio.get(
      '/manga/ranking',
      queryParameters: {
        'ranking_type': 'all',
        'fields': _mangaFields,
        'limit': limit,
      },
    );
    return _mangaList(res.data);
  }

  Future<List<MangaSummary>> searchManga(
    String query, {
    int limit = 24,
    String? type,
    String? status,
    String? genres,
  }) async {
    if (isDemo) {
      final q = query.toLowerCase();
      return DemoData.topManga
          .where((m) => m.title.toLowerCase().contains(q))
          .toList();
    }
    final params = <String, dynamic>{
      'q': query,
      'fields': _mangaFields,
      'limit': limit,
    };
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (genres != null && genres.isNotEmpty) params['genres'] = genres;
    final res = await _client.dio.get('/manga', queryParameters: params);
    return _mangaList(res.data);
  }

  // ---------- user ----------

  Future<MalUser> myUser() async {
    if (isDemo) return DemoData.demoUser;
    final res = await _client.dio.get(
      '/users/@me',
      queryParameters: {'fields': 'anime_statistics,manga_statistics'},
    );
    return MalUser.fromMal(res.data as Map<String, dynamic>);
  }

  // ---------- helpers ----------

  List<AnimeSummary> _animeList(dynamic data) {
    final list = (data as Map<String, dynamic>)['data'];
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) AnimeSummary.fromMal(e)
    ];
  }

  List<MangaSummary> _mangaList(dynamic data) {
    final list = (data as Map<String, dynamic>)['data'];
    if (list is! List) return const [];
    return [
      for (final e in list)
        if (e is Map<String, dynamic>) MangaSummary.fromMal(e)
    ];
  }

  String _seasonOf(int month) {
    if (month <= 3) return 'winter';
    if (month <= 6) return 'spring';
    if (month <= 9) return 'summer';
    return 'fall';
  }
}
