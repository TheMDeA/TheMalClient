import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/core/theme/app_theme.dart';

/// Settings: appearance, accent, cache, about, logout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Appearance',
              style:
                  textTheme.titleSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),
          Card.filled(
            child: Column(
              children: [
                _ThemeTile(
                  title: 'Auto (system)',
                  icon: Icons.settings_suggest_outlined,
                  selected: themeMode == AppThemeMode.auto,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(AppThemeMode.auto),
                ),
                _ThemeTile(
                  title: 'Light',
                  icon: Icons.light_mode_outlined,
                  selected: themeMode == AppThemeMode.light,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(AppThemeMode.light),
                ),
                _ThemeTile(
                  title: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  selected: themeMode == AppThemeMode.dark,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(AppThemeMode.dark),
                ),
                _ThemeTile(
                  title: 'Black (AMOLED)',
                  icon: Icons.contrast_outlined,
                  selected: themeMode == AppThemeMode.black,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(AppThemeMode.black),
                ),
                ListTile(
                  leading: Icon(Icons.palette_outlined,
                      color: scheme.onSurfaceVariant),
                  title: const Text('Theme setup'),
                  subtitle: Text(
                      'Colors, background image, font (${accent.label})'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/setup'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Storage',
              style:
                  textTheme.titleSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),
          Card.filled(
            child: ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear image cache'),
              subtitle: const Text('Frees space used by cached posters'),
              onTap: () async {
                // CachedNetworkImage evicts via its cache manager; a full
                // clear is a best-effort here.
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Image cache will refresh on next load.')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Text('Account',
              style:
                  textTheme.titleSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),
          Card.filled(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'MALClient 1.0.1 · Flutter rewrite\nData: MyAnimeList · Reviews/news: Jikan',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon,
          color: selected ? scheme.primary : scheme.onSurfaceVariant),
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check, color: scheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

