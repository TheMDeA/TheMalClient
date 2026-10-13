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
      related: rel('related_anime'),
      recommendations: recs(json['recommendations']),
      source: _str(json, 'source'),
      rating: _str(json, 'rating'),
      myListStatus: mls is Map<String, dynamic>
          ? MyListStatus.fromMal(mls, ListKind.anime)
          : null,
    );
  }
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

  factory MalUserStats.fromMal(Map<String, dynamic> json) => MalUserStats(
        daysWatched: (json['days_watched'] as num?)?.toDouble() ?? 0,
        meanScore: (json['mean_score'] as num?)?.toDouble() ?? 0,
        totalEntries: (json['total_entries'] as num?)?.toInt() ?? 0,
      );
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
    final pic = json['picture'];
    return MalUser(
      name: (json['name'] ?? '') as String,
      pictureUrl: pic is Map<String, dynamic> ? pic['large'] as String? : null,
      animeStats: json['anime_statistics'] is Map<String, dynamic>
          ? MalUserStats.fromMal(json['anime_statistics'] as Map<String, dynamic>)
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
      watching: (json['watching'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      onHold: (json['on_hold'] as num?)?.toInt() ?? 0,
      dropped: (json['dropped'] as num?)?.toInt() ?? 0,
      planToWatch: (json['plan_to_watch'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      scorePercent: scores,
    );
  }
}
