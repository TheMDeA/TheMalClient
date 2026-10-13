import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/widgets/poster_card.dart';
import 'package:malclient/src/widgets/section_widgets.dart';

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
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  String? _genre;

  static const _genres = [
    'Action', 'Adventure', 'Comedy', 'Drama', 'Fantasy',
    'Romance', 'Sci-Fi', 'Slice of Life', 'Sports', 'Supernatural',
  ];

  @override
  void initState() {
    super.initState();
    final initial = switch (widget.initialTab) {
      'manga' => 1,
      'seasonal' => 2,
      _ => 0,
    };
    _tabs = TabController(length: 3, vsync: this, initialIndex: initial);
    if (widget.focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
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
            Expanded(
              child: _query.isEmpty ? _tabViews() : _searchResults(),
            ),
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
              onSelected: (_) => setState(() => _genre = _genre == g ? null : g),
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
        _grid(ref.watch(topAnimeProvider), ListKind.anime),
        _mangaGrid(ref.watch(topMangaProvider)),
        _grid(ref.watch(seasonalAnimeProvider), ListKind.anime),
      ],
    );
  }

  List<AnimeSummary> _applyGenre(List<AnimeSummary> items) {
    if (_genre == null) return items;
    return items.where((a) => a.genres.contains(_genre)).toList();
  }

  Widget _grid(AsyncValue<List<AnimeSummary>> value, ListKind kind) {
    return value.when(
      data: (items) => _posterGrid(
        _applyGenre(items)
            .map((a) => PosterCard(
                  imageUrl: a.imageUrl,
                  title: a.title,
                  mean: a.mean,
                  members: a.numListUsers,
                  rank: a.rank,
                  width: double.infinity,
                  onTap: () => context.push('/detail/anime/${a.id}'),
                ))
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncSection.error(
        error: e,
        onRetry: () => ref.invalidate(topAnimeProvider),
      ),
    );
  }

  Widget _mangaGrid(AsyncValue<List<MangaSummary>> value) {
    return value.when(
      data: (items) => _posterGrid(
        items
            .map((m) => PosterCard(
                  imageUrl: m.imageUrl,
                  title: m.title,
                  mean: m.mean,
                  members: m.numListUsers,
                  rank: m.rank,
                  width: double.infinity,
                  onTap: () => context.push('/detail/manga/${m.id}'),
                ))
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
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
      itemBuilder: (_, i) => cards[i],
    );
  }

  Widget _searchResults() {
    final animeF = ref.watch(_animeSearchProvider(_query));
    final mangaF = ref.watch(_mangaSearchProvider(_query));
    return animeF.when(
      data: (anime) => mangaF.when(
        data: (manga) {
          final cards = <PosterCard>[
            for (final a in anime)
              PosterCard(
                imageUrl: a.imageUrl,
                title: a.title,
                mean: a.mean,
                width: double.infinity,
                onTap: () => context.push('/detail/anime/${a.id}'),
              ),
            for (final m in manga)
              PosterCard(
                imageUrl: m.imageUrl,
                title: m.title,
                mean: m.mean,
                width: double.infinity,
                onTap: () => context.push('/detail/manga/${m.id}'),
              ),
          ];
          if (cards.isEmpty) {
            return const Center(child: Text('No results.'));
          }
          return _posterGrid(cards);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Search failed: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Search failed: $e')),
    );
  }
}

final _animeSearchProvider =
    FutureProvider.family<List<AnimeSummary>, String>((ref, q) {
  return ref.watch(mediaRepositoryProvider).searchAnime(q);
});

final _mangaSearchProvider =
    FutureProvider.family<List<MangaSummary>, String>((ref, q) {
  return ref.watch(mediaRepositoryProvider).searchManga(q);
});
