import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malclient/src/core/providers.dart';

/// Sort / filter / display options for the My List tab.
///
/// Persisted to SharedPreferences as JSON. Empty sets mean "no filter".
class ListFilterState {
  // ---------- sort ----------
  final String sortBy;
  final bool sortDesc;

  // ---------- anime filters ----------
  final Set<String> animeTypes; // tv, ova, movie, special, ona, music
  final Set<String> animeStatuses; // currently_airing, finished_airing, not_yet_aired
  final Set<String> ratings; // g, pg, pg_13, r, r_plus, rx
  final Set<String> genresInclude;
  final Set<String> genresExclude;

  // ---------- manga filters ----------
  final Set<String> mangaTypes; // manga, novel, light_novel, one_shot, ...
  final Set<String> mangaStatuses; // currently_publishing, finished, not_yet_published

  // ---------- display ----------
  final bool compactRows;

  const ListFilterState({
    this.sortBy = 'updated_at',
    this.sortDesc = true,
    this.animeTypes = const {},
    this.animeStatuses = const {},
    this.ratings = const {},
    this.genresInclude = const {},
    this.genresExclude = const {},
    this.mangaTypes = const {},
    this.mangaStatuses = const {},
    this.compactRows = false,
  });

  static const sortOptions = [
    ('title', 'Title'),
    ('list_score', 'List Score'),
    ('start_date', 'Start Date'),
    ('updated_at', 'Updated At'),
    ('popularity', 'Popularity'),
    ('list_users', 'No. of List users'),
    ('scoring_users', 'No. of Scoring users'),
    ('score', 'Score'),
  ];

  static const animeTypeOptions = [
    ('tv', 'TV'),
    ('ova', 'OVA'),
    ('movie', 'Movie'),
    ('special', 'Special'),
    ('ona', 'ONA'),
    ('music', 'Music'),
  ];

  static const animeStatusOptions = [
    ('currently_airing', 'Airing'),
    ('finished_airing', 'Complete'),
    ('not_yet_aired', 'Upcoming'),
  ];

  static const mangaTypeOptions = [
    ('manga', 'Manga'),
    ('novel', 'Novel'),
    ('light_novel', 'Light Novel'),
    ('one_shot', 'One Shot'),
    ('doujinshi', 'Doujinshi'),
    ('manhwa', 'Manhwa'),
    ('manhua', 'Manhua'),
  ];

  static const mangaStatusOptions = [
    ('currently_publishing', 'Publishing'),
    ('finished', 'Complete'),
    ('not_yet_published', 'Upcoming'),
  ];

  static const ratingOptions = [
    ('g', 'G - All Ages'),
    ('pg', 'PG - Children'),
    ('pg_13', 'PG-13 - Teens 13 or older'),
    ('r', 'R - 17+ (violence & profanity)'),
    ('r_plus', 'R+ - Mild Nudity'),
    ('rx', 'Rx - Hentai'),
  ];

  bool get hasActiveFilters =>
      animeTypes.isNotEmpty ||
      animeStatuses.isNotEmpty ||
      ratings.isNotEmpty ||
      genresInclude.isNotEmpty ||
      genresExclude.isNotEmpty ||
      mangaTypes.isNotEmpty ||
      mangaStatuses.isNotEmpty;

  bool get isDefaultSort => sortBy == 'updated_at' && sortDesc;

  ListFilterState copyWith({
    String? sortBy,
    bool? sortDesc,
    Set<String>? animeTypes,
    Set<String>? animeStatuses,
    Set<String>? ratings,
    Set<String>? genresInclude,
    Set<String>? genresExclude,
    Set<String>? mangaTypes,
    Set<String>? mangaStatuses,
    bool? compactRows,
  }) =>
      ListFilterState(
        sortBy: sortBy ?? this.sortBy,
        sortDesc: sortDesc ?? this.sortDesc,
        animeTypes: animeTypes ?? this.animeTypes,
        animeStatuses: animeStatuses ?? this.animeStatuses,
        ratings: ratings ?? this.ratings,
        genresInclude: genresInclude ?? this.genresInclude,
        genresExclude: genresExclude ?? this.genresExclude,
        mangaTypes: mangaTypes ?? this.mangaTypes,
        mangaStatuses: mangaStatuses ?? this.mangaStatuses,
        compactRows: compactRows ?? this.compactRows,
      );

  Map<String, dynamic> toJson() => {
        'sortBy': sortBy,
        'sortDesc': sortDesc,
        'animeTypes': animeTypes.toList(),
        'animeStatuses': animeStatuses.toList(),
        'ratings': ratings.toList(),
        'genresInclude': genresInclude.toList(),
        'genresExclude': genresExclude.toList(),
        'mangaTypes': mangaTypes.toList(),
        'mangaStatuses': mangaStatuses.toList(),
        'compactRows': compactRows,
      };

  factory ListFilterState.fromJson(Map<String, dynamic> json) {
    Set<String> setOf(String k) => {
          for (final e in (json[k] as List? ?? const []))
            if (e is String) e
        };
    return ListFilterState(
      sortBy: (json['sortBy'] as String?) ?? 'updated_at',
      sortDesc: (json['sortDesc'] as bool?) ?? true,
      animeTypes: setOf('animeTypes'),
      animeStatuses: setOf('animeStatuses'),
      ratings: setOf('ratings'),
      genresInclude: setOf('genresInclude'),
      genresExclude: setOf('genresExclude'),
      mangaTypes: setOf('mangaTypes'),
      mangaStatuses: setOf('mangaStatuses'),
      compactRows: (json['compactRows'] as bool?) ?? false,
    );
  }
}

final listFilterProvider =
    NotifierProvider<ListFilterNotifier, ListFilterState>(
        ListFilterNotifier.new);

class ListFilterNotifier extends Notifier<ListFilterState> {
  static const _key = 'list_filter';

  @override
  ListFilterState build() {
    final raw = ref.watch(sharedPrefsProvider).getString(_key);
    if (raw == null) return const ListFilterState();
    try {
      return ListFilterState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const ListFilterState();
    }
  }

  Future<void> _save(ListFilterState s) async {
    state = s;
    await ref
        .read(sharedPrefsProvider)
        .setString(_key, jsonEncode(s.toJson()));
  }

  Future<void> setSort(String by, bool desc) =>
      _save(state.copyWith(sortBy: by, sortDesc: desc));

  Future<void> toggleSortDir() =>
      _save(state.copyWith(sortDesc: !state.sortDesc));

  Future<void> update(ListFilterState s) => _save(s);

  Future<void> reset() => _save(const ListFilterState());
}
