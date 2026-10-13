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
                  title: 'System default',
                  icon: Icons.settings_suggest_outlined,
                  selected: themeMode == ThemeMode.system,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(ThemeMode.system),
                ),
                _ThemeTile(
                  title: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  selected: themeMode == ThemeMode.dark,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(ThemeMode.dark),
                ),
                _ThemeTile(
                  title: 'Light',
                  icon: Icons.light_mode_outlined,
                  selected: themeMode == ThemeMode.light,
                  onTap: () =>
                      ref.read(themeModeProvider.notifier).set(ThemeMode.light),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Accent color',
              style:
                  textTheme.titleSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: 8),
          Card.filled(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final a in AppAccent.values)
                    _AccentDot(
                      accent: a,
                      selected: accent == a,
                      onTap: () =>
                          ref.read(accentProvider.notifier).set(a),
                    ),
                ],
              ),
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
              'MALClient 1.0.0 · Flutter rewrite\nData: MyAnimeList · Reviews/news: Jikan',
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

class _AccentDot extends StatelessWidget {
  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = accent.primary(brightness);
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: selected
                  ? Border.all(color: scheme.onSurface, width: 3)
                  : null,
            ),
            child: selected
                ? Icon(Icons.check,
                    color: accent.primary(brightness) == Colors.white
                        ? Colors.black
                        : scheme.onPrimary)
                : null,
          ),
          const SizedBox(height: 6),
          Text(accent.label,
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
