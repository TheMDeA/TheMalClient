import 'package:flutter/material.dart';
import 'package:malclient/src/widgets/poster_card.dart';

/// "Section title            ->" row, DailyAL-style.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (onSeeAll != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: onSeeAll,
              tooltip: 'See all',
            ),
        ],
      ),
    );
  }
}

/// Horizontal rail of [PosterCard]s.
class PosterRail extends StatelessWidget {
  final List<PosterCard> cards;

  const PosterRail({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => cards[i],
      ),
    );
  }
}

/// Small centered loading / error / empty states for async sections.
class AsyncSection extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const AsyncSection.error(
      {super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 32),
            const SizedBox(height: 8),
            const Text('Could not load this section.'),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
