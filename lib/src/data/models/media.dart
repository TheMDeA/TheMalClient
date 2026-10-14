// Shared media models. `AnimeSummary` / `MangaSummary` are the list-level
// shapes used across rails, grids and rows; `AnimeDetail` /
// `MangaDetail` extend them for the detail screen.

enum ListKind { anime, manga }

/// MAL anime list statuses.
class AnimeListStatuses {
  static const watching = 'watching';
  static const completed = 'completed';
  static const onHold = 'on_hold';
  static const dropped = 'dropped';
  static const planToWatch = 'plan_to_watch';

  static const all = [watching, completed, onHold, dropped, planToWatch];

  static String label(String s) => switch (s) {
        watching => 'Watching',
        completed => 'Completed',
        onHold => 'On Hold',
        dropped => 'Dropped',
        planToWatch => 'Plan to Watch',
        _ => s,
      };
}

/// MAL manga list statuses.
class MangaListStatuses {
  static const reading = 'reading';
  static const completed = 'completed';
  static const onHold = 'on_hold';
  static const dropped = 'dropped';
  static const planToRead = 'plan_to_read';

  static const all = [reading, completed, onHold, dropped, planToRead];

  static String label(String s) => switch (s) {
        reading => 'Reading',
        completed => 'Completed',
        onHold => 'On Hold',
        dropped => 'Dropped',
        planToRead => 'Plan to Read',
        _ => s,
      };
}

String? _str(Map<String, dynamic> j, String k) => j[k] as String?;

String? _pic(Map<String, dynamic> j) {
  final pic = j['main_picture'];
  if (pic is Map<String, dynamic>) {
    return pic['large'] as String? ?? pic['medium'] as String?;
  }
  return null;
}

List<String> _genres(Map<String, dynamic> j) {
  final g = j['genres'];
  if (g is List) {
    return [
      for (final e in g)
        if (e is Map<String, dynamic> && e['name'] is String) e['name'] as String
    ];
  }
  return const [];
}

class AnimeSummary {
  final int id;
  final String title;
  final String? imageUrl;
  final double? mean;
  final int? rank;
  final int? popularity;
  final int? numEpisodes;
  final String? mediaType;
  final String? status; // currently_airing | finished_airing | not_yet_aired
  final String? season;
  final int? seasonYear;
  final List<String> genres;
  final String? synopsis;
  final String? broadcastDay; // e.g. "saturdays"
  final String? broadcastTime; // e.g. "23:45"
  final String? studio;
  final int? numListUsers;
  final int? numScoringUsers;
  final String? rating; // g | pg | pg_13 | r | r_plus | rx
  final String? airedFrom; // YYYY-MM-DD (anime's start_date)
  final String? airedTo; // YYYY-MM-DD (anime's end_date)
  final int? avgEpisodeDuration; // seconds (average_episode_duration)
  final List<String> synonyms; // alternative_titles.synonyms
  final String? titleEn; // alternative_titles.en
  final String? titleJa; // alternative_titles.ja

  const AnimeSummary({
    required this.id,
    required this.title,
    this.imageUrl,
    this.mean,
    this.rank,
    this.popularity,
    this.numEpisodes,
    this.mediaType,
    this.status,
    this.season,
    this.seasonYear,
    this.genres = const [],
    this.synopsis,
    this.broadcastDay,
    this.broadcastTime,
    this.studio,
    this.numListUsers,
    this.numScoringUsers,
    this.rating,
    this.airedFrom,
    this.airedTo,
    this.avgEpisodeDuration,
    this.synonyms = const [],
    this.titleEn,
    this.titleJa,
  });

  bool get isAiring => status == 'currently_airing';

  factory AnimeSummary.fromMal(Map<String, dynamic> json) {
    final node = json['node'] is Map<String, dynamic>
        ? json['node'] as Map<String, dynamic>
        : json;
    final b = node['broadcast'];
    final broadcast = b is Map<String, dynamic> ? b : null;
    final studios = node['studios'];
    String? studio;
    if (studios is List && studios.isNotEmpty && studios.first is Map) {
      studio = (studios.first as Map)['name'] as String?;
    }
    final season = node['start_season'];
    return AnimeSummary(
      id: (node['id'] as num).toInt(),
      title: (node['title'] ?? '') as String,
      imageUrl: _pic(node),
      mean: (node['mean'] as num?)?.toDouble(),
      rank: (node['rank'] as num?)?.toInt(),
      popularity: (node['popularity'] as num?)?.toInt(),
      numEpisodes: (node['num_episodes'] as num?)?.toInt(),
      mediaType: _str(node, 'media_type'),
      status: _str(node, 'status'),
      season: season is Map<String, dynamic> ? season['season'] as String? : null,
      seasonYear:
          season is Map<String, dynamic> ? (season['year'] as num?)?.toInt() : null,
      genres: _genres(node),
      synopsis: _str(node, 'synopsis'),
      broadcastDay: broadcast?['day_of_the_week'] as String?,
      broadcastTime: broadcast?['start_time'] as String?,
      studio: studio,
      numListUsers: (node['num_list_users'] as num?)?.toInt(),
      numScoringUsers: (node['num_scoring_users'] as num?)?.toInt(),
      rating: _str(node, 'rating'),
      airedFrom: _str(node, 'start_date'),
      airedTo: _str(node, 'end_date'),
      avgEpisodeDuration:
          (node['average_episode_duration'] as num?)?.toInt(),
      synonyms: _altTitles(node).$1,
      titleEn: _altTitles(node).$2,
      titleJa: _altTitles(node).$3,
    );
  }

  /// (synonyms, en, ja) from `alternative_titles`.
  static (List<String>, String?, String?) _altTitles(
      Map<String, dynamic> node) {
    final alt = node['alternative_titles'];
    if (alt is! Map<String, dynamic>) return (const [], null, null);
    final syn = alt['synonyms'];
    return (
      [
        if (syn is List)
          for (final s in syn)
            if (s is String && s.isNotEmpty) s
      ],
      (alt['en'] as String?)?.isNotEmpty == true
          ? alt['en'] as String?
          : null,
      (alt['ja'] as String?)?.isNotEmpty == true
          ? alt['ja'] as String?
          : null,
    );
  }
}

class MangaSummary {
  final int id;
  final String title;
  final String? imageUrl;
  final double? mean;
  final int? rank;
  final int? popularity;
  final int? numChapters;
  final int? numVolumes;
  final String? mediaType;
  final String? status;
  final List<String> genres;
  final String? synopsis;
  final int? numListUsers;
  final int? numScoringUsers;

  const MangaSummary({
    required this.id,
    required this.title,
    this.imageUrl,
    this.mean,
    this.rank,
    this.popularity,
    this.numChapters,
    this.numVolumes,
    this.mediaType,
    this.status,
    this.genres = const [],
    this.synopsis,
    this.numListUsers,
    this.numScoringUsers,
  });

  factory MangaSummary.fromMal(Map<String, dynamic> json) {
    final node = json['node'] is Map<String, dynamic>
        ? json['node'] as Map<String, dynamic>
        : json;
    return MangaSummary(
      id: (node['id'] as num).toInt(),
      title: (node['title'] ?? '') as String,
      imageUrl: _pic(node),
      mean: (node['mean'] as num?)?.toDouble(),
      rank: (node['rank'] as num?)?.toInt(),
      popularity: (node['popularity'] as num?)?.toInt(),
      numChapters: (node['num_chapters'] as num?)?.toInt(),
      numVolumes: (node['num_volumes'] as num?)?.toInt(),
      mediaType: _str(node, 'media_type'),
      status: _str(node, 'status'),
      genres: _genres(node),
      synopsis: _str(node, 'synopsis'),
      numListUsers: (node['num_list_users'] as num?)?.toInt(),
      numScoringUsers: (node['num_scoring_users'] as num?)?.toInt(),
    );
  }
}

/// The user's own list status for one entry (MAL `my_list_status`).
class MyListStatus {
  final String status;
  final int score; // 0..10
  final int progress; // episodes watched / chapters read
  final int? progressVolumes; // manga volumes read
  final bool isRewatching; // is_rereading for manga
  final int timesRewatched;
  final int rewatchValue; // 0..5 (0 = unset)
  final String? startDate; // YYYY-MM-DD
  final String? finishDate; // YYYY-MM-DD
  final int priority; // 0 = low, 1 = medium, 2 = high
  final String comments;
  final String? updatedAt; // ISO 8601 from MAL

  const MyListStatus({
    required this.status,
    this.score = 0,
    this.progress = 0,
    this.progressVolumes,
    this.isRewatching = false,
    this.timesRewatched = 0,
    this.rewatchValue = 0,
    this.startDate,
    this.finishDate,
    this.priority = 0,
    this.comments = '',
    this.updatedAt,
  });

  factory MyListStatus.fromMal(Map<String, dynamic> json, ListKind kind) {
    final isAnime = kind == ListKind.anime;
    return MyListStatus(
      status: (json['status'] ?? '') as String,
      score: (json['score'] as num?)?.toInt() ?? 0,
      progress: ((isAnime
                  ? json['num_episodes_watched']
                  : json['num_chapters_read']) as num?)
              ?.toInt() ??
          0,
      progressVolumes: (json['num_volumes_read'] as num?)?.toInt(),
      isRewatching: (isAnime ? json['is_rewatching'] : json['is_rereading'])
              as bool? ??
          false,
      timesRewatched: ((isAnime
                  ? json['num_times_rewatched']
                  : json['num_times_reread']) as num?)
              ?.toInt() ??
          0,
      rewatchValue: ((isAnime ? json['rewatch_value'] : json['reread_value'])
              as num?)
              ?.toInt() ??
          0,
      startDate: json['start_date'] as String?,
      finishDate: json['finish_date'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      comments: (json['comments'] as String?) ?? '',
      updatedAt: json['updated_at'] as String?,
    );
  }

  MyListStatus copyWith({
    String? status,
    int? score,
    int? progress,
    int? progressVolumes,
    bool? isRewatching,
    int? timesRewatched,
    int? rewatchValue,
    String? startDate,
    String? finishDate,
    int? priority,
    String? comments,
    String? updatedAt,
  }) =>
      MyListStatus(
        status: status ?? this.status,
        score: score ?? this.score,
        progress: progress ?? this.progress,
        progressVolumes: progressVolumes ?? this.progressVolumes,
        isRewatching: isRewatching ?? this.isRewatching,
        timesRewatched: timesRewatched ?? this.timesRewatched,
        rewatchValue: rewatchValue ?? this.rewatchValue,
        startDate: startDate ?? this.startDate,
        finishDate: finishDate ?? this.finishDate,
        priority: priority ?? this.priority,
        comments: comments ?? this.comments,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class AnimeListEntry {
  final AnimeSummary anime;
  final MyListStatus listStatus;

  const AnimeListEntry({required this.anime, required this.listStatus});

  factory AnimeListEntry.fromMal(Map<String, dynamic> json) => AnimeListEntry(
        anime: AnimeSummary.fromMal(json),
        listStatus: MyListStatus.fromMal(
            (json['list_status'] as Map<String, dynamic>?) ?? const {},
            ListKind.anime),
      );
}

class MangaListEntry {
  final MangaSummary manga;
  final MyListStatus listStatus;

  const MangaListEntry({required this.manga, required this.listStatus});

  factory MangaListEntry.fromMal(Map<String, dynamic> json) => MangaListEntry(
        manga: MangaSummary.fromMal(json),
        listStatus: MyListStatus.fromMal(
            (json['list_status'] as Map<String, dynamic>?) ?? const {},
            ListKind.manga),
      );
}

/// A related anime/manga with its relation type from the MAL API
/// (e.g. "Sequel", "Prequel", "Side Story").
class RelatedEntry {
  final AnimeSummary anime;
  final String? relationLabel;

  const RelatedEntry({required this.anime, this.relationLabel});
}

/// Fallback formatter for raw `relation_type` values like "side_story".
/// Prefers the API's `relation_type_formatted` when available.
String? _prettyRelation(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return raw
      .split('_')
      .map((w) =>
          w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

class AnimeDetail extends AnimeSummary {
  final List<RelatedEntry> related;
  final List<AnimeSummary> recommendations;
  final String? source;
  final MyListStatus? myListStatus;

  const AnimeDetail({
    required super.id,
    required super.title,
    super.imageUrl,
    super.mean,
    super.rank,
    super.popularity,
    super.numEpisodes,
    super.mediaType,
    super.status,
    super.season,
    super.seasonYear,
    super.genres,
    super.synopsis,
    super.broadcastDay,
    super.broadcastTime,
    super.studio,
    super.numListUsers,
    super.numScoringUsers,
    super.rating,
    super.airedFrom,
    super.airedTo,
    super.avgEpisodeDuration,
    super.titleEn,
    super.titleJa,
    super.synonyms,
    this.related = const [],
    this.recommendations = const [],
    this.source,
    this.myListStatus,
  });

  factory AnimeDetail.fromMal(Map<String, dynamic> json) {
    final base = AnimeSummary.fromMal(json);
    List<RelatedEntry> rel(String key) {
      final l = json[key];
      if (l is! List) return const [];
      return [
        for (final e in l)
          if (e is Map<String, dynamic> && e['node'] is Map<String, dynamic>)
            RelatedEntry(
              anime: AnimeSummary.fromMal(
                  e['node'] as Map<String, dynamic>),
              relationLabel:
                  (e['relation_type_formatted'] as String?) ??
                      _prettyRelation(e['relation_type'] as String?),
            )
      ];
    }

    /// Recommendations have no relation type — plain summaries.
    List<AnimeSummary> recs(dynamic l) {
      if (l is! List) return const [];
      return [
        for (final e in l)
          if (e is Map<String, dynamic> && e['node'] is Map<String, dynamic>)
            AnimeSummary.fromMal(e['node'] as Map<String, dynamic>)
      ];
    }

    final mls = json['my_list_status'];
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
      broadcastTime: base.broadcastDay != null ? base.broadcastTime : null,
      studio: base.studio,
      numListUsers: base.numListUsers,
      rating: _str(json, 'rating'),
      airedFrom: base.airedFrom,
      airedTo: base.airedTo,
      avgEpisodeDuration: base.avgEpisodeDuration,
      titleEn: base.titleEn,
      titleJa: base.titleJa,
      synonyms: base.synonyms,
      related: rel('related_anime'),
      recommendations: recs(json['recommendations']),
      source: _str(json, 'source'),
      myListStatus: mls is Map<String, dynamic>
          ? MyListStatus.fromMal(mls, ListKind.anime)
          : null,
    );
  }
}

/// Full manga details (MAL `/manga/{id}`).
class MangaDetail extends MangaSummary {
  final List<String> authors;
  final List<MangaRelatedEntry> related;
  final List<MangaSummary> recommendations;
  final List<String> synonyms; // alternative_titles.synonyms
  final String? titleEn; // alternative_titles.en
  final String? titleJa; // alternative_titles.ja
  final String? startDate; // YYYY-MM-DD
  final String? endDate; // YYYY-MM-DD
  final MyListStatus? myListStatus;

  const MangaDetail({
    required super.id,
    required super.title,
    super.imageUrl,
    super.mean,
    super.rank,
    super.popularity,
    super.numChapters,
    super.numVolumes,
    super.mediaType,
    super.status,
    super.genres,
    super.synopsis,
    super.numListUsers,
    super.numScoringUsers,
    this.authors = const [],
    this.related = const [],
    this.recommendations = const [],
    this.synonyms = const [],
    this.titleEn,
    this.titleJa,
    this.startDate,
    this.endDate,
    this.myListStatus,
  });

  factory MangaDetail.fromMal(Map<String, dynamic> json) {
    final base = MangaSummary.fromMal(json);
    String authorName(dynamic a) {
      if (a is! Map<String, dynamic>) return '';
      final node = a['node'];
      if (node is! Map<String, dynamic>) return '';
      final first = _str(node, 'first_name') ?? '';
      final last = _str(node, 'last_name') ?? '';
      return '$first $last'.trim();
    }

    List<MangaRelatedEntry> rel(dynamic l) {
      if (l is! List) return [];
      return [
        for (final e in l)
          if (e is Map<String, dynamic> && e['node'] is Map<String, dynamic>)
            MangaRelatedEntry(
              manga: MangaSummary.fromMal(e['node'] as Map<String, dynamic>),
              relationLabel:
                  _prettyRelation(e['relation_type_formatted'] as String?) ??
                      _prettyRelation(e['relation_type'] as String?),
            ),
      ];
    }
    List<MangaSummary> recs(dynamic l) {
      if (l is! List) return [];
      return [
        for (final e in l)
          if (e is Map<String, dynamic> && e['node'] is Map<String, dynamic>)
            MangaSummary.fromMal(e['node'] as Map<String, dynamic>),
      ];
    }

    final alt = json['alternative_titles'];
    final synonyms = <String>[];
    String? titleEn, titleJa;
    if (alt is Map<String, dynamic>) {
      final s = alt['synonyms'];
      if (s is List) {
        synonyms.addAll([for (final x in s) if (x is String) x]);
      }
      titleEn = _str(alt, 'en');
      titleJa = _str(alt, 'ja');
    }
    final mls = json['my_list_status'];
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
      numScoringUsers: base.numScoringUsers,
      authors: [
        for (final a in (json['authors'] as List? ?? []))
          authorName(a),
      ].where((s) => s.isNotEmpty).toList(),
      related: rel(json['related_manga']),
      recommendations: recs(json['recommendations']),
      synonyms: synonyms,
      titleEn: titleEn,
      titleJa: titleJa,
      startDate: _str(json, 'start_date'),
      endDate: _str(json, 'end_date'),
      myListStatus: mls is Map<String, dynamic>
          ? MyListStatus.fromMal(mls, ListKind.manga)
          : null,
    );
  }
}

class MangaRelatedEntry {
  final MangaSummary manga;
  final String? relationLabel;

  const MangaRelatedEntry({required this.manga, this.relationLabel});
}

/// Jikan-sourced review (MAL API v2 has no reviews endpoint).
class Review {
  final String author;
  final String? authorImageUrl;
  final int score;
  final String text;
  final String date;

  const Review({
    required this.author,
    this.authorImageUrl,
    required this.score,
    required this.text,
    required this.date,
  });

  factory Review.fromJikan(Map<String, dynamic> json) {
    final user = json['user'];
    return Review(
      author: user is Map<String, dynamic>
          ? (user['username'] ?? 'Unknown') as String
          : 'Unknown',
      authorImageUrl: user is Map<String, dynamic>
          ? (user['images']?['jpg']?['image_url']) as String?
          : null,
      score: (json['score'] as num?)?.toInt() ?? 0,
      text: (json['review'] ?? '') as String,
      date: (json['date'] ?? '') as String,
    );
  }
}

/// Jikan-sourced news article.
class NewsItem {
  final String title;
  final String? imageUrl;
  final String excerpt;
  final String date;
  final String url;
  final String? author;

  const NewsItem({
    required this.title,
    this.imageUrl,
    required this.excerpt,
    required this.date,
    required this.url,
    this.author,
  });

  factory NewsItem.fromJikan(Map<String, dynamic> json) {
    final images = json['images'];
    return NewsItem(
      title: (json['title'] ?? '') as String,
      imageUrl: images is Map<String, dynamic>
          ? (images['jpg']?['image_url']) as String?
          : null,
      excerpt: (json['excerpt'] ?? '') as String,
      date: (json['date'] ?? '') as String,
      url: (json['url'] ?? '') as String,
      author: (json['author_username'] ?? json['author']) as String?,
    );
  }
}

class MalUserStats {
  final double daysWatched;
  final double meanScore;
  final int totalEntries;

  const MalUserStats({
    this.daysWatched = 0,
    this.meanScore = 0,
    this.totalEntries = 0,
  });

  factory MalUserStats.fromMal(Map<String, dynamic> json) {
    // MAL has no total-entries field: sum the num_items_* buckets.
    var totalEntries = 0;
    for (final e in json.entries) {
      if (e.key.startsWith('num_items_')) {
        totalEntries += (e.value as num?)?.toInt() ?? 0;
      }
    }
    // Field names are num_days_watched (anime) / num_days_read (manga).
    final days = (json['num_days_watched'] as num?) ??
        (json['num_days_read'] as num?) ??
        (json['num_days'] as num?);
    return MalUserStats(
      daysWatched: days?.toDouble() ?? 0,
      meanScore: (json['mean_score'] as num?)?.toDouble() ?? 0,
      totalEntries: totalEntries,
    );
  }
}

class MalUser {
  final String name;
  final String? pictureUrl;
  final MalUserStats animeStats;
  final MalUserStats mangaStats;

  const MalUser({
    required this.name,
    this.pictureUrl,
    this.animeStats = const MalUserStats(),
    this.mangaStats = const MalUserStats(),
  });

  factory MalUser.fromMal(Map<String, dynamic> json) {
    // MAL returns `picture` as a plain URL string, not a map.
    final pic = json['picture'];
    return MalUser(
      name: (json['name'] ?? '') as String,
      pictureUrl: pic is String ? pic : null,
      animeStats: json['anime_statistics'] is Map<String, dynamic>
          ? MalUserStats.fromMal(json['anime_statistics'] as Map<String, dynamic>)
          : const MalUserStats(),
      mangaStats: json['manga_statistics'] is Map<String, dynamic>
          ? MalUserStats.fromMal(json['manga_statistics'] as Map<String, dynamic>)
          : const MalUserStats(),
    );
  }
}

/// A character with their voice actors (Jikan `/anime/{id}/characters`).
class AnimeCharacter {
  final int malId;
  final String name;
  final String? imageUrl;
  final String role; // "Main" or "Supporting"
  final List<String> voiceActors; // "Name (Language)"

  const AnimeCharacter({
    required this.malId,
    required this.name,
    this.imageUrl,
    this.role = '',
    this.voiceActors = const [],
  });

  factory AnimeCharacter.fromJikan(Map<String, dynamic> json) {
    final char = json['character'];
    final vas = json['voice_actors'];
    return AnimeCharacter(
      malId: (char?['mal_id'] as num?)?.toInt() ?? 0,
      name: (char?['name'] ?? '') as String,
      imageUrl: char?['images']?['jpg']?['image_url'] as String?,
      role: (json['role'] ?? '') as String,
      voiceActors: [
        if (vas is List)
          for (final va in vas)
            if (va is Map<String, dynamic>)
              '${va['person']?['name'] ?? ''} (${va['language'] ?? ''})',
      ],
    );
  }
}

/// A staff member (Jikan `/anime/{id}/staff`).
class AnimeStaff {
  final int malId;
  final String name;
  final String? imageUrl;
  final List<String> positions;

  const AnimeStaff({
    required this.malId,
    required this.name,
    this.imageUrl,
    this.positions = const [],
  });

  factory AnimeStaff.fromJikan(Map<String, dynamic> json) {
    final person = json['person'];
    final pos = json['positions'];
    return AnimeStaff(
      malId: (person?['mal_id'] as num?)?.toInt() ?? 0,
      name: (person?['name'] ?? '') as String,
      imageUrl: person?['images']?['jpg']?['image_url'] as String?,
      positions: [
        if (pos is List) for (final p in pos) (p ?? '').toString(),
      ],
    );
  }
}

/// Aggregate statistics (Jikan `/anime/{id}/statistics`).
class AnimeStatistics {
  final int watching;
  final int completed;
  final int onHold;
  final int dropped;
  final int planToWatch;
  final int total;
  final Map<int, double> scorePercent; // score 1..10 -> %

  const AnimeStatistics({
    this.watching = 0,
    this.completed = 0,
    this.onHold = 0,
    this.dropped = 0,
    this.planToWatch = 0,
    this.total = 0,
    this.scorePercent = const {},
  });

  factory AnimeStatistics.fromJikan(Map<String, dynamic> json) {
    final scores = <int, double>{};
    final s = json['scores'];
    if (s is Map<String, dynamic>) {
      for (final e in s.entries) {
        final score = int.tryParse(e.key);
        final pct = (e.value?['percentage'] as num?)?.toDouble();
        if (score != null && pct != null) scores[score] = pct;
      }
    }
    return AnimeStatistics(
      watching: (json['watching'] as num?)?.toInt() ??
          (json['reading'] as num?)?.toInt() ??
          0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      onHold: (json['on_hold'] as num?)?.toInt() ?? 0,
      dropped: (json['dropped'] as num?)?.toInt() ?? 0,
      planToWatch: (json['plan_to_watch'] as num?)?.toInt() ??
          (json['plan_to_read'] as num?)?.toInt() ??
          0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      scorePercent: scores,
    );
  }
}

/// Extracts `images.jpg.image_url` from a Jikan-style node, or null.
String? _jpgImage(dynamic node) {
  if (node is! Map) return null;
  final images = node['images'];
  if (images is! Map) return null;
  final jpg = images['jpg'];
  if (jpg is! Map) return null;
  return jpg['image_url'] as String?;
}

/// Full character details (Tenrai `/characters/{id}`).
class CharacterDetail {
  final int malId;
  final String name;
  final String? nameKanji;
  final String? imageUrl;
  final List<String> nicknames;
  final int favorites;
  final String? about;

  const CharacterDetail({
    required this.malId,
    required this.name,
    this.nameKanji,
    this.imageUrl,
    this.nicknames = const [],
    this.favorites = 0,
    this.about,
  });

  factory CharacterDetail.fromJikan(Map<String, dynamic> json) {
    return CharacterDetail(
      malId: (json['mal_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      nameKanji: json['name_kanji'] as String?,
      imageUrl: _jpgImage(json),
      nicknames: [
        if (json['nicknames'] is List)
          for (final n in (json['nicknames'] as List))
            if (n is String && n.isNotEmpty) n,
      ],
      favorites: (json['favorites'] as num?)?.toInt() ?? 0,
      about: json['about'] as String?,
    );
  }
}

/// An anime a character appears in (Tenrai `/characters/{id}/anime`).
class CharacterAnime {
  final int malId;
  final String title;
  final String? imageUrl;
  final String role; // "Main" or "Supporting"

  const CharacterAnime({
    required this.malId,
    required this.title,
    this.imageUrl,
    this.role = '',
  });

  factory CharacterAnime.fromJikan(Map<String, dynamic> json) {
    final anime = json['anime'];
    return CharacterAnime(
      malId: (anime?['mal_id'] as num?)?.toInt() ?? 0,
      title: (anime?['title'] ?? '') as String,
      imageUrl: _jpgImage(anime),
      role: (json['role'] ?? '') as String,
    );
  }
}

/// Full staff/person details (Tenrai `/people/{id}`).
class StaffDetail {
  final int malId;
  final String name;
  final String? givenName;
  final String? familyName;
  final String? imageUrl;
  final List<String> alternateNames;
  final String? birthday; // ISO date
  final int favorites;
  final String? about;

  const StaffDetail({
    required this.malId,
    required this.name,
    this.givenName,
    this.familyName,
    this.imageUrl,
    this.alternateNames = const [],
    this.birthday,
    this.favorites = 0,
    this.about,
  });

  factory StaffDetail.fromJikan(Map<String, dynamic> json) {
    return StaffDetail(
      malId: (json['mal_id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      givenName: json['given_name'] as String?,
      familyName: json['family_name'] as String?,
      imageUrl: _jpgImage(json),
      alternateNames: [
        if (json['alternate_names'] is List)
          for (final n in (json['alternate_names'] as List))
            if (n is String && n.isNotEmpty) n,
      ],
      birthday: (json['birthday'] as String?)?.substring(0, 10),
      favorites: (json['favorites'] as num?)?.toInt() ?? 0,
      about: json['about'] as String?,
    );
  }
}

/// An anime a staff member worked on (Tenrai `/people/{id}/anime`).
class StaffAnime {
  final int malId;
  final String title;
  final String? imageUrl;
  final String position;

  const StaffAnime({
    required this.malId,
    required this.title,
    this.imageUrl,
    this.position = '',
  });

  factory StaffAnime.fromJikan(Map<String, dynamic> json) {
    final anime = json['anime'];
    return StaffAnime(
      malId: (anime?['mal_id'] as num?)?.toInt() ?? 0,
      title: (anime?['title'] ?? '') as String,
      imageUrl: _jpgImage(anime),
      position: (json['position'] ?? '') as String,
    );
  }
}
