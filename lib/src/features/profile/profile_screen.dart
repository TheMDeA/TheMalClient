import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';

/// Profile tab: avatar header, anime/manga stats, menu to settings/logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: auth.when(
          data: (state) {
            final user = state.user;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(context, state, scheme, textTheme),
                const SizedBox(height: 20),
                if (user != null) ...[
                  _StatsCard(
                    title: 'Anime statistics',
                    stats: user.animeStats,
                    unit: 'days watched',
                  ),
                  const SizedBox(height: 12),
                  _StatsCard(
                    title: 'Manga statistics',
                    stats: user.mangaStats,
                    unit: 'days read',
                  ),
                  const SizedBox(height: 20),
                ],
                _MenuTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => context.push('/settings'),
                ),
                _MenuTile(
                  icon: Icons.history,
                  title: 'History',
                  onTap: () => context.push('/history'),
                ),
                _MenuTile(
                  icon: Icons.info_outline,
                  title: 'About MyAL',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'MyAL',
                    applicationVersion: '1.0.0 (Flutter rewrite)',
                    children: const [
                      Text(
                        'A from-scratch Flutter rewrite of MyAL '
                        'MyAnimeList app. Data by MyAnimeList; reviews and '
                        'news by Tenrai.',
                      ),
                    ],
                  ),
                ),
                _MenuTile(
                  icon: Icons.logout,
                  title: state.isDemo ? 'Exit demo mode' : 'Log out',
                  onTap: () async {
                    await ref
                        .read(authControllerProvider.notifier)
                        .logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AuthState state, ColorScheme scheme,
      TextTheme textTheme) {
    final user = state.user;
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: scheme.primaryContainer,
          backgroundImage:
              user?.pictureUrl != null ? NetworkImage(user!.pictureUrl!) : null,
          child: user?.pictureUrl == null
              ? Text(
                  (user?.name ?? 'D')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 32,
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? (state.isDemo ? 'DemoUser' : 'Guest'),
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.isDemo ? 'Demo mode' : 'MyAnimeList account',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final MalUserStats stats;
  final String unit;

  const _StatsCard({
    required this.title,
    required this.stats,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget stat(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                stat('Entries', '${stats.totalEntries}'),
                stat('Mean score', stats.meanScore.toStringAsFixed(2)),
                stat(unit, stats.daysWatched.toStringAsFixed(1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
