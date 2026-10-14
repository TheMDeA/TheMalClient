import 'package:malclient/src/data/models/media.dart';

/// A normalized related/recommended title for the detail page.
class RelatedTitle {
  final ListKind kind;
  final int id;
  final String title;
  final String? imageUrl;
  final double? mean;
  final String? label;

  const RelatedTitle({
    required this.kind,
    required this.id,
    required this.title,
    this.imageUrl,
    this.mean,
    this.label,
  });
}

/// Normalized title details for the detail page, built from either an
/// [AnimeDetail] or a [MangaDetail]. Anime-only fields are null for manga
/// and vice versa; the UI branches on [isAnime].
class TitleDetail {
  final ListKind kind;
  final int id;
  final String title;
  final String? imageUrl;
  final double? mean;
  final int? rank;
  final int? popularity;
  final int? numListUsers;
  final String? mediaType;
  final String? status;
  final List<String> genres;
  final String? synopsis;
  final String? titleEn;
  final String? titleJa;
  final List<String> synonyms;
  final MyListStatus? myListStatus;
  final List<RelatedTitle> related;
  final List<RelatedTitle> recommendations;

  // Anime-only.
  final int? numEpisodes;
  final String? studio;
  final String? broadcastDay;
  final String? broadcastTime;
  final String? season;
  final int? seasonYear;
  final String? airedFrom;
  final String? airedTo;
  final int? avgEpisodeDuration;
  final String? rating;
  final String? source;

  // Manga-only.
  final int? numChapters;
  final int? numVolumes;
  final List<String> authors;
  final String? publishedFrom;
  final String? publishedTo;

  const TitleDetail({
    required this.kind,
    required this.id,
    required this.title,
    this.imageUrl,
    this.mean,
    this.rank,
    this.popularity,
    this.numListUsers,
    this.mediaType,
    this.status,
    this.genres = const [],
    this.synopsis,
    this.titleEn,
    this.titleJa,
    this.synonyms = const [],
    this.myListStatus,
    this.related = const [],
    this.recommendations = const [],
    this.numEpisodes,
    this.studio,
    this.broadcastDay,
    this.broadcastTime,
    this.season,
    this.seasonYear,
    this.airedFrom,
    this.airedTo,
    this.avgEpisodeDuration,
    this.rating,
    this.source,
    this.numChapters,
    this.numVolumes,
    this.authors = const [],
    this.publishedFrom,
    this.publishedTo,
  });

  bool get isAnime => kind == ListKind.anime;

  /// Total episodes/chapters, whichever applies.
  int? get totalCount => isAnime ? numEpisodes : numChapters;

  /// Unit label for progress ("ep"/"ch").
  String get unit => isAnime ? 'ep' : 'ch';

  factory TitleDetail.fromAnime(AnimeDetail d) {
    return TitleDetail(
      kind: ListKind.anime,
      id: d.id,
      title: d.title,
      imageUrl: d.imageUrl,
      mean: d.mean,
      rank: d.rank,
      popularity: d.popularity,
      numListUsers: d.numListUsers,
      mediaType: d.mediaType,
      status: d.status,
      genres: d.genres,
      synopsis: d.synopsis,
      titleEn: d.titleEn,
      titleJa: d.titleJa,
      synonyms: d.synonyms,
      myListStatus: d.myListStatus,
      related: [
        for (final r in d.related)
          RelatedTitle(
            kind: ListKind.anime,
            id: r.anime.id,
            title: r.anime.title,
            imageUrl: r.anime.imageUrl,
            mean: r.anime.mean,
            label: r.relationLabel,
          ),
      ],
      recommendations: [
        for (final a in d.recommendations)
          RelatedTitle(
            kind: ListKind.anime,
            id: a.id,
            title: a.title,
            imageUrl: a.imageUrl,
            mean: a.mean,
          ),
      ],
      numEpisodes: d.numEpisodes,
      studio: d.studio,
      broadcastDay: d.broadcastDay,
      broadcastTime: d.broadcastTime,
      season: d.season,
      seasonYear: d.seasonYear,
      airedFrom: d.airedFrom,
      airedTo: d.airedTo,
      avgEpisodeDuration: d.avgEpisodeDuration,
      rating: d.rating,
      source: d.source,
    );
  }

  factory TitleDetail.fromManga(MangaDetail d) {
    return TitleDetail(
      kind: ListKind.manga,
      id: d.id,
      title: d.title,
      imageUrl: d.imageUrl,
      mean: d.mean,
      rank: d.rank,
      popularity: d.popularity,
      numListUsers: d.numListUsers,
      mediaType: d.mediaType,
      status: d.status,
      genres: d.genres,
      synopsis: d.synopsis,
      titleEn: d.titleEn,
      titleJa: d.titleJa,
      synonyms: d.synonyms,
      myListStatus: d.myListStatus,
      related: [
        for (final r in d.related)
          RelatedTitle(
            kind: ListKind.manga,
            id: r.manga.id,
            title: r.manga.title,
            imageUrl: r.manga.imageUrl,
            mean: r.manga.mean,
            label: r.relationLabel,
          ),
      ],
      recommendations: [
        for (final m in d.recommendations)
          RelatedTitle(
            kind: ListKind.manga,
            id: m.id,
            title: m.title,
            imageUrl: m.imageUrl,
            mean: m.mean,
          ),
      ],
      numChapters: d.numChapters,
      numVolumes: d.numVolumes,
      authors: d.authors,
      publishedFrom: d.startDate,
      publishedTo: d.endDate,
    );
  }
}
