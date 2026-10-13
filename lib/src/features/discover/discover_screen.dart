import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/core/mal_genres.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/widgets/poster_card.dart';
import 'package:malclient/src/widgets/section_widgets.dart';
import 'package:malclient/src/widgets/skeleton.dart';
import 'package:malclient/src/widgets/entrance.dart';

/// Discover tab: M3 SearchBar, genre chips, and Top Anime / Top Manga /
/// Seasonal grids. `?tab=top|manga|seasonal` and `?focusSearch=true` are
/// honored for deep links from Home.
class DiscoverScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  final bool focusSearch;

  const DiscoverScreen({super.key, this.initialTab, this.focusSearch = false});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TabController _searchTabs;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _genre;

  /// Advanced search filters, kept separate per media kind.
  _SearchFilters _animeFilters = const _SearchFilters();
  _SearchFilters _mangaFilters = const _SearchFilters();

  static const _genres = malGenres;

  @override
  void initState() {
    super.initState();
    final initial = switch (widget.initialTab) {
      'manga' => 1,
      'seasonal' => 2,
      _ => 0,
    };
    _tabs = TabController(length: 3, vsync: this, initialIndex: initial);
    _searchTabs = TabController(length: 2, vsync: this);
    // Refresh the filter badge when switching between anime/manga results.
    _searchTabs.addListener(() => setState(() {}));
    if (widget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchTabs.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SearchBar(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                hintText: 'Search anime and manga',
                leading: const Icon(Icons.search),
                trailing: _query.isEmpty
                    ? null
                    : [
                        _filterButton(),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                      ],
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            if (_query.isEmpty) _genreChips(),
            if (_query.isEmpty)
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: 'Top Anime'),
                  Tab(text: 'Top Manga'),
                  Tab(text: 'Seasonal'),
                ],
              ),
            Expanded(child: _query.isEmpty ? _tabViews() : _searchResults()),
          ],
        ),
      ),
    );
  }

  Widget _genreChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _genres.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = _genres[i];
          return Center(
            child: FilterChip(
              label: Text(g),
              selected: _genre == g,
              onSelected: (_) =>
                  setState(() => _genre = _genre == g ? null : g),
            ),
          );
        },
      ),
    );
  }

  Widget _tabViews() {
    return TabBarView(
      controller: _tabs,
      children: [
        _grid(ref.watch(topAnimeProvider), ListKind.anime, topAnimeProvider),
        _mangaGrid(ref.watch(topMangaProvider), topMangaProvider),
        _grid(ref.watch(seasonalAnimeProvider), ListKind.anime,
            seasonalAnimeProvider),
      ],
    );
  }

  List<AnimeSummary> _applyGenre(List<AnimeSummary> items) {
    if (_genre == null) return items;
    return items.where((a) => a.genres.contains(_genre)).toList();
  }

  Widget _grid(AsyncValue<List<AnimeSummary>> value, ListKind kind,
      FutureProvider<List<AnimeSummary>> provider) {
    return value.when(
      data: (items) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          try {
            await ref.read(provider.future);
          } catch (_) {}
        },
        child: _posterGrid(
          _applyGenre(items)
              .map(
                (a) => PosterCard(
                  imageUrl: a.imageUrl,
                  title: a.title,
                  mean: a.mean,
                  members: a.numListUsers,
                  rank: a.rank,
                  width: double.infinity,
                  onTap: () => context.push('/detail/anime/${a.id}'),
                ),
              )
              .toList(),
        ),
      ),
      loading: () => const SkeletonPosterGrid(),
      error: (e, _) => AsyncSection.error(
        error: e,
        onRetry: () => ref.invalidate(topAnimeProvider),
      ),
    );
  }

  Widget _mangaGrid(AsyncValue<List<MangaSummary>> value,
      FutureProvider<List<MangaSummary>> provider) {
    return value.when(
      data: (items) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          try {
            await ref.read(provider.future);
          } catch (_) {}
        },
        child: _posterGrid(
          items
              .map(
                (m) => PosterCard(
                  imageUrl: m.imageUrl,
                  title: m.title,
                  mean: m.mean,
                  members: m.numListUsers,
                  rank: m.rank,
                  width: double.infinity,
                  onTap: () => context.push('/detail/manga/${m.id}'),
                ),
              )
              .toList(),
        ),
      ),
      loading: () => const SkeletonPosterGrid(),
      error: (e, _) => AsyncSection.error(
        error: e,
        onRetry: () => ref.invalidate(topMangaProvider),
      ),
    );
  }

  Widget _posterGrid(List<PosterCard> cards) {
    if (cards.isEmpty) {
      return const Center(child: Text('Nothing here yet.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => Entrance(index: i, child: cards[i]),
    );
  }

  /// Filter button with an active-indicator badge. Shown inside the search
  /// bar while searching; applies to the currently visible result tab.
  Widget _filterButton() {
    final active = _searchTabs.index == 0
        ? _animeFilters.isActive
        : _mangaFilters.isActive;
    return Badge(
      isLabelVisible: active,
      child: IconButton(
        icon: const Icon(Icons.filter_list),
        tooltip: 'Search filters',
        onPressed: _openFilterSheet,
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final isAnime = _searchTabs.index == 0;
    final result = await showModalBottomSheet<_SearchFilters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SearchFilterSheet(
        initial: isAnime ? _animeFilters : _mangaFilters,
        isAnime: isAnime,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (isAnime) {
          _animeFilters = result;
        } else {
          _mangaFilters = result;
        }
      });
    }
  }

  Widget _searchResults() {
    return Column(
      children: [
        TabBar(
          controller: _searchTabs,
          tabs: const [
            Tab(text: 'Anime'),
            Tab(text: 'Manga'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _searchTabs,
            children: [_animeSearchGrid(), _mangaSearchGrid()],
          ),
        ),
      ],
    );
  }

  Widget _animeSearchGrid() {
    final f = _animeFilters;
    final value = ref.watch(
      _animeSearchProvider((
        q: _query,
        type: f.type,
        status: f.status,
        rating: f.rating,
        genres: f.genreIdsParam,
      )),
    );
    return value.when(
      data: (items) => _posterGrid(
        items
            .map(
              (a) => PosterCard(
                imageUrl: a.imageUrl,
                title: a.title,
                mean: a.mean,
                width: double.infinity,
                onTap: () => context.push('/detail/anime/${a.id}'),
              ),
            )
            .toList(),
      ),
      loading: () => const SkeletonPosterGrid(),
      error: (e, _) => Center(child: Text('Search failed: $e')),
    );
  }

  Widget _mangaSearchGrid() {
    final f = _mangaFilters;
    final value = ref.watch(
      _mangaSearchProvider((
        q: _query,
        type: f.type,
        status: f.status,
        genres: f.genreIdsParam,
      )),
    );
    return value.when(
      data: (items) => _posterGrid(
        items
            .map(
              (m) => PosterCard(
                imageUrl: m.imageUrl,
                title: m.title,
                mean: m.mean,
                width: double.infinity,
                onTap: () => context.push('/detail/manga/${m.id}'),
              ),
            )
            .toList(),
      ),
      loading: () => const SkeletonPosterGrid(),
      error: (e, _) => Center(child: Text('Search failed: $e')),
    );
  }
}

/// Immutable advanced-search filter state. `genres` holds MAL genre names;
/// [genreIdsParam] converts them to the comma-separated ID list the API wants.
class _SearchFilters {
  final String? type;
  final String? status;
  final String? rating;
  final Set<String> genres;

  const _SearchFilters({
    this.type,
    this.status,
    this.rating,
    this.genres = const {},
  });

  bool get isActive =>
      type != null || status != null || rating != null || genres.isNotEmpty;

  String? get genreIdsParam {
    if (genres.isEmpty) return null;
    final ids = <int>[];
    for (final g in genres) {
      final id = malGenreIds[g];
      if (id != null) ids.add(id);
    }
    return ids.isEmpty ? null : ids.join(',');
  }
}

final _animeSearchProvider =
    FutureProvider.family<
      List<AnimeSummary>,
      ({String q, String? type, String? status, String? rating, String? genres})
    >((ref, p) {
      return ref
          .watch(mediaRepositoryProvider)
          .searchAnime(
            p.q,
            type: p.type,
            status: p.status,
            rating: p.rating,
            genres: p.genres,
          );
    });

final _mangaSearchProvider =
    FutureProvider.family<
      List<MangaSummary>,
      ({String q, String? type, String? status, String? genres})
    >((ref, p) {
      return ref
          .watch(mediaRepositoryProvider)
          .searchManga(p.q, type: p.type, status: p.status, genres: p.genres);
    });

// ---------- filter sheet ----------

const _animeTypeOptions = [
  ('tv', 'TV'),
  ('ova', 'OVA'),
  ('movie', 'Movie'),
  ('special', 'Special'),
  ('ona', 'ONA'),
  ('music', 'Music'),
];
const _mangaTypeOptions = [
  ('manga', 'Manga'),
  ('novel', 'Novel'),
  ('light_novel', 'Light Novel'),
  ('one_shot', 'One Shot'),
  ('doujin', 'Doujinshi'),
  ('manhwa', 'Manhwa'),
  ('manhua', 'Manhua'),
];
const _animeStatusOptions = [
  ('airing', 'Airing'),
  ('complete', 'Complete'),
  ('upcoming', 'Upcoming'),
];
const _mangaStatusOptions = [
  ('publishing', 'Publishing'),
  ('complete', 'Complete'),
  ('upcoming', 'Upcoming'),
];
const _ratingOptions = [
  ('g', 'G'),
  ('pg', 'PG'),
  ('pg_13', 'PG-13'),
  ('r', 'R'),
  ('r_plus', 'R+'),
  ('rx', 'Rx'),
];

/// Advanced search filter bottom sheet. Edits a draft of [_SearchFilters];
/// Apply returns it, Clear resets to empty, dismissing discards changes.
class _SearchFilterSheet extends StatefulWidget {
  final _SearchFilters initial;
  final bool isAnime;

  const _SearchFilterSheet({required this.initial, required this.isAnime});

  @override
  State<_SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<_SearchFilterSheet> {
  late String? _type;
  late String? _status;
  late String? _rating;
  late Set<String> _genres;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _status = widget.initial.status;
    _rating = widget.initial.rating;
    _genres = Set.of(widget.initial.genres);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Search filters',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  _singleSelectSection(
                    title: widget.isAnime ? 'Anime type' : 'Manga type',
                    options: widget.isAnime
                        ? _animeTypeOptions
                        : _mangaTypeOptions,
                    value: _type,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                  _singleSelectSection(
                    title: widget.isAnime ? 'Anime status' : 'Manga status',
                    options: widget.isAnime
                        ? _animeStatusOptions
                        : _mangaStatusOptions,
                    value: _status,
                    onChanged: (v) => setState(() => _status = v),
                  ),
                  if (widget.isAnime)
                    _singleSelectSection(
                      title: 'Rating',
                      options: _ratingOptions,
                      value: _rating,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                  Text(
                    'Genres',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final g in malGenres)
                        FilterChip(
                          label: Text(g),
                          selected: _genres.contains(g),
                          onSelected: (_) => setState(() {
                            _genres.contains(g)
                                ? _genres.remove(g)
                                : _genres.add(g);
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _type = null;
                      _status = null;
                      _rating = null;
                      _genres = {};
                    }),
                    child: const Text('Clear'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _SearchFilters(
                        type: _type,
                        status: _status,
                        rating: _rating,
                        genres: _genres,
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _singleSelectSection({
    required String title,
    required List<(String, String)> options,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (v, label) in options)
              ChoiceChip(
                label: Text(label),
                selected: value == v,
                onSelected: (_) => onChanged(value == v ? null : v),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
