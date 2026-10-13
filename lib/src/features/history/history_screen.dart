import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/widgets/poster_card.dart';
import 'package:malclient/src/widgets/section_widgets.dart';

/// History tab: recently updated list entries, grouped by date.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Anime'),
              Tab(text: 'Manga'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HistoryTab(kind: ListKind.anime),
            _HistoryTab(kind: ListKind.manga),
          ],
        ),
      ),
    );
  }
}

/// Flat view model shared by anime and manga entries.
class _HistoryItem {
  final int id;
  final String title;
  final String? imageUrl;
  final String detail;
  final DateTime? updatedAt;
  final ListKind kind;

  const _HistoryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.detail,
    required this.updatedAt,
    required this.kind,
  });
}

class _HistoryTab extends ConsumerWidget {
  final ListKind kind;

  const _HistoryTab({required this.kind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = kind == ListKind.anime
        ? ref.watch(myAnimeListProvider)
        : ref.watch(myMangaListProvider);

    return value.when(
      data: (items) {
        final shown = _buildItems(items);
        if (shown.isEmpty) {
          return const Center(child: Text('No history yet.'));
        }
        final groups = _groupItems(shown);
        return RefreshIndicator(
          onRefresh: () async => invalidateMyLists(ref),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: groups.fold<int>(
                0, (sum, g) => sum + 1 + g.items.length),
            itemBuilder: (_, index) {
              var remaining = index;
              for (final g in groups) {
                if (remaining == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                    child: Text(
                      g.header,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  );
                }
                remaining -= 1;
                if (remaining < g.items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryRow(item: g.items[remaining]),
                  );
                }
                remaining -= g.items.length;
              }
              return const SizedBox.shrink();
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AsyncSection.error(
        error: e,
        onRetry: () => invalidateMyLists(ref),
      ),
    );
  }

  List<_HistoryItem> _buildItems(List<dynamic> items) {
    final out = <_HistoryItem>[];
    for (final e in items) {
      if (e is AnimeListEntry) {
        final s = e.listStatus;
        out.add(_HistoryItem(
          id: e.anime.id,
          title: e.anime.title,
          imageUrl: e.anime.imageUrl,
          detail: '${AnimeListStatuses.label(s.status)}'
              ' · Score ${s.score}'
              ' · ${s.progress}/${e.anime.numEpisodes ?? '?'} eps',
          updatedAt: _parseDate(s.updatedAt),
          kind: ListKind.anime,
        ));
      } else if (e is MangaListEntry) {
        final s = e.listStatus;
        out.add(_HistoryItem(
          id: e.manga.id,
          title: e.manga.title,
          imageUrl: e.manga.imageUrl,
          detail: '${MangaListStatuses.label(s.status)}'
              ' · Score ${s.score}'
              ' · ${s.progress}/${e.manga.numChapters ?? '?'} ch',
          updatedAt: _parseDate(s.updatedAt),
          kind: ListKind.manga,
        ));
      }
    }
    // Most recent first; entries without a date go last.
    out.sort((a, b) {
      if (a.updatedAt == null && b.updatedAt == null) return 0;
      if (a.updatedAt == null) return 1;
      if (b.updatedAt == null) return -1;
      return b.updatedAt!.compareTo(a.updatedAt!);
    });
    return out;
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  List<_Group> _groupItems(List<_HistoryItem> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <String, List<_HistoryItem>>{};
    final order = <String>[];

    for (final item in items) {
      final dt = item.updatedAt;
      final String header;
      if (dt == null) {
        header = 'Earlier';
      } else {
        final day = DateTime(dt.year, dt.month, dt.day);
        final diff = today.difference(day).inDays;
        if (diff <= 0) {
          header = 'Today';
        } else if (diff == 1) {
          header = 'Yesterday';
        } else if (diff < 7) {
          header = 'This week';
        } else if (dt.year == now.year && dt.month == now.month) {
          header = 'Earlier this month';
        } else {
          header = '${_monthName(dt.month)} ${dt.year}';
        }
      }
      groups.putIfAbsent(header, () {
        order.add(header);
        return [];
      });
      groups[header]!.add(item);
    }
    return [for (final h in order) _Group(h, groups[h]!)];
  }

  String _monthName(int m) => switch (m) {
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        _ => 'December',
      };
}

class _Group {
  final String header;
  final List<_HistoryItem> items;
  const _Group(this.header, this.items);
}

class _HistoryRow extends StatelessWidget {
  final _HistoryItem item;

  const _HistoryRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card.filled(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/detail/${item.kind == ListKind.anime ? 'anime' : 'manga'}/${item.id}',
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PosterImage(
                  url: item.imageUrl,
                  title: item.title,
                  width: 52,
                  height: 76),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.detail,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(item.updatedAt),
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
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

  String _relativeTime(DateTime? dt) {
    if (dt == null) return 'Unknown date';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) {
      return diff.inDays == 1 ? 'Yesterday' : '${diff.inDays} days ago';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final label = '${months[dt.month - 1]} ${dt.day}';
    return dt.year == DateTime.now().year ? label : '$label, ${dt.year}';
  }
}
