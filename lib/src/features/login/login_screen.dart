import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/config.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// First screen: MAL OAuth login or demo mode.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;

  Future<void> _login() async {
    if (!hasRealClientId) {
      _showClientIdHelp();
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final url = await repo.beginLogin();
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the browser.')),
        );
      }
      // The flow continues when MAL redirects to malclient://oauth,
      // captured via app_links in main.dart.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showClientIdHelp() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Client ID required'),
        content: const Text(
          'To log in with a real MyAnimeList account, add your MAL API '
          'Client ID in lib/src/core/config.dart (see the comment there). '
          'Get one free at myanimelist.net/apiconfig with redirect URL '
          'malclient://oauth.\n\nOr continue in demo mode to explore the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _demo() async {
    await ref.read(authControllerProvider.notifier).continueAsDemo();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: Text(
                  'M',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MALClient',
                style: textTheme.displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your anime and manga, beautifully tracked.',
                style: textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy ? null : _login,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: const Text('Log in with MyAnimeList'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _demo,
                child: const Text('Continue in demo mode'),
              ),
              const SizedBox(height: 16),
              Text(
                hasRealClientId
                    ? 'Secure OAuth2 sign-in via myanimelist.net'
                    : 'Demo mode: no Client ID configured yet (see lib/src/core/config.dart)',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
