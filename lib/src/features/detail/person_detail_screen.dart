import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/widgets/entrance.dart';
import 'package:malclient/src/widgets/poster_card.dart';

/// Character detail page (Tenrai `/characters/{id}`).
class CharacterDetailScreen extends ConsumerWidget {
  final int id;

  const CharacterDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(characterDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Character')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(characterDetailProvider(id));
          ref.invalidate(characterAnimeProvider(id));
          try {
            await ref.read(characterDetailProvider(id).future);
          } catch (_) {}
        },
        child: detail.when(
          data: (d) {
            if (d == null) {
              return _errorBody(
                context,
                ref,
                'Could not load character.',
                () => ref.invalidate(characterDetailProvider(id)),
              );
            }
            return _CharacterBody(detail: d, anime: ref.watch(characterAnimeProvider(id)));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _errorBody(
            context,
            ref,
            'Could not load character.',
            () => ref.invalidate(characterDetailProvider(id)),
          ),
        ),
      ),
    );
  }
}

class _CharacterBody extends StatelessWidget {
  final CharacterDetail detail;
  final AsyncValue<List<CharacterAnime>> anime;

  const _CharacterBody({required this.detail, required this.anime});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _PersonHeader(
          imageUrl: d.imageUrl,
          name: d.name,
          heroTag: 'character-${d.malId}',
          subtitle: d.nameKanji,
          facts: [
            if (d.nicknames.isNotEmpty) '“${d.nicknames.take(3).join('”, “')}”',
            if (d.favorites > 0) '♥ ${_compact(d.favorites)} favorites',
          ],
        ),
        if (d.about != null && d.about!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('About'),
          const SizedBox(height: 8),
          _AboutText(text: d.about!),
        ],
        const SizedBox(height: 20),
        _SectionTitle('Animeography'),
        const SizedBox(height: 8),
        anime.when(
          data: (items) {
            if (items.isEmpty) {
              return const Text('No anime listed.');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final a = items[i];
                return Entrance(
                  index: i,
                  child: GestureDetector(
                    onTap: () => context.push('/detail/anime/${a.malId}'),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PosterImage(
                              url: a.imageUrl,
                              title: a.title,
                              heroTag: 'poster-anime-${a.malId}',
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (a.role.isNotEmpty)
                          Text(
                            a.role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => const Text('Could not load anime list.'),
        ),
      ],
    );
  }
}

/// Staff/person detail page (Tenrai `/people/{id}`).
class StaffDetailScreen extends ConsumerWidget {
  final int id;

  const StaffDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(staffDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(staffDetailProvider(id));
          ref.invalidate(staffAnimeProvider(id));
          try {
            await ref.read(staffDetailProvider(id).future);
          } catch (_) {}
        },
        child: detail.when(
          data: (d) {
            if (d == null) {
              return _errorBody(
                context,
                ref,
                'Could not load staff member.',
                () => ref.invalidate(staffDetailProvider(id)),
              );
            }
            return _StaffBody(detail: d, anime: ref.watch(staffAnimeProvider(id)));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _errorBody(
            context,
            ref,
            'Could not load staff member.',
            () => ref.invalidate(staffDetailProvider(id)),
          ),
        ),
      ),
    );
  }
}

class _StaffBody extends StatelessWidget {
  final StaffDetail detail;
  final AsyncValue<List<StaffAnime>> anime;

  const _StaffBody({required this.detail, required this.anime});

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final jpName = [
      if (d.familyName != null) d.familyName,
      if (d.givenName != null) d.givenName,
    ].join(' ');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _PersonHeader(
          imageUrl: d.imageUrl,
          name: d.name,
          heroTag: 'staff-${d.malId}',
          subtitle: jpName.isNotEmpty ? jpName : null,
          facts: [
            if (d.birthday != null) 'Born ${d.birthday}',
            if (d.favorites > 0) '♥ ${_compact(d.favorites)} favorites',
            if (d.alternateNames.isNotEmpty)
              'aka ${d.alternateNames.take(2).join(', ')}',
          ],
        ),
        if (d.about != null && d.about!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _SectionTitle('About'),
          const SizedBox(height: 8),
          _AboutText(text: d.about!),
        ],
        const SizedBox(height: 20),
        _SectionTitle('Works'),
        const SizedBox(height: 8),
        anime.when(
          data: (items) {
            if (items.isEmpty) {
              return const Text('No works listed.');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final a = items[i];
                return Entrance(
                  index: i,
                  child: GestureDetector(
                    onTap: () => context.push('/detail/anime/${a.malId}'),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PosterImage(
                              url: a.imageUrl,
                              title: a.title,
                              heroTag: 'poster-anime-${a.malId}',
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (a.position.isNotEmpty)
                          Text(
                            a.position,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, _) => const Text('Could not load works.'),
        ),
      ],
    );
  }
}

/// Shared header: photo + name + facts.
class _PersonHeader extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String? heroTag;
  final String? subtitle;
  final List<String> facts;

  const _PersonHeader({
    required this.imageUrl,
    required this.name,
    this.heroTag,
    this.subtitle,
    this.facts = const [],
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: PosterImage(
            url: imageUrl,
            title: name,
            heroTag: heroTag,
            width: 120,
            height: 170,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              for (final f in facts) ...[
                const SizedBox(height: 8),
                Text(
                  f,
                  style: textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

/// About text with "read more" expansion for long bios.
class _AboutText extends StatefulWidget {
  final String text;

  const _AboutText({required this.text});

  @override
  State<_AboutText> createState() => _AboutTextState();
}

class _AboutTextState extends State<_AboutText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text.trim();
    if (text.length <= 400) {
      return SelectableText(text);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          _expanded ? text : '${text.substring(0, 400)}…',
        ),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Show less' : 'Read more'),
        ),
      ],
    );
  }
}

Widget _errorBody(
  BuildContext context,
  WidgetRef ref,
  String message,
  VoidCallback onRetry,
) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
