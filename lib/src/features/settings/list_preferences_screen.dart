import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';

/// List Preferences sub-screen: default tabs + start/end date auto-setters.
class ListPreferencesScreen extends ConsumerWidget {
  const ListPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auto = ref.watch(dateAutoSetProvider);
    final defaults = ref.watch(listTabDefaultsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('List Preferences')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Choose which tabs the My List screen opens on.',
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _DefaultTabRow(
            icon: Icons.tab_outlined,
            title: 'Default tab for anime/manga',
            valueLabel: switch (defaults.kind) {
              'anime' => 'Anime',
              'manga' => 'Manga',
              _ => 'None',
            },
            onTap: () => _pickOption(
              context: context,
              title: 'Default tab for anime/manga',
              options: const [
                (null, 'None'),
                ('anime', 'Anime'),
                ('manga', 'Manga'),
              ],
              current: defaults.kind,
              onPick: (v) =>
                  ref.read(listTabDefaultsProvider.notifier).setKind(v),
            ),
          ),
          _DefaultTabRow(
            icon: Icons.movie_outlined,
            title: 'Default tab for anime',
            valueLabel: _statusValueLabel(defaults.animeStatus, true),
            onTap: () => _pickOption(
              context: context,
              title: 'Default tab for anime',
              options: [
                (null, 'None'),
                ('all', 'All'),
                ...AnimeListStatuses.all
                    .map((s) => (s, AnimeListStatuses.label(s))),
              ],
              current: defaults.animeStatus,
              onPick: (v) => ref
                  .read(listTabDefaultsProvider.notifier)
                  .setAnimeStatus(v),
            ),
          ),
          _DefaultTabRow(
            icon: Icons.menu_book_outlined,
            title: 'Default tab for manga',
            valueLabel: _statusValueLabel(defaults.mangaStatus, false),
            onTap: () => _pickOption(
              context: context,
              title: 'Default tab for manga',
              options: [
                (null, 'None'),
                ('all', 'All'),
                ...MangaListStatuses.all
                    .map((s) => (s, MangaListStatuses.label(s))),
              ],
              current: defaults.mangaStatus,
              onPick: (v) => ref
                  .read(listTabDefaultsProvider.notifier)
                  .setMangaStatus(v),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Divider(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Automatically set start and end dates when list entries change status.',
              style: textTheme.bodyMedium?.copyWith(
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _CheckRow(
            label: 'Set start date to today when adding to list.',
            value: auto.startOnAdd,
            onChanged: (v) => ref
                .read(dateAutoSetProvider.notifier)
                .setStartOnAdd(v),
          ),
          _CheckRow(
            label:
                'Set start date to today when setting watching status.',
            value: auto.startOnWatching,
            onChanged: (v) => ref
                .read(dateAutoSetProvider.notifier)
                .setStartOnWatching(v),
          ),
          _CheckRow(
            label:
                'Set end date to today when setting completed status.',
            value: auto.endOnCompleted,
            onChanged: (v) => ref
                .read(dateAutoSetProvider.notifier)
                .setEndOnCompleted(v),
          ),
          _CheckRow(
            label:
                'Set end date to today when setting dropped status.',
            value: auto.endOnDropped,
            onChanged: (v) => ref
                .read(dateAutoSetProvider.notifier)
                .setEndOnDropped(v),
          ),
          _CheckRow(
            label:
                'Allow manually picked dates to override the automatic ones.',
            value: auto.allowOverride,
            onChanged: (v) => ref
                .read(dateAutoSetProvider.notifier)
                .setAllowOverride(v),
          ),
        ],
      ),
    );
  }
}

String _statusValueLabel(String? value, bool anime) {
  if (value == null) return 'None';
  if (value == 'all') return 'All';
  return anime ? AnimeListStatuses.label(value) : MangaListStatuses.label(value);
}

/// Radio option picker in a bottom sheet, like the reference design.
void _pickOption({
  required BuildContext context,
  required String title,
  required List<(String?, String)> options,
  required String? current,
  required ValueChanged<String?> onPick,
}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: RadioGroup<String?>(
              groupValue: current,
              onChanged: (v) {
                Navigator.pop(sheetContext);
                onPick(v);
              },
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in options)
                    RadioListTile<String?>(
                      title: Text(option.$2),
                      value: option.$1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DefaultTabRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String valueLabel;
  final VoidCallback onTap;

  const _DefaultTabRow({
    required this.icon,
    required this.title,
    required this.valueLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyLarge),
                  Text(
                    'If nothing is selected, it will default to last opened one.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              valueLabel,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: textTheme.bodyLarge),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
