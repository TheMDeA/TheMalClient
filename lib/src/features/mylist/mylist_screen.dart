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
  bool isNew = false,
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
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
        final epEnd =
            (total != null && total > 0) ? total : newProgress + 8;

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
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // ---------- Your List Status ----------
                  Text(
                    'Your List Status',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                            onTap: () =>
                                setSheetState(() => newStatus = s),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('$progressNoun Seen',
                          style: theme.textTheme.labelLarge),
                      const Spacer(),
                      _StepButton(
                        icon: Icons.remove,
                        onTap: () => setSheetState(() => newProgress =
                            (newProgress - 1).clamp(0, 1 << 30)),
                      ),
                      _StepButton(
                        icon: Icons.add,
                        onTap: () => setSheetState(() => newProgress =
                            (newProgress + 1).clamp(0, 1 << 30)),
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
                          onTap: () =>
                              setSheetState(() => newProgress = n),
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
                            onTap: () =>
                                setSheetState(() => newScore = s),
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
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('$rewatchNoun ing',
                                    style: theme.textTheme.labelLarge),
                                const SizedBox(height: 4),
                                Switch(
                                  value: newRewatching,
                                  onChanged: (v) => setSheetState(
                                      () => newRewatching = v),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Times $rewatchNoun ed',
                                    style: theme.textTheme.labelLarge),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StepButton(
                                      icon: Icons.remove,
                                      onTap: () => setSheetState(() =>
                                          newTimesRewatched =
                                              (newTimesRewatched - 1)
                                                  .clamp(0, 1 << 30)),
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8),
                                      child: Text('$newTimesRewatched',
                                          style: theme
                                              .textTheme.titleMedium),
                                    ),
                                    _StepButton(
                                      icon: Icons.add,
                                      onTap: () => setSheetState(() =>
                                          newTimesRewatched =
                                              (newTimesRewatched + 1)
                                                  .clamp(0, 1 << 30)),
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
                                onTap: () => setSheetState(
                                    () => newRewatchValue = v),
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
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                sectionTitle('Start Date'),
                                OutlinedButton.icon(
                                  onPressed: () => pickDate(true),
                                  icon: const Icon(
                                      Icons.calendar_today,
                                      size: 16),
                                  label: Text(fmtDate(newStartDate)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                sectionTitle('Finish Date'),
                                OutlinedButton.icon(
                                  onPressed: () => pickDate(false),
                                  icon: const Icon(
                                      Icons.calendar_today,
                                      size: 16),
                                  label: Text(fmtDate(newFinishDate)),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                sectionTitle('Priority'),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      for (var pr = 0;
                                          pr <= 2;
                                          pr++)
                                        pill(
                                          label: priorityLabels[pr],
                                          selected:
                                              newPriority == pr,
                                          onTap: () => setSheetState(
                                              () =>
                                                  newPriority = pr),
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
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                            final repo =
                                ref.read(listRepositoryProvider);
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
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        content: Text(
                                            'Delete failed: $e')));
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
