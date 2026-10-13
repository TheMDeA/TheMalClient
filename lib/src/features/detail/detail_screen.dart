import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/features/mylist/mylist_screen.dart';
import 'package:malclient/src/widgets/poster_card.dart';

/// Title detail screen: banner header, score row, countdown chip,
/// M3 TabBar (Synopsis | Media | Related | Reviews), add-to-list FAB.
class DetailScreen extends ConsumerStatefulWidget {
  final ListKind kind;
  final int id;

  const DetailScreen({super.key, required this.kind, required this.id});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  @override
  Widget build(BuildContext context) {
    // v1 focuses on anime details; manga reuses the anime layout
    // with manga-specific fields where available.
    final detail = ref.watch(_animeDetailProvider(widget.id));
    return detail.when(
      data: (d) => _DetailBody(detail: d, kind: widget.kind),
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 40),
              const SizedBox(height: 8),
              Text('Could not load details.\n$e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(_animeDetailProvider(widget.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _animeDetailProvider =
    FutureProvider.family<AnimeDetail, int>((ref, id) {
  return ref.watch(mediaRepositoryProvider).animeDetail(id);
});

class _DetailBody extends ConsumerStatefulWidget {
  final AnimeDetail detail;
  final ListKind kind;

  const _DetailBody({required this.detail, required this.kind});

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PosterImage(
                    url: d.imageUrl,
                    title: d.title,
                    borderRadius: BorderRadius.zero,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          scheme.surface.withValues(alpha: 0.9),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Text(
                      d.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            _scoreRow(context, d),
            if (d.isAiring && d.broadcastDay != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _CountdownChip(detail: d),
              ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Synopsis'),
                Tab(text: 'Media'),
                Tab(text: 'Related'),
                Tab(text: 'Reviews'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _SynopsisTab(detail: d),
                  _MediaTab(detail: d),
                  _RelatedTab(detail: d),
                  _ReviewsTab(animeId: d.id),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final mls = widget.detail.myListStatus ??
              const MyListStatus(status: AnimeListStatuses.planToWatch);
          showEditEntrySheet(
            context,
            ref,
            kind: widget.kind,
            id: widget.detail.id,
            title: widget.detail.title,
            status: mls,
            total: widget.detail.numEpisodes,
          );
        },
        icon: const Icon(Icons.add),
        label: Text(widget.detail.myListStatus == null
            ? 'Add to list'
            : 'Edit list entry'),
      ),
    );
  }

  Widget _scoreRow(BuildContext context, AnimeDetail d) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    Widget stat(String label, String value) => Column(
          children: [
            Text(
              value,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style:
                  textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          stat('Score', d.mean?.toStringAsFixed(2) ?? '—'),
          stat('Rank', d.rank != null ? '#${d.rank}' : '—'),
          stat('Popularity', d.popularity != null ? '#${d.popularity}' : '—'),
          stat(d.mediaType == 'movie' ? 'Duration' : 'Episodes',
              '${d.numEpisodes ?? '—'}'),
        ],
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final AnimeDetail detail;

  const _CountdownChip({required this.detail});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = detail.broadcastTime != null
        ? 'Airs ${_prettyDay(detail.broadcastDay)} at ${detail.broadcastTime}'
        : 'Currently airing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 16, color: scheme.onPrimaryContainer),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _prettyDay(String? day) {
    if (day == null) return '';
    return day[0].toUpperCase() + day.substring(1).replaceAll('s', '');
  }
}

class _SynopsisTab extends StatelessWidget {
  final AnimeDetail detail;

  const _SynopsisTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (detail.genres.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in detail.genres)
                Chip(
                  label: Text(g),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        if (detail.genres.isNotEmpty) const SizedBox(height: 16),
        Text(
          (detail.synopsis ?? 'No synopsis available.')
              .replaceAll('<br>', '\n')
              .replaceAll(RegExp(r'<[^>]*>'), ''),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 16),
        _infoRow(context, 'Studio', detail.studio),
        _infoRow(context, 'Source', detail.source),
        _infoRow(context, 'Season',
            detail.seasonYear != null ? '${_cap(detail.season)} ${detail.seasonYear}' : null),
        _infoRow(context, 'Status', _prettyStatus(detail.status)),
      ],
    );
  }

  String _cap(String? s) =>
      s == null || s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  String _prettyStatus(String? s) => switch (s) {
        'currently_airing' => 'Currently airing',
        'finished_airing' => 'Finished airing',
        'not_yet_aired' => 'Not yet aired',
        _ => s ?? '—',
      };

  Widget _infoRow(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _MediaTab extends StatelessWidget {
  final AnimeDetail detail;

  const _MediaTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    // v1: key art + facts. Full gallery/pv support can follow.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: PosterImage(
            url: detail.imageUrl,
            title: detail.title,
            width: 200,
            height: 284,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Pictures and videos are coming to this tab in a later update.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _RelatedTab extends StatelessWidget {
  final AnimeDetail detail;

  const _RelatedTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    final items = detail.related.isNotEmpty
        ? detail.related
        : detail.recommendations;
    if (items.isEmpty) {
      return const Center(child: Text('No related titles.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i];
        return PosterCard(
          imageUrl: a.imageUrl,
          title: a.title,
          mean: a.mean,
          width: double.infinity,
          onTap: () => context.push('/detail/anime/${a.id}'),
        );
      },
    );
  }
}

class _ReviewsTab extends ConsumerWidget {
  final int animeId;

  const _ReviewsTab({required this.animeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(_reviewsProvider(animeId));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return reviews.when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No reviews yet.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final r = items[i];
            return Card.filled(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: r.authorImageUrl != null
                              ? NetworkImage(r.authorImageUrl!)
                              : null,
                          child: r.authorImageUrl == null
                              ? Text(r.author.isEmpty
                                  ? '?'
                                  : r.author[0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.author,
                                  style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600)),
                              Text(
                                r.date.length >= 10
                                    ? r.date.substring(0, 10)
                                    : r.date,
                                style: textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${r.score}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      r.text,
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium
                          ?.copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load reviews: $e')),
    );
  }
}

final _reviewsProvider =
    FutureProvider.family<List<Review>, int>((ref, id) {
  return ref.watch(jikanRepositoryProvider).animeReviews(id);
});
