import 'package:flutter/material.dart';

/// About sub-screen: version, changelog highlights, data sources.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.pets,
                  size: 64,
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'MALClient',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version 1.1.0 · Flutter rewrite',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "What's new",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in _changelog)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: textTheme.bodyMedium),
                  Expanded(
                    child: Text(item,
                        style: textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Data sources',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anime & manga data: MyAnimeList API\nReviews & news: Jikan API',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

const _changelog = [
  'Full list entry editor with rewatch status, dates, priority and comments',
  'Sort, filter and display options for My List',
  'Characters & staff tabs and statistics on detail pages',
  'News browser and history view',
  'Advanced search filters',
];
