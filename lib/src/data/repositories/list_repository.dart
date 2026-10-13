import 'package:dio/dio.dart';
import 'package:malclient/src/core/api/mal_api_client.dart';
import 'package:malclient/src/core/config.dart';
import 'package:malclient/src/core/demo/demo_data.dart';
import 'package:malclient/src/data/models/media.dart';

/// The user's own anime/manga lists: read + update.
///
/// Source: MAL API v2 when authenticated, otherwise an in-memory copy of
/// the demo data (edits apply to the session only).
class ListRepository {
  final MalApiClient _client;
  final bool _demo;

  /// In-memory demo lists (so the stepper / edit sheet work in demo mode).
  final List<AnimeListEntry> _demoAnime = List.of(DemoData.myAnimeList);
  final List<MangaListEntry> _demoManga = List.of(DemoData.myMangaList);

  ListRepository(this._client, {required this._demo});

  bool get isDemo => _demo || !hasRealClientId;

  Future<List<AnimeListEntry>> animeList({String? status}) async {
    if (isDemo) {
      if (status == null) return List.of(_demoAnime);
      return _demoAnime.where((e) => e.listStatus.status == status).toList();
    }
    final res = await _client.dio.get(
      '/users/@me/animelist',
      queryParameters: {
        'fields':
            'list_status,media_type,status,genres,mean,rank,popularity,num_list_users,num_scoring_users,rating,num_episodes,start_date',
        'limit': 200,
        if (status case final st) 'status': st,
        'sort': 'list_updated_at',
      },
    );
    final data = res.data;
    if (data is! Map<String, dynamic> || data['data'] is! List) {
      return const [];
    }
    return [
      for (final e in data['data'] as List)
        if (e is Map<String, dynamic>) AnimeListEntry.fromMal(e)
    ];
  }

  Future<List<MangaListEntry>> mangaList({String? status}) async {
    if (isDemo) {
      if (status == null) return List.of(_demoManga);
      return _demoManga.where((e) => e.listStatus.status == status).toList();
    }
    final res = await _client.dio.get(
      '/users/@me/mangalist',
      queryParameters: {
        'fields':
            'list_status,media_type,status,genres,mean,rank,popularity,num_list_users,num_scoring_users,num_chapters,num_volumes,start_date',
        'limit': 200,
        if (status case final st) 'status': st,
        'sort': 'list_updated_at',
      },
    );
    final data = res.data;
    if (data is! Map<String, dynamic> || data['data'] is! List) {
      return const [];
    }
    return [
      for (final e in data['data'] as List)
        if (e is Map<String, dynamic>) MangaListEntry.fromMal(e)
    ];
  }

  /// Creates or updates the user's status for an anime entry.
  Future<void> updateAnimeEntry(
    int id, {
    String? status,
    int? score,
    int? numWatchedEpisodes,
    bool? isRewatching,
    int? numTimesRewatched,
    int? rewatchValue,
    int? priority,
    String? comments,
    String? startDate,
    String? finishDate,
  }) async {
    if (isDemo) {
      final i = _demoAnime.indexWhere((e) => e.anime.id == id);
      if (i == -1) return;
      final cur = _demoAnime[i].listStatus;
      _demoAnime[i] = AnimeListEntry(
        anime: _demoAnime[i].anime,
        listStatus: cur.copyWith(
          status: status,
          score: score,
          progress: numWatchedEpisodes,
          isRewatching: isRewatching,
          timesRewatched: numTimesRewatched,
          rewatchValue: rewatchValue,
          priority: priority,
          comments: comments,
          startDate: startDate,
          finishDate: finishDate,
        ),
      );
      return;
    }
    final data = <String, dynamic>{};
    if (status != null) data['status'] = status;
    if (score != null) data['score'] = score;
    if (numWatchedEpisodes != null) {
      data['num_watched_episodes'] = numWatchedEpisodes;
    }
    if (isRewatching != null) data['is_rewatching'] = isRewatching;
    if (numTimesRewatched != null) {
      data['num_times_rewatched'] = numTimesRewatched;
    }
    if (rewatchValue != null) data['rewatch_value'] = rewatchValue;
    if (priority != null) data['priority'] = priority;
    if (comments != null) data['comments'] = comments;
    if (startDate != null) data['start_date'] = startDate;
    if (finishDate != null) data['finish_date'] = finishDate;
    await _client.dio.patch(
      '/anime/$id/my_list_status',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  /// Creates or updates the user's status for a manga entry.
  Future<void> updateMangaEntry(
    int id, {
    String? status,
    int? score,
    int? numReadChapters,
    int? numReadVolumes,
    bool? isRereading,
    int? numTimesReread,
    int? rereadValue,
    int? priority,
    String? comments,
    String? startDate,
    String? finishDate,
  }) async {
    if (isDemo) {
      final i = _demoManga.indexWhere((e) => e.manga.id == id);
      if (i == -1) return;
      final cur = _demoManga[i].listStatus;
      _demoManga[i] = MangaListEntry(
        manga: _demoManga[i].manga,
        listStatus: cur.copyWith(
          status: status,
          score: score,
          progress: numReadChapters,
          progressVolumes: numReadVolumes,
          isRewatching: isRereading,
          timesRewatched: numTimesReread,
          rewatchValue: rereadValue,
          priority: priority,
          comments: comments,
          startDate: startDate,
          finishDate: finishDate,
        ),
      );
      return;
    }
    final data = <String, dynamic>{};
    if (status != null) data['status'] = status;
    if (score != null) data['score'] = score;
    if (numReadChapters != null) data['num_chapters_read'] = numReadChapters;
    if (numReadVolumes != null) data['num_volumes_read'] = numReadVolumes;
    if (isRereading != null) data['is_rereading'] = isRereading;
    if (numTimesReread != null) data['num_times_reread'] = numTimesReread;
    if (rereadValue != null) data['reread_value'] = rereadValue;
    if (priority != null) data['priority'] = priority;
    if (comments != null) data['comments'] = comments;
    if (startDate != null) data['start_date'] = startDate;
    if (finishDate != null) data['finish_date'] = finishDate;
    await _client.dio.patch(
      '/manga/$id/my_list_status',
      data: data,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
  }

  Future<void> deleteAnimeEntry(int id) async {
    if (isDemo) {
      _demoAnime.removeWhere((e) => e.anime.id == id);
      return;
    }
    await _client.dio.delete('/anime/$id/my_list_status');
  }

  Future<void> deleteMangaEntry(int id) async {
    if (isDemo) {
      _demoManga.removeWhere((e) => e.manga.id == id);
      return;
    }
    await _client.dio.delete('/manga/$id/my_list_status');
  }
}
