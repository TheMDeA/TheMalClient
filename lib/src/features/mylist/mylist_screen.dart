import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/core/theme/app_theme.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/features/mylist/filter_sheet.dart';
import 'package:malclient/src/features/mylist/list_filter.dart';
import 'package:malclient/src/widgets/poster_card.dart';
import 'package:malclient/src/widgets/section_widgets.dart';
import 'package:malclient/src/widgets/skeleton.dart';
import 'package:malclient/src/widgets/entrance.dart';

/// My List tab: Anime | Manga segmented control, status filter chips,
/// rows with progress steppers and an edit bottom sheet.
class MyListScreen extends ConsumerStatefulWidget {
  const MyListScreen({super.key});

  @override
  ConsumerState<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends ConsumerState<MyListScreen> {
  ListKind _kind = ListKind.anime;
  String? _status; // null = all
  String _searchQuery = '';
  final _searchController = TextEditingController();

  /// Single screen-level ticker keeping airing countdowns fresh (rows no
  /// longer run their own per-second timers).
  Timer? _ticker;

  /// Entry ids with a stepper update in flight (steppers disabled meanwhile).
  final _steppingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _statuses =>
      _kind == ListKind.anime ? AnimeListStatuses.all : MangaListStatuses.all;

  String _statusLabel(String s) => _kind == ListKind.anime
      ? AnimeListStatuses.label(s)
      : MangaListStatuses.label(s);

  List<AnimeListEntry> _applyAnimeFilterSort(
    List<AnimeListEntry> items,
    ListFilterState f,
  ) {
    var out = items;
    // Status chips filter locally — the list is fetched once (all statuses).
    if (_status != null) {
      out = out.where((e) => e.listStatus.status == _status).toList();
    }
    if (_searchQuery.isNotEmpty) {
      out = out
          .where((e) => e.anime.title.toLowerCase().contains(_searchQuery))
          .toList();
    }
    if (f.animeTypes.isNotEmpty) {
      out = out.where((e) => f.animeTypes.contains(e.anime.mediaType)).toList();
    }
    if (f.animeStatuses.isNotEmpty) {
      out = out.where((e) => f.animeStatuses.contains(e.anime.status)).toList();
    }
    if (f.ratings.isNotEmpty) {
      out = out.where((e) => f.ratings.contains(e.anime.rating)).toList();
    }
    if (f.genresInclude.isNotEmpty) {
      out = out
          .where((e) => f.genresInclude.any((g) => e.anime.genres.contains(g)))
          .toList();
    }
    if (f.genresExclude.isNotEmpty) {
      out = out
          .where((e) => !f.genresExclude.any((g) => e.anime.genres.contains(g)))
          .toList();
    }
    final sorted = List<AnimeListEntry>.of(out);
    sorted.sort((a, b) {
      final int cmp;
      switch (f.sortBy) {
        case 'title':
          cmp = a.anime.title.toLowerCase().compareTo(
            b.anime.title.toLowerCase(),
          );
        case 'list_score':
          cmp = a.listStatus.score.compareTo(b.listStatus.score);
        case 'start_date':
          cmp = (a.listStatus.startDate ?? '').compareTo(
            b.listStatus.startDate ?? '',
          );
        case 'popularity':
          cmp = (a.anime.popularity ?? 999999).compareTo(
            b.anime.popularity ?? 999999,
          );
        case 'list_users':
          cmp = (a.anime.numListUsers ?? 0).compareTo(
            b.anime.numListUsers ?? 0,
          );
        case 'scoring_users':
          cmp = (a.anime.numScoringUsers ?? 0).compareTo(
            b.anime.numScoringUsers ?? 0,
          );
        case 'score':
          cmp = (a.anime.mean ?? 0).compareTo(b.anime.mean ?? 0);
        case 'updated_at':
        default:
          cmp = (a.listStatus.updatedAt ?? '').compareTo(
            b.listStatus.updatedAt ?? '',
          );
      }
      return f.sortDesc ? -cmp : cmp;
    });
    return sorted;
  }

  List<MangaListEntry> _applyMangaFilterSort(
    List<MangaListEntry> items,
    ListFilterState f,
  ) {
    var out = items;
    // Status chips filter locally — the list is fetched once (all statuses).
    if (_status != null) {
      out = out.where((e) => e.listStatus.status == _status).toList();
    }
    if (_searchQuery.isNotEmpty) {
      out = out
          .where((e) => e.manga.title.toLowerCase().contains(_searchQuery))
          .toList();
    }
    if (f.mangaTypes.isNotEmpty) {
      out = out.where((e) => f.mangaTypes.contains(e.manga.mediaType)).toList();
    }
    if (f.mangaStatuses.isNotEmpty) {
      out = out.where((e) => f.mangaStatuses.contains(e.manga.status)).toList();
    }
    if (f.genresInclude.isNotEmpty) {
      out = out
          .where((e) => f.genresInclude.any((g) => e.manga.genres.contains(g)))
          .toList();
    }
    if (f.genresExclude.isNotEmpty) {
      out = out
          .where((e) => !f.genresExclude.any((g) => e.manga.genres.contains(g)))
          .toList();
    }
    final sorted = List<MangaListEntry>.of(out);
    sorted.sort((a, b) {
      final int cmp;
      switch (f.sortBy) {
        case 'title':
          cmp = a.manga.title.toLowerCase().compareTo(
            b.manga.title.toLowerCase(),
          );
        case 'list_score':
          cmp = a.listStatus.score.compareTo(b.listStatus.score);
        case 'start_date':
          cmp = (a.listStatus.startDate ?? '').compareTo(
            b.listStatus.startDate ?? '',
          );
        case 'popularity':
          cmp = (a.manga.popularity ?? 999999).compareTo(
            b.manga.popularity ?? 999999,
          );
        case 'list_users':
          cmp = (a.manga.numListUsers ?? 0).compareTo(
            b.manga.numListUsers ?? 0,
          );
        case 'scoring_users':
          cmp = (a.manga.numScoringUsers ?? 0).compareTo(
            b.manga.numScoringUsers ?? 0,
          );
        case 'score':
          cmp = (a.manga.mean ?? 0).compareTo(b.manga.mean ?? 0);
        case 'updated_at':
        default:
          cmp = (a.listStatus.updatedAt ?? '').compareTo(
            b.listStatus.updatedAt ?? '',
          );
      }
      return f.sortDesc ? -cmp : cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    'My List',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Consumer(
                    builder: (context, ref, _) {
                      final f = ref.watch(listFilterProvider);
                      final active = f.hasActiveFilters || !f.isDefaultSort;
                      return IconButton(
                        icon: Badge(
                          isLabelVisible: active,
                          child: const Icon(Icons.filter_list),
                        ),
                        tooltip: 'Sort & filter',
                        onPressed: () =>
                            showListFilterSheet(context, ref, kind: _kind),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search your list…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ListKind>(
                segments: const [
                  ButtonSegment(
                    value: ListKind.anime,
                    label: Text('Anime'),
                    icon: Icon(Icons.movie_outlined),
                  ),
                  ButtonSegment(
                    value: ListKind.manga,
                    label: Text('Manga'),
                    icon: Icon(Icons.menu_book_outlined),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _kind = s.first;
                    _status = null;
                  });
                },
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statuses.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Center(
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _status == null,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _status = null);
                        },
                      ),
                    );
                  }
                  final s = _statuses[i - 1];
                  return Center(
                    child: FilterChip(
                      label: Text(_statusLabel(s)),
                      selected: _status == s,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _status = _status == s ? null : s);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _kind == ListKind.anime ? _animeList() : _mangaList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animeList() {
    final value = ref.watch(myAnimeListProvider);
    final filter = ref.watch(listFilterProvider);
    return value.when(
      data: (items) {
        final shown = _applyAnimeFilterSort(items, filter);
        if (shown.isEmpty) {
          return const Center(child: Text('No entries match.'));
        }
        return RefreshIndicator(
          onRefresh: () async => invalidateMyLists(ref),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final e = shown[i];
              return Entrance(
                index: i,
                child: _ListRow(
                  id: e.anime.id,
                  kind: 'anime',
                  imageUrl: e.anime.imageUrl,
                  title: e.anime.title,
                  mean: e.anime.mean,
                  numListUsers: e.anime.numListUsers,
                  listStatus: e.listStatus,
                  mediaType: e.anime.mediaType,
                  total: e.anime.numEpisodes,
                  unit: 'ep',
                  genres: e.anime.genres,
                  isAiring: e.anime.isAiring,
                  broadcastDay: e.anime.broadcastDay,
                  broadcastTime: e.anime.broadcastTime,
                  airedFrom: e.anime.airedFrom,
                  compact: filter.compactRows,
                  stepping: _steppingIds.contains(e.anime.id),
                  onTap: () => context.push('/detail/anime/${e.anime.id}'),
                  onEdit: () => showEditEntrySheet(
                    context,
                    ref,
                    kind: ListKind.anime,
                    id: e.anime.id,
                    title: e.anime.title,
                    status: e.listStatus,
                    total: e.anime.numEpisodes,
                  ),
                  onStep: (delta) => _stepAnime(e, delta),
                ),
              );
            },
          ),
        );
      },
      loading: () => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const SkeletonListRow(),
      ),
      error: (e, _) =>
          AsyncSection.error(error: e, onRetry: () => invalidateMyLists(ref)),
    );
  }

  Widget _mangaList() {
    final value = ref.watch(myMangaListProvider);
    final filter = ref.watch(listFilterProvider);
    return value.when(
      data: (items) {
        final shown = _applyMangaFilterSort(items, filter);
        if (shown.isEmpty) {
          return const Center(child: Text('No entries match.'));
        }
        return RefreshIndicator(
          onRefresh: () async => invalidateMyLists(ref),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: shown.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final e = shown[i];
              return Entrance(
                index: i,
                child: _ListRow(
                  id: e.manga.id,
                  kind: 'manga',
                  imageUrl: e.manga.imageUrl,
                  title: e.manga.title,
                  mean: e.manga.mean,
                  numListUsers: e.manga.numListUsers,
                  listStatus: e.listStatus,
                  mediaType: e.manga.mediaType,
                  total: e.manga.numChapters,
                  unit: 'ch',
                  genres: e.manga.genres,
                  isAiring: false,
                  broadcastDay: null,
                  broadcastTime: null,
                  airedFrom: null,
                  compact: filter.compactRows,
                  stepping: _steppingIds.contains(e.manga.id),
                  onTap: () => context.push('/detail/manga/${e.manga.id}'),
                  onEdit: () => showEditEntrySheet(
                    context,
                    ref,
                    kind: ListKind.manga,
                    id: e.manga.id,
                    title: e.manga.title,
                    status: e.listStatus,
                    total: e.manga.numChapters,
                  ),
                  onStep: (delta) => _stepManga(e, delta),
                ),
              );
            },
          ),
        );
      },
      loading: () => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const SkeletonListRow(),
      ),
      error: (e, _) =>
          AsyncSection.error(error: e, onRetry: () => invalidateMyLists(ref)),
    );
  }

  /// Optimistic stepper: patches the cached list instantly (no refetch, no
  /// skeleton flash), then persists in the background. Rolls back on failure.
  /// The buttons are disabled while an update for the entry is in flight so
  /// rapid taps can't interleave stale values.
  Future<void> _stepAnime(AnimeListEntry e, int delta) async {
    final id = e.anime.id;
    if (_steppingIds.contains(id)) return;
    final t = e.anime.numEpisodes;
    final max = (t != null && t > 0) ? t : 1 << 30;
    final next = (e.listStatus.progress + delta).clamp(0, max);
    if (next == e.listStatus.progress) return; // At the boundary: nothing to do.
    setState(() => _steppingIds.add(id));
    final ok =
        await ref.read(myAnimeListProvider.notifier).stepProgress(id, next);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed. Please try again.')),
      );
    }
    if (mounted) setState(() => _steppingIds.remove(id));
  }

  Future<void> _stepManga(MangaListEntry e, int delta) async {
    final id = e.manga.id;
    if (_steppingIds.contains(id)) return;
    final t = e.manga.numChapters;
    final max = (t != null && t > 0) ? t : 1 << 30;
    final next = (e.listStatus.progress + delta).clamp(0, max);
    if (next == e.listStatus.progress) return; // At the boundary: nothing to do.
    setState(() => _steppingIds.add(id));
    final ok =
        await ref.read(myMangaListProvider.notifier).stepProgress(id, next);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update failed. Please try again.')),
      );
    }
    if (mounted) setState(() => _steppingIds.remove(id));
  }
}

class _ListRow extends StatelessWidget {
  final int id;
  final String kind; // 'anime' or 'manga'
  final String? imageUrl;
  final String title;
  final double? mean;
  final int? numListUsers;
  final MyListStatus listStatus;
  final String? mediaType;
  final int? total;
  final String unit;
  final List<String> genres;
  final bool isAiring;
  final String? broadcastDay;
  final String? broadcastTime;
  final String? airedFrom;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final void Function(int delta) onStep;
  final bool compact;

  /// True while a stepper update for this entry is in flight.
  final bool stepping;

  const _ListRow({
    required this.id,
    required this.kind,
    required this.imageUrl,
    required this.title,
    required this.mean,
    required this.numListUsers,
    required this.listStatus,
    required this.mediaType,
    required this.total,
    required this.unit,
    required this.genres,
    required this.isAiring,
    required this.broadcastDay,
    required this.broadcastTime,
    required this.airedFrom,
    required this.onTap,
    required this.onEdit,
    required this.onStep,
    this.compact = false,
    this.stepping = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ls = listStatus;
    final progress = ls.progress;

    return Card.filled(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 6 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterImage(
                url: imageUrl,
                title: title,
                width: compact ? 36 : 64,
                height: compact ? 52 : 92,
                heroTag: 'poster-$kind-$id',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: MAL score + status badge ... user score.
                    Row(
                      children: [
                        if (mean != null) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            mean!.toStringAsFixed(
                              mean! >= 10 ? 0 : 2,
                            ),
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (numListUsers != null)
                            Text(
                              ' (${_compactNum(numListUsers!)})',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(width: 6),
                        ],
                        _StatusBadge(status: ls.status),
                        const Spacer(),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          '${ls.score}',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Airing countdown (minute precision; the screen-level
                    // ticker refreshes it, so rows need no timers).
                    if (isAiring)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _airingLine(),
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 2),
                    // Media info + genres.
                    Text(
                      _mediaLine(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$progress $unit',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _StepButton(
                          icon: Icons.add,
                          onTap: stepping
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  onStep(1);
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: onEdit,
                          tooltip: 'Edit entry',
                          visualDensity: VisualDensity.compact,
                        ),
                        _StepButton(
                          icon: Icons.remove,
                          onTap: stepping
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  onStep(-1);
                                },
                        ),
                      ],
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

  /// "TV (64 eps) · Action, Adventure, Drama"
  String _mediaLine() {
    final parts = <String>[];
    final type = _prettyMediaType(mediaType);
    if (type != null) {
      parts.add(
        total != null && total! > 0
            ? '$type ($total $unit'
            : type,
      );
    }
    if (genres.isNotEmpty) {
      parts.add(genres.take(3).join(', '));
    }
    return parts.join(' · ');
  }

  /// "Ep 3 · 3d 3h 39m 56s"
  String _airingLine() {
    final ep = _currentEpisode();
    final countdown = _countdown();
    if (ep != null && countdown != null) return 'Ep $ep · $countdown';
    if (countdown != null) return countdown;
    return 'Currently airing';
  }

  int? _currentEpisode() {
    final start = airedFrom;
    if (start == null || start.length < 10) return null;
    try {
      final startDate = DateTime.parse(start.substring(0, 10));
      final now = DateTime.now();
      if (now.isBefore(startDate)) return null;
      final weeks = now.difference(startDate).inDays ~/ 7;
      var ep = weeks + 1;
      final t = total;
      if (t != null && t > 0 && ep > t) ep = t;
      return ep > 0 ? ep : null;
    } catch (_) {
      return null;
    }
  }

  String? _countdown() {
    final next = _nextAirDate();
    if (next == null) return null;
    final diff = next.difference(DateTime.now());
    if (diff.isNegative) return null;
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  DateTime? _nextAirDate() {
    final day = broadcastDay;
    final time = broadcastTime;
    if (day == null || time == null) return null;
    final weekday = _weekday(day);
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || weekday == null) return null;
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

  String? _prettyMediaType(String? t) => switch (t) {
    'tv' => 'TV',
    'ova' => 'OVA',
    'movie' => 'Movie',
    'special' => 'Special',
    'ona' => 'ONA',
    'music' => 'Music',
    'manga' => 'Manga',
    'novel' => 'Novel',
    'one_shot' => 'One-shot',
    'doujinshi' => 'Doujinshi',
    'manhwa' => 'Manhwa',
    'manhua' => 'Manhua',
    _ => t,
  };

  String _compactNum(int n) {
    if (n >= 1000000) {
      final v = n / 1000000;
      return '${v.toStringAsFixed(v >= 10 ? 0 : 2).replaceAll(RegExp(r'\.?0+$'), '')}M';
    }
    if (n >= 1000) {
      final v = n / 1000;
      return '${v.toStringAsFixed(v >= 100 ? 0 : 1).replaceAll(RegExp(r'\.?0+$'), '')}K';
    }
    return '$n';
  }
}

/// Colored status pill: CW / C / OH / D / PTW.
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final (label, color) = switch (status) {
      'watching' || 'reading' => ('CW', statusColorFor(brightness, status)),
      'completed' => ('C', statusColorFor(brightness, status)),
      'on_hold' => ('OH', statusColorFor(brightness, status)),
      'dropped' => ('D', statusColorFor(brightness, status)),
      'plan_to_watch' || 'plan_to_read' =>
        ('PTW', statusColorFor(brightness, status)),
      _ => ('?', statusColorFor(brightness, status)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Bottom sheet to edit a list entry: status, score, progress, delete.
Future<void> showEditEntrySheet(
  BuildContext context,
  WidgetRef ref, {
  required ListKind kind,
  required int id,
  required String title,
  required MyListStatus status,
  required int? total,
  bool isNew = false,
  VoidCallback? onSaved,
}) {
  final isAnime = kind == ListKind.anime;
  final statuses = isAnime ? AnimeListStatuses.all : MangaListStatuses.all;
  String statusLabel(String s) =>
      isAnime ? AnimeListStatuses.label(s) : MangaListStatuses.label(s);
  final rewatchNoun = isAnime ? 'Rewatch' : 'Reread';
  final progressNoun = isAnime ? 'Episodes' : 'Chapters';
  final originalStatus = status.status;

  var newStatus = status.status;
  var newScore = status.score;
  var newProgress = status.progress;
  var newRewatching = status.isRewatching;
  var newTimesRewatched = status.timesRewatched;
  var newRewatchValue = status.rewatchValue;
  var newStartDate = status.startDate;
  var newFinishDate = status.finishDate;
  var newPriority = status.priority;
  final commentsCtrl = TextEditingController(text: status.comments);

  const rewatchLabels = ['—', 'Very Low', 'Low', 'Medium', 'High', 'Very High'];
  const priorityLabels = ['Low', 'Medium', 'High'];

  String fmtDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return 'Select';
    final dt = DateTime.tryParse(ymd);
    if (dt == null) return ymd;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        Future<void> save() async {
          try {
            // Apply start/end date auto-setters from Settings.
            final autoSet = ref.read(dateAutoSetProvider);
            final now = DateTime.now();
            final today =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            // When "allow override" is on, a manually chosen date is never
            // overwritten — the auto-setter only fills empty dates.
            String? autoDate(String? current) {
              if (autoSet.allowOverride &&
                  current != null &&
                  current.isNotEmpty) {
                return current;
              }
              return today;
            }

            final watchingStatus = isAnime
                ? AnimeListStatuses.watching
                : MangaListStatuses.reading;
            final statusChanged = newStatus != originalStatus;

            if (isNew && autoSet.startOnAdd) {
              newStartDate = autoDate(newStartDate);
            }
            if (statusChanged &&
                newStatus == watchingStatus &&
                autoSet.startOnWatching) {
              newStartDate = autoDate(newStartDate);
            }
            if (statusChanged &&
                newStatus == 'completed' &&
                autoSet.endOnCompleted) {
              newFinishDate = autoDate(newFinishDate);
            }
            if (statusChanged &&
                newStatus == 'dropped' &&
                autoSet.endOnDropped) {
              newFinishDate = autoDate(newFinishDate);
            }

            final repo = ref.read(listRepositoryProvider);
            if (isAnime) {
              await repo.updateAnimeEntry(
                id,
                status: newStatus,
                score: newScore,
                numWatchedEpisodes: newProgress,
                isRewatching: newRewatching,
                numTimesRewatched: newTimesRewatched,
                rewatchValue: newRewatchValue,
                priority: newPriority,
                comments: commentsCtrl.text,
                startDate: newStartDate,
                finishDate: newFinishDate,
              );
            } else {
              await repo.updateMangaEntry(
                id,
                status: newStatus,
                score: newScore,
                numReadChapters: newProgress,
                isRereading: newRewatching,
                numTimesReread: newTimesRewatched,
                rereadValue: newRewatchValue,
                priority: newPriority,
                comments: commentsCtrl.text,
                startDate: newStartDate,
                finishDate: newFinishDate,
              );
            }
            invalidateMyLists(ref);
            onSaved?.call();
            if (context.mounted) Navigator.of(context).pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Save failed: $e')));
            }
          }
        }

        Future<void> pickDate(bool isStart) async {
          final cur = isStart ? newStartDate : newFinishDate;
          final initial = DateTime.tryParse(cur ?? '') ?? DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: initial,
            firstDate: DateTime(1970),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            final ymd =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            setSheetState(() {
              if (isStart) {
                newStartDate = ymd;
              } else {
                newFinishDate = ymd;
              }
            });
          }
        }

        Widget pill({
          required String label,
          required bool selected,
          required VoidCallback onTap,
        }) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) => onTap(),
              showCheckmark: false,
              selectedColor: scheme.primaryContainer,
              labelStyle: TextStyle(
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }

        Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        );

        // Episode/chapter pills: window around current value.
        final epStart = (newProgress - 4).clamp(0, 1 << 30);
        final epEnd = (total != null && total > 0) ? total : newProgress + 8;
        // Progress can never exceed the known total; reaching it completes
        // the entry.
        final maxProgress = (total != null && total > 0) ? total : (1 << 30);
        void setProgress(int n) {
          newProgress = n.clamp(0, maxProgress);
          if (total != null &&
              total > 0 &&
              newProgress >= total &&
              newStatus != 'completed') {
            newStatus = 'completed';
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // ---------- Your List Status ----------
                  Text(
                    'Your List Status',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  sectionTitle('Status'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in statuses)
                          pill(
                            label: statusLabel(s),
                            selected: newStatus == s,
                            onTap: () => setSheetState(() => newStatus = s),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '$progressNoun Seen',
                        style: theme.textTheme.labelLarge,
                      ),
                      const Spacer(),
                      _StepButton(
                        icon: Icons.remove,
                        onTap: () =>
                            setSheetState(() => setProgress(newProgress - 1)),
                      ),
                      _StepButton(
                        icon: Icons.add,
                        onTap: () =>
                            setSheetState(() => setProgress(newProgress + 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: (epEnd - epStart).clamp(0, 500),
                      itemBuilder: (context, i) {
                        final n = epStart + i;
                        return pill(
                          label: '$n',
                          selected: n == newProgress,
                          onTap: () => setSheetState(() => setProgress(n)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  sectionTitle('Score · Select a rating'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var s = 0; s <= 10; s++)
                          pill(
                            label: s == 0 ? '—' : '$s',
                            selected: newScore == s,
                            onTap: () => setSheetState(() => newScore = s),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ---------- Rewatch Status ----------
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      '$rewatchNoun Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$rewatchNoun ing',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Switch(
                                  value: newRewatching,
                                  onChanged: (v) =>
                                      setSheetState(() => newRewatching = v),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Times $rewatchNoun ed',
                                  style: theme.textTheme.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StepButton(
                                      icon: Icons.remove,
                                      onTap: () => setSheetState(
                                        () => newTimesRewatched =
                                            (newTimesRewatched - 1).clamp(
                                              0,
                                              1 << 30,
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text(
                                        '$newTimesRewatched',
                                        style: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    _StepButton(
                                      icon: Icons.add,
                                      onTap: () => setSheetState(
                                        () => newTimesRewatched =
                                            (newTimesRewatched + 1).clamp(
                                              0,
                                              1 << 30,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      sectionTitle('$rewatchNoun Value'),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var v = 0; v <= 5; v++)
                              pill(
                                label: rewatchLabels[v],
                                selected: newRewatchValue == v,
                                onTap: () =>
                                    setSheetState(() => newRewatchValue = v),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),

                  // ---------- Dates & Priority ----------
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Dates & Priority',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                sectionTitle('Start Date'),
                                OutlinedButton.icon(
                                  onPressed: () => pickDate(true),
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                  ),
                                  label: Text(fmtDate(newStartDate)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                sectionTitle('Finish Date'),
                                OutlinedButton.icon(
                                  onPressed: () => pickDate(false),
                                  icon: const Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                  ),
                                  label: Text(fmtDate(newFinishDate)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                sectionTitle('Priority'),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (var pr = 0; pr <= 2; pr++)
                                        pill(
                                          label: priorityLabels[pr],
                                          selected: newPriority == pr,
                                          onTap: () => setSheetState(
                                            () => newPriority = pr,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),

                  // ---------- Others ----------
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Others',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      sectionTitle('Comments'),
                      TextField(
                        controller: commentsCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Type comments here..',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final repo = ref.read(listRepositoryProvider);
                            try {
                              if (isAnime) {
                                await repo.deleteAnimeEntry(id);
                              } else {
                                await repo.deleteMangaEntry(id);
                              }
                              invalidateMyLists(ref);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Delete failed: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: save,
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
