import 'package:malclient/src/data/models/media.dart';

/// Bundled sample data used when the app runs in demo mode
/// (no MAL Client ID configured, or "Continue in demo mode" tapped).
/// Image URLs point at MAL's public CDN; every image widget has a
/// gradient fallback so a stale URL degrades gracefully.
class DemoData {
  static const _cdn = 'https://cdn.myanimelist.net/images/anime';

  static List<AnimeSummary> get seasonalAnime => [
        _a(52991, 'Sousou no Frieren', '$_cdn/1016/135109.jpg',
            mean: 9.14, rank: 1, numEpisodes: 28, status: 'currently_airing',
            genres: ['Adventure', 'Drama', 'Fantasy'],
            studio: 'Madhouse', day: 'fridays', time: '23:00'),
        _a(21, 'One Piece', '$_cdn/6/73245.jpg',
            mean: 8.71, rank: 92, numEpisodes: 0, status: 'currently_airing',
            genres: ['Action', 'Adventure', 'Fantasy'],
            studio: 'Toei Animation', day: 'sundays', time: '09:30'),
        _a(51009, 'Jujutsu Kaisen 2nd Season', '$_cdn/1792/138022.jpg',
            mean: 8.83, rank: 24, numEpisodes: 23, status: 'finished_airing',
            genres: ['Action', 'Fantasy'], studio: 'MAPPA'),
        _a(52034, 'Oshi no Ko', '$_cdn/1812/134736.jpg',
            mean: 8.70, rank: 47, numEpisodes: 11, status: 'finished_airing',
            genres: ['Drama', 'Supernatural'], studio: 'Doga Kobo'),
        _a(51178, 'Chainsaw Man', '$_cdn/1806/126216.jpg',
            mean: 8.53, rank: 110, numEpisodes: 12, status: 'finished_airing',
            genres: ['Action', 'Fantasy'], studio: 'MAPPA'),
        _a(52299, 'Spy x Family Season 2', '$_cdn/1448/127956.jpg',
            mean: 8.25, rank: 280, numEpisodes: 12, status: 'finished_airing',
            genres: ['Action', 'Comedy'], studio: 'Wit Studio, CloverWorks'),
        _a(20, 'Naruto', '$_cdn/3/117463.jpg',
            mean: 8.01, rank: 640, numEpisodes: 220, status: 'finished_airing',
            genres: ['Action', 'Adventure'], studio: 'Pierrot'),
        _a(269, 'Bleach', '$_cdn/3/49869.jpg',
            mean: 7.92, rank: 720, numEpisodes: 366, status: 'finished_airing',
            genres: ['Action', 'Supernatural'], studio: 'Pierrot'),
        _a(38000, 'Kimetsu no Yaiba', '$_cdn/1286/99889.jpg',
            mean: 8.49, rank: 130, numEpisodes: 26, status: 'finished_airing',
            genres: ['Action', 'Fantasy'], studio: 'ufotable'),
        _a(16498, 'Shingeki no Kyojin', '$_cdn/10/47347.jpg',
            mean: 8.54, rank: 105, numEpisodes: 25, status: 'finished_airing',
            genres: ['Action', 'Drama'], studio: 'Wit Studio'),
        _a(32281, 'Kimi no Na wa.', '$_cdn/5/87048.jpg',
            mean: 8.84, rank: 22, numEpisodes: 1, mediaType: 'movie',
            status: 'finished_airing', genres: ['Drama', 'Romance'],
            studio: 'CoMix Wave Films'),
        _a(52305, 'Bocchi the Rock!', '$_cdn/1797/133152.jpg',
            mean: 8.73, rank: 40, numEpisodes: 12, status: 'finished_airing',
            genres: ['Comedy', 'Music'], studio: 'CloverWorks'),
      ];

  static AnimeSummary _a(
    int id,
    String title,
    String img, {
    double? mean,
    int? rank,
    int? numEpisodes,
    String? mediaType,
    String? status,
    List<String> genres = const [],
    String? studio,
    String? day,
    String? time,
  }) =>
      AnimeSummary(
        id: id,
        title: title,
        imageUrl: img,
        mean: mean,
        rank: rank,
        popularity: rank != null ? rank * 37 : null,
        numEpisodes: numEpisodes,
        mediaType: mediaType ?? 'tv',
        status: status,
        season: 'fall',
        seasonYear: 2026,
        genres: genres,
        synopsis:
            'A sweeping tale of adventure, friendship and self-discovery that '
            'captivated audiences worldwide. When an unexpected event turns '
            'everyday life upside down, an unlikely group of heroes must band '
            'together to face a challenge far greater than any of them imagined.',
        broadcastDay: day,
        broadcastTime: time,
        studio: studio,
        numListUsers: rank != null ? rank * 4200 : null,
      );

  static List<MangaSummary> get topManga => [
        _m(2, 'Berserk', 'https://cdn.myanimelist.net/images/manga/1/157897.jpg',
            mean: 9.47, rank: 1, chapters: 380),
        _m(13, 'One Piece', 'https://cdn.myanimelist.net/images/manga/2/253146.jpg',
            mean: 9.22, rank: 2, chapters: 1120),
        _m(1706, 'JoJo no Kimyou na Bouken: Steel Ball Run',
            'https://cdn.myanimelist.net/images/manga/3/179882.jpg',
            mean: 9.30, rank: 3, chapters: 96),
        _m(25, 'Fullmetal Alchemist',
            'https://cdn.myanimelist.net/images/manga/3/243675.jpg',
            mean: 9.10, rank: 5, chapters: 116),
        _m(44347, 'Oshi no Ko',
            'https://cdn.myanimelist.net/images/manga/4/284927.jpg',
            mean: 8.45, rank: 60, chapters: 166),
        _m(105778, 'Chainsaw Man',
            'https://cdn.myanimelist.net/images/manga/3/216464.jpg',
            mean: 8.55, rank: 45, chapters: 190),
      ];

  static MangaSummary _m(int id, String title, String img,
          {double? mean, int? rank, int? chapters}) =>
      MangaSummary(
        id: id,
        title: title,
        imageUrl: img,
        mean: mean,
        rank: rank,
        popularity: rank != null ? rank * 53 : null,
        numChapters: chapters,
        numVolumes: chapters != null ? (chapters / 9).ceil() : null,
        mediaType: 'manga',
        status: 'finished',
        genres: const ['Action', 'Drama'],
        synopsis:
            'A critically acclaimed manga series following unforgettable '
            'characters through a richly imagined world.',
        numListUsers: rank != null ? rank * 6100 : null,
      );

  static List<NewsItem> get news => [
        NewsItem(
          title: "'Frieren' Movie Announced for 2027 Theatrical Release",
          imageUrl: '$_cdn/1016/135109.jpg',
          excerpt:
              'The official website announced a brand-new theatrical film continuing the journey beyond the TV series.',
          date: '2026-10-10',
          url: 'https://myanimelist.net',
          author: 'MAL News',
        ),
        NewsItem(
          title: "Winter 2027 Anime Lineup: 42 New Series Revealed",
          imageUrl: '$_cdn/6/73245.jpg',
          excerpt:
              'The seasonal chart is filling up fast — here are the most anticipated premieres of the winter season.',
          date: '2026-10-08',
          url: 'https://myanimelist.net',
          author: 'MAL News',
        ),
        NewsItem(
          title: "'One Piece' Manga Enters Final Saga Milestone",
          imageUrl: 'https://cdn.myanimelist.net/images/manga/2/253146.jpg',
          excerpt:
              'Eiichiro Oda thanks fans as the long-running epic approaches its climax.',
          date: '2026-10-05',
          url: 'https://myanimelist.net',
          author: 'MAL News',
        ),
      ];

  static List<Review> get reviews => [
        const Review(
          author: 'AnimeFan88',
          score: 10,
          date: '2026-09-20',
          text: 'A masterpiece in every sense. The quiet moments hit harder '
              'than any battle scene, and the finale left me staring at the '
              'ceiling for an hour. Essential viewing.',
        ),
        const Review(
          author: 'sakuga enjoyer',
          score: 9,
          date: '2026-08-14',
          text: 'Gorgeous production paired with a genuinely moving story '
              'about time, memory and what we leave behind. A few slow '
              'episodes in the middle, but the payoff is immense.',
        ),
        const Review(
          author: 'critic_cat',
          score: 8,
          date: '2026-07-02',
          text: 'Beautifully directed with a haunting score. Not for everyone '
              '— it demands patience — but those who give in will be rewarded.',
        ),
      ];

  /// Demo "My List" entries (mutable copies are managed by the repository).
  static List<AnimeListEntry> get myAnimeList => [
        AnimeListEntry(
          anime: seasonalAnime[0],
          listStatus: const MyListStatus(
              status: AnimeListStatuses.watching, score: 10, progress: 18),
        ),
        AnimeListEntry(
          anime: seasonalAnime[1],
          listStatus: const MyListStatus(
              status: AnimeListStatuses.watching, score: 9, progress: 1095),
        ),
        AnimeListEntry(
          anime: seasonalAnime[3],
          listStatus: const MyListStatus(
              status: AnimeListStatuses.completed, score: 9, progress: 11),
        ),
        AnimeListEntry(
          anime: seasonalAnime[4],
          listStatus: const MyListStatus(
              status: AnimeListStatuses.completed, score: 8, progress: 12),
        ),
        AnimeListEntry(
          anime: seasonalAnime[11],
          listStatus: const MyListStatus(
              status: AnimeListStatuses.planToWatch, score: 0, progress: 0),
        ),
        AnimeListEntry(
          anime: seasonalAnime[9],
          listStatus: const MyListStatus(
              status: AnimeListStatuses.onHold, score: 7, progress: 12),
        ),
      ];

  static List<MangaListEntry> get myMangaList => [
        MangaListEntry(
          manga: topManga[0],
          listStatus: const MyListStatus(
              status: MangaListStatuses.reading, score: 10, progress: 200),
        ),
        MangaListEntry(
          manga: topManga[4],
          listStatus: const MyListStatus(
              status: MangaListStatuses.completed, score: 8, progress: 166),
        ),
        MangaListEntry(
          manga: topManga[5],
          listStatus: const MyListStatus(
              status: MangaListStatuses.planToRead, score: 0, progress: 0),
        ),
      ];

  static MalUser get demoUser => const MalUser(
        name: 'DemoUser',
        animeStats:
            MalUserStats(daysWatched: 42.5, meanScore: 8.4, totalEntries: 312),
        mangaStats:
            MalUserStats(daysWatched: 12.0, meanScore: 8.1, totalEntries: 86),
      );
}
