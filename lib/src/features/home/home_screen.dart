import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/widgets/poster_card.dart';
import 'package:malclient/src/widgets/section_widgets.dart';

/// Home tab: greeting header, filter chips, news rail, seasonal rail,
/// suggested rail. DailyAL-inspired, M3 components.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    final seasonal = ref.watch(seasonalAnimeProvider);
    final top = ref.watch(topAnimeProvider);
    final news = ref.watch(homeNewsProvider);
    final scheme = Theme.of(context).colorScheme;

    final name = auth?.user?.name ?? (auth?.isDemo == true ? 'DemoUser' : 'Guest');

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(seasonalAnimeProvider);
            ref.invalidate(topAnimeProvider);
            ref.invalidate(homeNewsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header(context, name, scheme)),
              SliverToBoxAdapter(child: _filterChips(context)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'News',
                  onSeeAll: () => context.push('/news'),
                ),
              ),
              SliverToBoxAdapter(child: _newsRail(context, ref, news)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Seasonal Anime',
                  onSeeAll: () => context.go('/discover?tab=seasonal'),
                ),
              ),
              SliverToBoxAdapter(
                child: _animeRail(context, ref, seasonal, ListKind.anime),
              ),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Suggested Anime',
                  onSeeAll: () => context.go('/discover?tab=top'),
                ),
              ),
              SliverToBoxAdapter(
                child: _animeRail(context, ref, top, ListKind.anime),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String name, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $name',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'What are we watching today?',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _soon(context, 'Notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () => context.go('/mylist'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/discover?focusSearch=true'),
          ),
        ],
      ),
    );
  }

  Widget _filterChips(BuildContext context) {
    final chips = ['Categories', 'Genres', 'Top Anime', 'Top Manga'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = chips[i];
          return Center(
            child: FilterChip(
              label: Text(label),
              selected: false,
              onSelected: (_) {
                switch (label) {
                  case 'Top Anime':
                    context.go('/discover?tab=top');
                  case 'Top Manga':
                    context.go('/discover?tab=manga');
                  default:
                    _soon(context, label);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _newsRail(BuildContext context, WidgetRef ref,
      AsyncValue<List<NewsItem>> news) {
    return news.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length.clamp(0, 8),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _NewsCard(item: items[i]),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncSection.error(
        error: e,
        onRetry: () => ref.invalidate(homeNewsProvider),
      ),
    );
  }

  Widget _animeRail(BuildContext context, WidgetRef ref,
      AsyncValue<List<AnimeSummary>> value, ListKind kind) {
    return value.when(
      data: (items) => PosterRail(
        cards: [
          for (final a in items.take(12))
            PosterCard(
              imageUrl: a.imageUrl,
              title: a.title,
              mean: a.mean,
              members: a.numListUsers,
              rank: a.rank,
              onTap: () => context.push('/detail/anime/${a.id}'),
            ),
        ],
      ),
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncSection.error(
        error: e,
        onRetry: () => ref.invalidate(seasonalAnimeProvider),
      ),
    );
  }

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is coming soon in this preview.')),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;

  const _NewsCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 300,
      child: Card.filled(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PosterImage(
                url: item.imageUrl,
                title: item.title,
                width: 86,
                height: 130,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        item.excerpt,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      item.date.length >= 10 ? item.date.substring(0, 10) : item.date,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
