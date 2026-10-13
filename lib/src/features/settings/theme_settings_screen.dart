import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/core/theme/app_theme.dart';

/// Theme Settings sub-screen: theme mode + link to full theme setup.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentProvider);
    final dynamicOn = ref.watch(dynamicColorProvider);
    final dynamicAvailable = ref.watch(dynamicColorAvailableProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: ListView(
        children: [
          _RadioRow(
            icon: Icons.settings_suggest_outlined,
            title: 'Auto (system)',
            subtitle: 'Follow the system theme.',
            selected: themeMode == AppThemeMode.auto,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .set(AppThemeMode.auto),
          ),
          _RadioRow(
            icon: Icons.light_mode_outlined,
            title: 'Light',
            subtitle: 'Light theme.',
            selected: themeMode == AppThemeMode.light,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .set(AppThemeMode.light),
          ),
          _RadioRow(
            icon: Icons.dark_mode_outlined,
            title: 'Dark',
            subtitle: 'Dark theme.',
            selected: themeMode == AppThemeMode.dark,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .set(AppThemeMode.dark),
          ),
          _RadioRow(
            icon: Icons.contrast_outlined,
            title: 'Black (AMOLED)',
            subtitle: 'Pure black theme for AMOLED screens.',
            selected: themeMode == AppThemeMode.black,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .set(AppThemeMode.black),
          ),
          const Divider(),
          _DynamicColorTile(
            value: dynamicOn,
            available: dynamicAvailable,
            onChanged: (v) =>
                ref.read(dynamicColorProvider.notifier).set(v),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.palette_outlined,
                color: scheme.onSurfaceVariant),
            title: const Text('Theme setup'),
            subtitle: Text(dynamicOn && dynamicAvailable
                ? 'Accent color and font (dynamic colors on)'
                : 'Accent color and font (${accent.label})'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/setup'),
          ),
        ],
      ),
    );
  }
}

/// Material You toggle: uses the system wallpaper colors (Android 12+)
/// instead of the accent presets. Disabled when the device doesn't provide
/// dynamic colors.
class _DynamicColorTile extends StatelessWidget {
  final bool value;
  final bool available;
  final ValueChanged<bool> onChanged;

  const _DynamicColorTile({
    required this.value,
    required this.available,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled =
        available && Theme.of(context).platform == TargetPlatform.android;
    return SwitchListTile(
      secondary: Icon(
        Icons.wallpaper_outlined,
        color: scheme.onSurfaceVariant,
      ),
      title: const Text('Material You dynamic colors'),
      subtitle: Text(
        !available
            ? 'Requires Android 12 or newer.'
            : 'Use your wallpaper colors instead of an accent preset.',
        style: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      value: value && enabled,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _RadioRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RadioRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                size: 26,
                color: selected
                    ? scheme.primary
                    : scheme.onSurfaceVariant),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleMedium),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}
