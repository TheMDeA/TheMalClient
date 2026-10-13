import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malclient/src/core/mal_genres.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/features/mylist/list_filter.dart';

/// Sort / Filter / Display bottom sheet for the My List tab.
///
/// Edits a draft copy of [ListFilterState]; Save applies it, Reset clears
/// it, Close discards changes.
Future<void> showListFilterSheet(
  BuildContext context,
  WidgetRef ref, {
  required ListKind kind,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _FilterSheet(kind: kind),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  final ListKind kind;
  const _FilterSheet({required this.kind});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ListFilterState _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(listFilterProvider);
  }

  bool get _isAnime => widget.kind == ListKind.anime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Padding(
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
              TabBar(
                tabs: const [
                  Tab(text: 'Sort'),
                  Tab(text: 'Filter'),
                  Tab(text: 'Display'),
                ],
                labelColor: scheme.primary,
                unselectedLabelColor: scheme.onSurfaceVariant,
                indicatorColor: scheme.primary,
              ),
              Flexible(
                child: TabBarView(
                  children: [
                    _sortTab(context),
                    _filterTab(context),
                    _displayTab(context),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _draft = const ListFilterState();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(listFilterProvider.notifier)
                            .update(_draft);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Sort ----------------

  Widget _sortTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final (value, label) in ListFilterState.sortOptions)
          ListTile(
            title: Text(label),
            trailing: _draft.sortBy == value
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _draft.sortDesc ? 'desc' : 'asc',
                          style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _draft.sortDesc
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 16,
                          color: scheme.onPrimaryContainer,
                        ),
                      ],
                    ),
                  )
                : null,
            selected: _draft.sortBy == value,
            selectedColor: scheme.primary,
            onTap: () {
              setState(() {
                if (_draft.sortBy == value) {
                  _draft =
                      _draft.copyWith(sortDesc: !_draft.sortDesc);
                } else {
                  // Sensible defaults: title and popularity ascending
                  // (rank 1 = most popular), everything else descending.
                  final desc =
                      value != 'title' && value != 'popularity';
                  _draft =
                      _draft.copyWith(sortBy: value, sortDesc: desc);
                }
              });
            },
          ),
      ],
    );
  }

  // ---------------- Filter ----------------

  Widget _filterTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        if (_isAnime) ...[
          _filterSection(
            context,
            title: 'Anime Type',
            options: ListFilterState.animeTypeOptions,
            selected: _draft.animeTypes,
            onToggle: (v) {
              final s = Set<String>.of(_draft.animeTypes);
              s.contains(v) ? s.remove(v) : s.add(v);
              setState(() => _draft = _draft.copyWith(animeTypes: s));
            },
          ),
          _filterSection(
            context,
            title: 'Anime Status',
            options: ListFilterState.animeStatusOptions,
            selected: _draft.animeStatuses,
            onToggle: (v) {
              final s = Set<String>.of(_draft.animeStatuses);
              s.contains(v) ? s.remove(v) : s.add(v);
              setState(
                  () => _draft = _draft.copyWith(animeStatuses: s));
            },
          ),
          _filterSection(
            context,
            title: 'Rated',
            options: ListFilterState.ratingOptions,
            selected: _draft.ratings,
            onToggle: (v) {
              final s = Set<String>.of(_draft.ratings);
              s.contains(v) ? s.remove(v) : s.add(v);
              setState(() => _draft = _draft.copyWith(ratings: s));
            },
          ),
        ] else ...[
          _filterSection(
            context,
            title: 'Manga Type',
            options: ListFilterState.mangaTypeOptions,
            selected: _draft.mangaTypes,
            onToggle: (v) {
              final s = Set<String>.of(_draft.mangaTypes);
              s.contains(v) ? s.remove(v) : s.add(v);
              setState(() => _draft = _draft.copyWith(mangaTypes: s));
            },
          ),
          _filterSection(
            context,
            title: 'Manga Status',
            options: ListFilterState.mangaStatusOptions,
            selected: _draft.mangaStatuses,
            onToggle: (v) {
              final s = Set<String>.of(_draft.mangaStatuses);
              s.contains(v) ? s.remove(v) : s.add(v);
              setState(
                  () => _draft = _draft.copyWith(mangaStatuses: s));
            },
          ),
        ],
        _genreSection(context),
      ],
    );
  }

  Widget _filterSection(
    BuildContext context, {
    required String title,
    required List<(String, String)> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Tap to select, tap again to deselect',
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (value, label) in options)
              FilterChip(
                label: Text(label),
                selected: selected.contains(value),
                onSelected: (_) => onToggle(value),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Genre include/exclude with three-state chips:
  /// tap cycles none → include (primary) → exclude (error) → none.
  Widget _genreSection(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Genre Include/Exclude',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  'Tap once to include, twice to exclude, again to clear',
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final g in malGenres)
              _TriStateGenreChip(
                label: g,
                state: _draft.genresInclude.contains(g)
                    ? 1
                    : _draft.genresExclude.contains(g)
                        ? -1
                        : 0,
                onTap: () {
                  final inc =
                      Set<String>.of(_draft.genresInclude);
                  final exc =
                      Set<String>.of(_draft.genresExclude);
                  if (inc.contains(g)) {
                    inc.remove(g);
                    exc.add(g);
                  } else if (exc.contains(g)) {
                    exc.remove(g);
                  } else {
                    inc.add(g);
                  }
                  setState(() => _draft = _draft.copyWith(
                        genresInclude: inc,
                        genresExclude: exc,
                      ));
                },
              ),
          ],
        ),
      ],
    );
  }

  // ---------------- Display ----------------

  Widget _displayTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        SwitchListTile(
          title: const Text('Compact rows'),
          subtitle: const Text('Smaller posters, denser list'),
          value: _draft.compactRows,
          onChanged: (v) =>
              setState(() => _draft = _draft.copyWith(compactRows: v)),
        ),
      ],
    );
  }
}

class _TriStateGenreChip extends StatelessWidget {
  final String label;
  final int state; // 0 = none, 1 = include, -1 = exclude
  final VoidCallback onTap;

  const _TriStateGenreChip({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? bg;
    Color? fg;
    if (state == 1) {
      bg = scheme.primaryContainer;
      fg = scheme.onPrimaryContainer;
    } else if (state == -1) {
      bg = scheme.errorContainer;
      fg = scheme.onErrorContainer;
    }
    return ActionChip(
      label: Text(label),
      backgroundColor: bg,
      labelStyle: fg != null
          ? TextStyle(color: fg, fontWeight: FontWeight.bold)
          : null,
      avatar: state == 1
          ? Icon(Icons.add, size: 16, color: fg)
          : state == -1
              ? Icon(Icons.remove, size: 16, color: fg)
              : null,
      onPressed: onTap,
    );
  }
}
