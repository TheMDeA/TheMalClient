import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malclient/src/core/providers.dart';

/// List Preferences sub-screen: start/end date auto-setters.
class ListPreferencesScreen extends ConsumerWidget {
  const ListPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auto = ref.watch(dateAutoSetProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('List Preferences')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
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
