import 'package:flutter/material.dart';
import 'package:malclient/src/core/services/update_service.dart';
import 'package:malclient/src/features/settings/update_sheet.dart';

/// About sub-screen: version, changelog highlights, data sources,
/// and the update checker.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  bool _checking = false;
  bool _autoCheck = true;

  @override
  void initState() {
    super.initState();
    autoCheckUpdate.then((v) {
      if (mounted) setState(() => _autoCheck = v);
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    try {
      final info = await checkForUpdate();
      if (!mounted) return;
      if (info != null) {
        await showUpdateSheet(context, info);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You're up to date.")),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Couldn't check for updates. Check your connection.")),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/logo/app_logo.webp',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'M',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'MyAL',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FutureBuilder<String>(
                  future: installedVersion(),
                  builder: (context, snap) => Text(
                    'Version ${snap.data ?? '1.2.3'} · Flutter rewrite',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card.filled(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.system_update_outlined,
                      color: scheme.onSurfaceVariant),
                  title: const Text('Check for updates'),
                  subtitle: const Text(
                      'See if a newer version is available'),
                  trailing: _checking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _checking ? null : _checkForUpdates,
                ),
                SwitchListTile(
                  secondary: Icon(Icons.autorenew_outlined,
                      color: scheme.onSurfaceVariant),
                  title: const Text('Auto-check for updates'),
                  subtitle: const Text(
                      'Check once a day when the app starts'),
                  value: _autoCheck,
                  onChanged: (v) async {
                    await setAutoCheckUpdate(v);
                    if (mounted) setState(() => _autoCheck = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ChangelogSection(textTheme: textTheme, scheme: scheme),
          const SizedBox(height: 24),
          Text(
            'Data sources',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anime & manga data: MyAnimeList API\nReviews, news & characters: Tenrai API',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// "What's new": release notes fetched from the GitHub releases feed
/// (same source as the update checker), cached for 24h. Falls back to a
/// static highlights list when offline with no cache.
class _ChangelogSection extends StatefulWidget {
  final TextTheme textTheme;
  final ColorScheme scheme;

  const _ChangelogSection({required this.textTheme, required this.scheme});

  @override
  State<_ChangelogSection> createState() => _ChangelogSectionState();
}

class _ChangelogSectionState extends State<_ChangelogSection> {
  late Future<List<ReleaseNotes>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchReleaseNotes();
  }

  void _refresh() {
    setState(() => _future = refreshReleaseNotes());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = widget.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "What's new",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
              onPressed: _refresh,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        FutureBuilder<List<ReleaseNotes>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            if (snap.hasError || !(snap.hasData && snap.data!.isNotEmpty)) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in _fallbackChangelog)
                    _bullet(textTheme, item),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    onPressed: _refresh,
                  ),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final release in snap.data!)
                  if (release.notes.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 2),
                      child: Text(
                        release.tag,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.scheme.primary,
                        ),
                      ),
                    ),
                    for (final line in _notesToBullets(release.notes))
                      _bullet(textTheme, line),
                  ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _bullet(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: textTheme.bodyMedium),
          Expanded(
            child: Text(text, style: textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Turns release-note markdown into plain bullet strings: skips headers,
/// strips `- `/`* ` markers and light markdown (bold, code, links).
List<String> _notesToBullets(String notes) {
  final out = <String>[];
  for (var line in notes.split('\n')) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('- ')) {
      line = line.substring(2).trim();
    } else if (line.startsWith('* ')) {
      line = line.substring(2).trim();
    }
    // [text](url) -> text
    line = line.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (m) => m.group(1)!,
    );
    line = line
        .replaceAll('**', '')
        .replaceAll('`', '')
        .replaceAll(RegExp(r'^_ | _$'), '')
        .trim();
    if (line.isNotEmpty) out.add(line);
  }
  return out;
}

const _fallbackChangelog = [
  'Full list entry editor with rewatch status, dates, priority and comments',
  'Sort, filter and display options for My List',
  'Characters & staff tabs and statistics on detail pages',
  'News browser and history view',
  'Advanced search filters',
];
