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
                    child:
                        Text(item, style: textTheme.bodyMedium),
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
