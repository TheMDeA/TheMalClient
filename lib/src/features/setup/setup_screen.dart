import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/core/theme/app_theme.dart';

/// Theme setup: accent color, theme mode, background image, and font.
/// Shown once after the welcome page during onboarding, and reachable later
/// from Settings.
class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  Future<void> _previous(BuildContext context, WidgetRef ref) async {
    final fresh = ref.read(authControllerProvider).value?.freshLogin ?? false;
    if (fresh) {
      context.go('/welcome');
    } else if (context.mounted) {
      context.pop();
    }
  }

  Future<void> _next(BuildContext context, WidgetRef ref) async {
    final fresh = ref.read(authControllerProvider).value?.freshLogin ?? false;
    if (fresh) {
      await ref.read(authControllerProvider.notifier).dismissWelcome();
      if (context.mounted) context.go('/home');
    } else if (context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Select a Theme',
                      style: textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    _SectionLabel(
                      label: 'Pick a color',
                      tooltip: 'Accent color used for buttons and highlights.',
                    ),
                    const SizedBox(height: 12),
                    const _AccentGrid(),
                    const SizedBox(height: 28),
                    _SectionLabel(
                      label: 'Select a theme mode',
                      tooltip:
                          'Auto follows your system. Black is a pure-black AMOLED dark theme.',
                    ),
                    const SizedBox(height: 12),
                    const _ThemeModePicker(),
                    const SizedBox(height: 28),
                    const _FontTile(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _previous(context, ref),
                      child: const Text('Previous'),
                    ),
                    TextButton(
                      onPressed: () => _next(context, ref),
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.tooltip});

  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label, style: textTheme.titleMedium),
        const SizedBox(width: 6),
        Tooltip(
          message: tooltip,
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AccentGrid extends ConsumerWidget {
  const _AccentGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(accentProvider);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        for (final accent in AppAccent.values)
          GestureDetector(
            onTap: () => ref.read(accentProvider.notifier).set(accent),
            child: Tooltip(
              message: accent.label,
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: accent.primary(brightness),
                    borderRadius: BorderRadius.circular(16),
                    border: selected == accent
                        ? Border.all(color: scheme.primary, width: 2)
                        : null,
                  ),
                  child: selected == accent
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeModePicker extends ConsumerWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<AppThemeMode>(
        segments: const [
          ButtonSegment(value: AppThemeMode.auto, label: Text('auto')),
          ButtonSegment(value: AppThemeMode.light, label: Text('light')),
          ButtonSegment(value: AppThemeMode.dark, label: Text('dark')),
          ButtonSegment(value: AppThemeMode.black, label: Text('black')),
        ],
        selected: {mode},
        onSelectionChanged: (selected) =>
            ref.read(themeModeProvider.notifier).set(selected.first),
      ),
    );
  }
}

class _FontTile extends ConsumerWidget {
  const _FontTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final font = ref.watch(appFontProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card.filled(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            'A',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
        title: const Text('Font Settings'),
        subtitle: Text(
            'Change the app font (${font == 'system' ? 'System default' : font})'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showFontPicker(context, ref),
      ),
    );
  }

  void _showFontPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text('Choose a font',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Flexible(
              child: RadioGroup<String>(
                groupValue: ref.watch(appFontProvider),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(appFontProvider.notifier).set(v);
                  }
                  Navigator.of(context).pop();
                },
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _fontOption('system', 'System Default'),
                    for (final name in AppFontNotifier.options)
                      _fontOption(name, name),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _fontOption(String key, String label) {
    final family =
        key == 'system' ? null : GoogleFonts.getFont(key).fontFamily;
    return RadioListTile<String>(
      value: key,
      title: Text(label, style: TextStyle(fontFamily: family, fontSize: 17)),
    );
  }
}
