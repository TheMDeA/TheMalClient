import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/widgets/poster_card.dart';
import 'package:malclient/src/widgets/section_widgets.dart';

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

  List<String> get _statuses => _kind == ListKind.anime
      ? AnimeListStatuses.all
      : MangaListStatuses.all;

  String _statusLabel(String s) => _kind == ListKind.anime
      ? AnimeListStatuses.label(s)
      : MangaListStatuses.label(s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'My List',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                onSelectionChanged: (s) => setState(() {
                  _kind = s.first;
                  _status = null;
                }),
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
                        onSelected: (_) => setState(() => _status = null),
                      ),
                    );
                  }
                  final s = _statuses[i - 1];
                  return Center(
                    child: FilterChip(
                      label: Text(_statusLabel(s)),
                      selected: _status == s,
                      onSelected: (_) =>
                          setState(() => _status = _status == s ? null : s),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _kind == ListKind.anime
                  ? _animeList()
                  : _mangaList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animeList() {
    final value = ref.watch(myAnimeListProvider(_status));
    return value.when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No entries.'));
        return RefreshIndicator(
          onRefresh: () async => invalidateMyLists(ref),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final e = items[i];
              return _ListRow(
                imageUrl: e.anime.imageUrl,
                title: e.anime.title,
                subtitle:
                    '${_statusLabel(e.listStatus.status)} · Score ${e.listStatus.score}',
                progress: e.listStatus.progress,
                total: e.anime.numEpisodes,
                unit: 'ep',
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
              );
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

  Widget _mangaList() {
    final value = ref.watch(myMangaListProvider(_status));
    return value.when(
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('No entries.'));
        return RefreshIndicator(
          onRefresh: () async => invalidateMyLists(ref),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final e = items[i];
              return _ListRow(
                imageUrl: e.manga.imageUrl,
                title: e.manga.title,
                subtitle:
                    '${_statusLabel(e.listStatus.status)} · Score ${e.listStatus.score}',
                progress: e.listStatus.progress,
                total: e.manga.numChapters,
                unit: 'ch',
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
              );
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

  Future<void> _stepAnime(AnimeListEntry e, int delta) async {
    final next = (e.listStatus.progress + delta).clamp(0, 1 << 30);
    try {
      await ref
          .read(listRepositoryProvider)
          .updateAnimeEntry(e.anime.id, numWatchedEpisodes: next);
      invalidateMyLists(ref);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $err')));
      }
    }
  }

  Future<void> _stepManga(MangaListEntry e, int delta) async {
    final next = (e.listStatus.progress + delta).clamp(0, 1 << 30);
    try {
      await ref
          .read(listRepositoryProvider)
          .updateMangaEntry(e.manga.id, numReadChapters: next);
      invalidateMyLists(ref);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Update failed: $err')));
      }
    }
  }
}

class _ListRow extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String subtitle;
  final int progress;
  final int? total;
  final String unit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final void Function(int delta) onStep;

  const _ListRow({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.total,
    required this.unit,
    required this.onTap,
    required this.onEdit,
    required this.onStep,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card.filled(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              PosterImage(url: imageUrl, title: title, width: 52, height: 76),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _StepButton(
                          icon: Icons.remove,
                          onTap: () => onStep(-1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            total != null && total! > 0
                                ? '$progress / $total $unit'
                                : '$progress $unit',
                            style: textTheme.labelLarge,
                          ),
                        ),
                        _StepButton(
                          icon: Icons.add,
                          onTap: () => onStep(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                tooltip: 'Edit entry',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primaryContainer,
        ),
        child: Icon(icon, size: 18, color: scheme.onPrimaryContainer),
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
}) {
  final statuses =
      kind == ListKind.anime ? AnimeListStatuses.all : MangaListStatuses.all;
  String statusLabel(String s) => kind == ListKind.anime
      ? AnimeListStatuses.label(s)
      : MangaListStatuses.label(s);

  var newStatus = status.status;
  var newScore = status.score;
  var newProgress = status.progress;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final scheme = Theme.of(context).colorScheme;
        Future<void> save() async {
          try {
            final repo = ref.read(listRepositoryProvider);
            if (kind == ListKind.anime) {
              await repo.updateAnimeEntry(
                id,
                status: newStatus,
                score: newScore,
                numWatchedEpisodes: newProgress,
              );
            } else {
              await repo.updateMangaEntry(
                id,
                status: newStatus,
                score: newScore,
                numReadChapters: newProgress,
              );
            }
            invalidateMyLists(ref);
            if (context.mounted) Navigator.of(context).pop();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('Save failed: $e')));
            }
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text('Status', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: statuses.contains(newStatus)
                    ? newStatus
                    : statuses.first,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  for (final s in statuses)
                    DropdownMenuItem(value: s, child: Text(statusLabel(s))),
                ],
                onChanged: (v) =>
                    setSheetState(() => newStatus = v ?? newStatus),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Score',
                      style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$newScore',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: newScore.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: '$newScore',
                onChanged: (v) =>
                    setSheetState(() => newScore = v.round()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    kind == ListKind.anime ? 'Episodes watched' : 'Chapters read',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  _StepButton(
                    icon: Icons.remove,
                    onTap: () => setSheetState(
                        () => newProgress = (newProgress - 1).clamp(0, 1 << 30)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      total != null && total > 0
                          ? '$newProgress / $total'
                          : '$newProgress',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add,
                    onTap: () => setSheetState(
                        () => newProgress = (newProgress + 1).clamp(0, 1 << 30)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final repo = ref.read(listRepositoryProvider);
                        try {
                          if (kind == ListKind.anime) {
                            await repo.deleteAnimeEntry(id);
                          } else {
                            await repo.deleteMangaEntry(id);
                          }
                          invalidateMyLists(ref);
                          if (context.mounted) Navigator.of(context).pop();
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
        );
      },
    ),
  );
}
