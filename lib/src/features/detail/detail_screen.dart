import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/features/mylist/mylist_screen.dart';
import 'package:malclient/src/widgets/poster_card.dart';
import 'package:malclient/src/widgets/entrance.dart';

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
              Text('Could not load details.\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(_animeDetailProvider(widget.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _animeDetailProvider = FutureProvider.family<AnimeDetail, int>((ref, id) {
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
  late final ScrollController _outerScroll;

  /// Title language: 0 = default, 1 = English, 2 = Japanese.
  int _titleLang = 0;

  bool get _isAnime => widget.kind == ListKind.anime;

  String get _displayTitle {
    final d = widget.detail;
    return switch (_titleLang) {
      1 => d.titleEn ?? d.title,
      2 => d.titleJa ?? d.title,
      _ => d.title,
    };
  }

  @override
  void initState() {
    super.initState();
    // Anime: 7 tabs (Synopsis, Characters, Staff, Media, Related, Reviews, More Info).
    // Manga: 6 tabs (no Staff — Jikan has no manga staff endpoint).
    _tabs = TabController(length: _isAnime ? 7 : 6, vsync: this);
    _outerScroll = ScrollController();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _outerScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _displayTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push('/discover'),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onPressed: () => _showMoreSheet(context, d, _isAnime),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final id = widget.detail.id;
          ref.invalidate(_animeDetailProvider(id));
          ref.invalidate(animeCharactersProvider(id));
          ref.invalidate(animePicturesProvider((id: id, isAnime: _isAnime)));
          ref.invalidate(animeStatisticsProvider(id));
          ref.invalidate(_reviewsProvider(id));
          if (_isAnime) ref.invalidate(animeStaffProvider(id));
          try {
            await ref.read(_animeDetailProvider(id).future);
          } catch (_) {}
        },
        child: NestedScrollView(
        controller: _outerScroll,
        headerSliverBuilder: (context, innerScrolled) => [
          // Auto-sizes to its content: no hardcoded height, so the
          // countdown chip can never overlap the tab bar.
          SliverToBoxAdapter(
            child: _ParallaxHeader(
              controller: _outerScroll,
              child: Column(
                children: [
                  _DetailHeader(
                    detail: d,
                    kind: _isAnime ? 'anime' : 'manga',
                    titleLang: _titleLang,
                    onTitleLangChanged: (v) => setState(() => _titleLang = v),
                    onInfoTap: () => _tabs.animateTo(_isAnime ? 6 : 5),
                    onBookmarkTap: () => _openEditSheet(context),
                  ),
                  if (d.isAiring && d.broadcastDay != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _CountdownChip(detail: d),
                    ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarHeaderDelegate(_tabs, _isAnime),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _SynopsisTab(detail: d),
            _CharactersTab(id: d.id, isAnime: _isAnime),
            if (_isAnime) _StaffTab(animeId: d.id),
            _MediaTab(detail: d, isAnime: _isAnime),
            _RelatedTab(detail: d),
            _ReviewsTab(animeId: d.id),
            _MoreInfoTab(detail: d, isAnime: _isAnime),
          ],
        ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditSheet(context),
        icon: Icon(
            widget.detail.myListStatus == null ? Icons.add : Icons.edit),
        label: Text(_fabLabel()),
      ),
    );
  }

  /// FAB label: "Add to list" for new entries, otherwise the current list
  /// status — with episode progress for in-progress entries
  /// ("Watching • 12/64").
  String _fabLabel() {
    final mls = widget.detail.myListStatus;
    if (mls == null) return 'Add to list';
    final label = _isAnime
        ? AnimeListStatuses.label(mls.status)
        : MangaListStatuses.label(mls.status);
    final inProgress = mls.status == AnimeListStatuses.watching ||
        mls.status == MangaListStatuses.reading;
    if (!inProgress) return label;
    final total = _isAnime ? widget.detail.numEpisodes : null;
    final progress = total != null && total > 0
        ? '${mls.progress}/$total'
        : '${mls.progress}';
    return '$label • $progress';
  }

  void _openEditSheet(BuildContext context) {
    final mls =
        widget.detail.myListStatus ??
        const MyListStatus(status: AnimeListStatuses.planToWatch);
    showEditEntrySheet(
      context,
      ref,
      kind: widget.kind,
      id: widget.detail.id,
      title: widget.detail.title,
      status: mls,
      total: widget.detail.numEpisodes,
      isNew: widget.detail.myListStatus == null,
    );
  }

  void _showMoreSheet(BuildContext context, AnimeDetail d, bool isAnime) {
    final malPath = isAnime ? 'anime' : 'manga';
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Open in MyAnimeList'),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(
                  Uri.parse('https://myanimelist.net/$malPath/${d.id}'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${d.title}\nhttps://myanimelist.net/$malPath/${d.id}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


/// Wraps the detail header and applies a parallax drift + fade as the
/// outer scroll view collapses it. Lives in a [SliverToBoxAdapter] so it
/// always sizes to its content — no hardcoded heights, no overlap.
class _ParallaxHeader extends StatelessWidget {
  final ScrollController controller;
  final Widget child;

  const _ParallaxHeader({required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final offset =
            controller.hasClients ? controller.offset : 0.0;
        // Drift slower than the scroll (parallax) and fade out.
        return Transform.translate(
          offset: Offset(0, offset * 0.35),
          child: Opacity(
            opacity: (1 - offset / 320).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }
}

/// Pinned tab bar below the collapsing header.
class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  final bool isAnime;

  _TabBarHeaderDelegate(this.controller, this.isAnime);

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabs: [
          const Tab(text: 'Synopsis'),
          const Tab(text: 'Characters'),
          if (isAnime) const Tab(text: 'Staff'),
          const Tab(text: 'Media'),
          const Tab(text: 'Related'),
          const Tab(text: 'Reviews'),
          const Tab(text: 'More Info'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.controller != controller ||
      oldDelegate.isAnime != isAnime;
}

/// Detail header: poster on the left, info panel on the right (DailyAL style).
class _DetailHeader extends StatelessWidget {
  final AnimeDetail detail;
  final String kind;
  final int titleLang;
  final ValueChanged<int> onTitleLangChanged;
  final VoidCallback onInfoTap;
  final VoidCallback onBookmarkTap;

  const _DetailHeader({
    required this.detail,
    required this.kind,
    required this.titleLang,
    required this.onTitleLangChanged,
    required this.onInfoTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final inList = d.myListStatus != null;

    Widget infoRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster with overlays.
          SizedBox(
            width: 150,
            child: Stack(
              children: [
                PosterImage(
                  url: d.imageUrl,
                  title: d.title,
                  width: 150,
                  height: 215,
                  borderRadius: BorderRadius.circular(12),
                  heroTag: 'poster-$kind-${d.id}',
                ),
                // Title language switcher.
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < 3; i++)
                            GestureDetector(
                              onTap: () => onTitleLangChanged(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: titleLang == i
                                      ? scheme.primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ['TI', 'EN', 'JA'][i],
                                  style: TextStyle(
                                    color: titleLang == i
                                        ? scheme.onPrimary
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bookmark + info buttons.
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              inList
                                  ? Icons.bookmark
                                  : Icons.bookmark_add,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: inList
                                ? 'Edit list entry'
                                : 'Add to list',
                            onPressed: onBookmarkTap,
                            visualDensity: VisualDensity.compact,
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.white24,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                            tooltip: 'More info',
                            onPressed: onInfoTap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Info panel.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.rank != null)
                  Text(
                    '#${d.rank}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                const SizedBox(height: 2),
                if (d.mean != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        d.mean!.toStringAsFixed(2),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                if (d.numScoringUsers != null)
                  Text(
                    '${_compactNum(d.numScoringUsers!)} users',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: 8),
                infoRow('Format', _formatLine(d)),
                infoRow('Aired', _airedLine(d)),
                if (d.popularity != null)
                  infoRow('Popularity', '#${d.popularity}'),
                if (d.studio != null) infoRow('Studios', d.studio!),
                if (d.numListUsers != null)
                  infoRow('Members', _number(d.numListUsers!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLine(AnimeDetail d) {
    final type = switch (d.mediaType) {
      'tv' => 'TV',
      'movie' => 'Movie',
      'ova' => 'OVA',
      'ona' => 'ONA',
      'special' => 'Special',
      _ => d.mediaType ?? '',
    };
    final n = d.numEpisodes;
    return n != null ? '$type ($n eps)' : type;
  }

  String _airedLine(AnimeDetail d) {
    if (d.seasonYear != null) {
      final s = d.season ?? '';
      final cap = s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
      return '$cap ${d.seasonYear}';
    }
    return d.airedFrom?.substring(0, 4) ?? '—';
  }

  String _compactNum(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return '${v.toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return '${v.toStringAsFixed(1)}K';
    }
    return '$n';
  }

  String _number(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}

class _CountdownChip extends StatefulWidget {
  final AnimeDetail detail;

  const _CountdownChip({required this.detail});

  @override
  State<_CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<_CountdownChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick every minute to keep the countdown fresh.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final d = widget.detail;
    final label = _buildLabel(d);
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                label,
                key: ValueKey(label),
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Ep 2 aired • Ep 3 Fri 22:00 • in 3d 1h 14m"
  String _buildLabel(AnimeDetail d) {
    final aired = _latestAiredEpisode(d);
    int? next;
    if (aired != null) {
      next = aired + 1;
      final total = d.numEpisodes;
      if (total != null && next > total) next = null; // finale already aired
    }

    final airTime = _shortAirLabel(d); // "Fri 22:00", local time
    String epPart;
    if (aired != null && next != null) {
      epPart = 'Ep $aired aired • Ep $next';
    } else if (next != null) {
      epPart = 'Ep $next';
    } else if (aired != null) {
      epPart = 'Ep $aired aired';
    } else {
      epPart = '';
    }

    final parts = <String>[];
    if (epPart.isNotEmpty && airTime != null) {
      parts.add('$epPart $airTime');
    } else if (epPart.isNotEmpty) {
      parts.add(epPart);
    } else if (airTime != null) {
      parts.add('Airs $airTime');
    } else {
      parts.add('Currently airing');
    }
    final countdown = _countdown(d);
    if (countdown != null) parts.add(countdown);
    return parts.join(' • ');
  }

  /// "Fri 22:00" in the phone's local timezone (broadcast is JST).
  String? _shortAirLabel(AnimeDetail d) {
    final next = _nextAirDate(d);
    if (next == null) return null;
    final day = switch (next.weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => '',
    };
    final time =
        '${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';
    return '$day $time';
  }

  /// Estimates the latest aired episode from start date + weekly broadcast.
  int? _latestAiredEpisode(AnimeDetail d) {
    final start = d.airedFrom;
    if (start == null || start.length < 10) return null;
    try {
      final startDate = DateTime.parse(start.substring(0, 10));
      final now = DateTime.now();
      if (now.isBefore(startDate)) return null;
      final weeks = now.difference(startDate).inDays ~/ 7;
      var ep = weeks + 1;
      final total = d.numEpisodes;
      if (total != null && ep > total) ep = total;
      return ep > 0 ? ep : null;
    } catch (_) {
      return null;
    }
  }

  /// "in 2d 4h 12m" until the next episode (broadcast is JST).
  String? _countdown(AnimeDetail d) {
    final next = _nextAirDate(d);
    if (next == null) return null;
    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return null;
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    if (days > 0) return 'in ${days}d ${hours}h ${mins}m';
    if (hours > 0) return 'in ${hours}h ${mins}m';
    return 'in ${mins}m';
  }

  /// Next broadcast datetime in local time. Broadcast times are JST (UTC+9).
  DateTime? _nextAirDate(AnimeDetail d) {
    final day = d.broadcastDay;
    final time = d.broadcastTime;
    if (day == null || time == null) return null;
    final weekday = _weekday(day);
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || weekday == null) return null;

    // Work in JST, then convert to local.
    final jstNow = DateTime.now().toUtc().add(const Duration(hours: 9));
    var candidate = DateTime.utc(
      jstNow.year,
      jstNow.month,
      jstNow.day,
      hour,
      minute,
    );
    var daysAhead = (weekday - candidate.weekday) % 7;
    if (daysAhead == 0 && !candidate.isAfter(jstNow)) daysAhead = 7;
    candidate = candidate.add(Duration(days: daysAhead));
    // JST -> UTC -> local.
    return candidate.subtract(const Duration(hours: 9)).toLocal();
  }

  int? _weekday(String day) => switch (day.toLowerCase()) {
    'monday' || 'mondays' => DateTime.monday,
    'tuesday' || 'tuesdays' => DateTime.tuesday,
    'wednesday' || 'wednesdays' => DateTime.wednesday,
    'thursday' || 'thursdays' => DateTime.thursday,
    'friday' || 'fridays' => DateTime.friday,
    'saturday' || 'saturdays' => DateTime.saturday,
    'sunday' || 'sundays' => DateTime.sunday,
    _ => null,
  };
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
                Chip(label: Text(g), visualDensity: VisualDensity.compact),
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
        _StatisticsSection(animeId: detail.id),
      ],
    );
  }
}

/// Aggregate user statistics: status distribution + score distribution.
/// Source: Jikan `/anime/{id}/statistics`.
class _StatisticsSection extends ConsumerWidget {
  final int animeId;

  const _StatisticsSection({required this.animeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(animeStatisticsProvider(animeId));
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return stats.when(
      data: (s) {
        if (s == null || s.total == 0) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text(
              'Statistics',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _statBar(context, 'Watching', s.watching, s.total, scheme.primary),
            _statBar(context, 'Completed', s.completed, s.total, Colors.green),
            _statBar(context, 'On Hold', s.onHold, s.total, Colors.orange),
            _statBar(context, 'Dropped', s.dropped, s.total, scheme.error),
            _statBar(
              context,
              'Plan to Watch',
              s.planToWatch,
              s.total,
              scheme.tertiary,
            ),
            if (s.scorePercent.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Score distribution',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int score = 10; score >= 1; score--)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${(s.scorePercent[score] ?? 0).toStringAsFixed(0)}%',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                height:
                                    60 *
                                    (s.scorePercent[score] ?? 0) /
                                    _maxScore(s.scorePercent),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$score',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  double _maxScore(Map<int, double> m) {
    double max = 1;
    for (final v in m.values) {
      if (v > max) max = v;
    }
    return max;
  }

  Widget _statBar(
    BuildContext context,
    String label,
    int count,
    int total,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: textTheme.bodySmall)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              '${_fmt(count)} (${(pct * 100).toStringAsFixed(1)}%)',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

/// Characters tab: grid of characters with voice actors (Jikan).
class _CharactersTab extends ConsumerWidget {
  final int id;
  final bool isAnime;

  const _CharactersTab({required this.id, required this.isAnime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chars = ref.watch(
      isAnime ? animeCharactersProvider(id) : mangaCharactersProvider(id),
    );
    final textTheme = Theme.of(context).textTheme;

    return chars.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No characters found.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.62,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final c = items[i];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/detail/character/${c.malId}'),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PosterImage(
                        url: c.imageUrl,
                        title: c.name,
                        heroTag: 'character-${c.malId}',
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    c.role.isNotEmpty
                        ? c.role
                        : (c.voiceActors.isNotEmpty ? c.voiceActors.first : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'Could not load characters.',
        details: _errorDetails(e),
        onRetry: () => ref.invalidate(
          isAnime ? animeCharactersProvider(id) : mangaCharactersProvider(id),
        ),
      ),
    );
  }
}

/// Error state with a retry button for Jikan-powered tabs.
class _ErrorRetry extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback onRetry;

  const _ErrorRetry({
    required this.message,
    this.details,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (details != null) ...[
              const SizedBox(height: 4),
              Text(
                details!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Human-readable error details for debugging Jikan failures.
String _errorDetails(Object e) {
  final s = e.toString();
  // DioException message is verbose; extract the key part.
  if (s.contains('DioException')) {
    if (s.contains('status code of 429')) {
      return 'Rate limited (429). Try again in a moment.';
    }
    if (s.contains('status code of 404')) return 'Not found (404).';
    final match = RegExp(r'status code of (\d+)').firstMatch(s);
    if (match != null) return 'HTTP ${match.group(1)}.';
    if (s.contains('SocketException') || s.contains('Connection')) {
      return 'No connection.';
    }
    if (s.contains('timeout')) return 'Request timed out.';
  }
  return s.length > 120 ? '${s.substring(0, 120)}…' : s;
}

/// Staff tab (anime only): list of staff with positions (Jikan).
class _StaffTab extends ConsumerWidget {
  final int animeId;

  const _StaffTab({required this.animeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(animeStaffProvider(animeId));
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return staff.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No staff found.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final s = items[i];
            return Card.filled(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/detail/staff/${s.malId}'),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PosterImage(
                          url: s.imageUrl,
                          title: s.name,
                          heroTag: 'staff-${s.malId}',
                          width: 48,
                          height: 68,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (s.positions.isNotEmpty)
                              Text(
                                s.positions.take(3).join(', '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
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
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorRetry(
        message: 'Could not load staff.',
        details: _errorDetails(e),
        onRetry: () => ref.invalidate(animeStaffProvider(animeId)),
      ),
    );
  }
}

class _MediaTab extends ConsumerWidget {
  final AnimeDetail detail;
  final bool isAnime;

  const _MediaTab({required this.detail, required this.isAnime});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pictures =
        ref.watch(animePicturesProvider((id: detail.id, isAnime: isAnime)));
    return pictures.when(
      data: (urls) {
        if (urls.isEmpty) {
          return const Center(child: Text('No pictures available.'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: urls.length,
          itemBuilder: (_, i) => Entrance(
            index: i,
            child: GestureDetector(
              onTap: () => _openViewer(context, urls, i),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  urls[i],
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Container(
                          color: Theme.of(ctx)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                  errorBuilder: (_, _, _) => Container(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 32),
            const SizedBox(height: 8),
            const Text('Could not load pictures.'),
            TextButton(
              onPressed: () =>
                  ref.invalidate(
                      animePicturesProvider((id: detail.id, isAnime: isAnime))),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, List<String> urls, int index) {
    showDialog(
      context: context,
      builder: (ctx) => _PictureViewer(urls: urls, initialIndex: index),
    );
  }
}

/// Fullscreen swipeable picture viewer. Owns its [PageController] so it
/// is disposed when the dialog closes.
class _PictureViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _PictureViewer({required this.urls, required this.initialIndex});

  @override
  State<_PictureViewer> createState() => _PictureViewerState();
}

class _PictureViewerState extends State<_PictureViewer> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.urls.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.urls[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _RelatedTab extends StatelessWidget {
  final AnimeDetail detail;

  const _RelatedTab({required this.detail});

  @override
  Widget build(BuildContext context) {
    // Normalize to (anime, relation label) pairs. Recommendations
    // have no relation type.
    final List<({AnimeSummary anime, String? label})> items;
    if (detail.related.isNotEmpty) {
      items = [
        for (final r in detail.related)
          (anime: r.anime, label: r.relationLabel),
      ];
    } else {
      items = [for (final a in detail.recommendations) (anime: a, label: null)];
    }
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
        final a = items[i].anime;
        final label = items[i].label;
        return Stack(
          children: [
            PosterCard(
              imageUrl: a.imageUrl,
              title: a.title,
              mean: a.mean,
              width: double.infinity,
              onTap: () => context.push('/detail/anime/${a.id}'),
            ),
            if (label != null)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
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
                              ? Text(
                                  r.author.isEmpty
                                      ? '?'
                                      : r.author[0].toUpperCase(),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.author,
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                            horizontal: 10,
                            vertical: 4,
                          ),
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
                      style: textTheme.bodyMedium?.copyWith(height: 1.45),
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

final _reviewsProvider = FutureProvider.family<List<Review>, int>((ref, id) {
  return ref.watch(tenraiRepositoryProvider).animeReviews(id);
});

/// More Info tab: card-based detailed metadata like the classic app.
class _MoreInfoTab extends StatelessWidget {
  final AnimeDetail detail;
  final bool isAnime;

  const _MoreInfoTab({required this.detail, required this.isAnime});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget card(String label, String value, {int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget wideCard(String label, String value) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: textTheme.bodyMedium),
          ],
        ),
      );
    }

    Widget chipSection(String label, List<String> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(label, style: textTheme.titleSmall),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Chip(label: Text(item), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
      );
    }

    final aired = _airedRange(d);
    final broadcast = _broadcastLocal(d);
    final duration = d.avgEpisodeDuration != null
        ? '${(d.avgEpisodeDuration! / 60).round()}mins'
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'More Info',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            card('Media', _mediaType(d.mediaType) ?? '—'),
            const SizedBox(width: 8),
            card('Episodes', '${d.numEpisodes ?? '—'}'),
            const SizedBox(width: 8),
            card('Status', _prettyStatus(d.status), flex: 2),
            const SizedBox(width: 8),
            card('Premiered', _premiered(d), flex: 2),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (aired != null) card('Aired', aired, flex: 3),
            if (aired != null) const SizedBox(width: 8),
            card(
              'Source',
              d.source?.isNotEmpty == true ? _cap(d.source) : '—',
              flex: 2,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (broadcast != null) card('Broadcast', broadcast, flex: 3),
            if (broadcast != null) const SizedBox(width: 8),
            if (duration != null) card('Duration', duration, flex: 2),
            if (duration != null) const SizedBox(width: 8),
            card('Rating', _prettyRating(d.rating) ?? '—', flex: 2),
          ],
        ),
        if (d.synonyms.isNotEmpty) ...[
          const SizedBox(height: 8),
          wideCard('Synonyms', d.synonyms.join(', ')),
        ],
        if (_allTitles(d).isNotEmpty) ...[
          const SizedBox(height: 8),
          wideCard('Title', _allTitles(d)),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (d.studio != null)
              Expanded(child: chipSection('Studios', [d.studio!])),
            Expanded(child: chipSection('Genres', d.genres)),
          ],
        ),
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  String? _mediaType(String? t) => switch (t) {
    'tv' => 'TV',
    'ova' => 'OVA',
    'movie' => 'Movie',
    'special' => 'Special',
    'ona' => 'ONA',
    'music' => 'Music',
    _ => t == null ? null : _cap(t),
  };

  String _cap(String? s) =>
      s == null || s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  String _prettyStatus(String? s) => switch (s) {
    'currently_airing' => 'Currently airing',
    'finished_airing' => 'Finished airing',
    'not_yet_aired' => 'Not yet aired',
    _ => s ?? '—',
  };

  String _premiered(AnimeDetail d) {
    if (d.seasonYear != null) {
      return '${_cap(d.season)} ${d.seasonYear}';
    }
    return d.airedFrom?.substring(0, 4) ?? '—';
  }

  /// "2026-04-01 to 2026-06-24"
  String? _airedRange(AnimeDetail d) {
    final from = d.airedFrom;
    if (from == null) return null;
    final to = d.airedTo;
    return to != null ? '$from to $to' : from;
  }

  /// Broadcast time converted to local timezone, e.g. "8:30 PM Wed (WITA)".
  String? _broadcastLocal(AnimeDetail d) {
    final day = d.broadcastDay;
    final time = d.broadcastTime;
    if (day == null || time == null) return null;
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      // JST -> UTC -> local.
      final jst = DateTime.utc(2026, 1, 1, hour, minute);
      final local = jst.subtract(const Duration(hours: 9)).toLocal();
      final h = local.hour;
      final period = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      final m = local.minute.toString().padLeft(2, '0');
      final weekday = _shortDay(day);
      final tz = DateTime.now().timeZoneName;
      return '$h12:$m $period $weekday ($tz)';
    } catch (_) {
      return null;
    }
  }

  String _shortDay(String day) => switch (day.toLowerCase()) {
    'monday' || 'mondays' => 'Mon',
    'tuesday' || 'tuesdays' => 'Tue',
    'wednesday' || 'wednesdays' => 'Wed',
    'thursday' || 'thursdays' => 'Thu',
    'friday' || 'fridays' => 'Fri',
    'saturday' || 'saturdays' => 'Sat',
    'sunday' || 'sundays' => 'Sun',
    _ => day,
  };

  String? _prettyRating(String? r) => switch (r) {
    'g' => 'G',
    'pg' => 'PG',
    'pg_13' => 'PG 13',
    'r' => 'R',
    'r_plus' => 'R+',
    'rx' => 'Rx',
    _ => r,
  };

  /// All alternative titles combined.
  String _allTitles(AnimeDetail d) {
    final titles = <String>[d.title];
    if (d.titleEn != null && d.titleEn != d.title) {
      titles.add(d.titleEn!);
    }
    if (d.titleJa != null) titles.add(d.titleJa!);
    return titles.join(', ');
  }
}
