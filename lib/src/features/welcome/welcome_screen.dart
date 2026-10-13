import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';

/// Shown once right after a successful MAL login: confirms who signed in,
/// then hands off to the theme setup page.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  /// Continues onboarding to the theme setup page (freshLogin stays set
  /// until setup is done).
  void _next(BuildContext context) {
    context.go('/setup');
  }

  /// "Previous" here means "wrong account" — sign out back to the login page.
  Future<void> _previous(WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value?.user;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pictureUrl = user?.pictureUrl;
    final initial = (user?.name.isNotEmpty ?? false)
        ? user!.name.characters.first.toUpperCase()
        : '?';

    return Scaffold(
      body: SafeArea(
        child: Column(
            children: [
              const Spacer(flex: 2),
              CircleAvatar(
                radius: 72,
                backgroundColor: scheme.primaryContainer,
                backgroundImage:
                    pictureUrl != null ? NetworkImage(pictureUrl) : null,
                child: pictureUrl == null
                    ? Text(
                        initial,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Logged in as ${user?.name ?? ''}',
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => _previous(ref),
                      child: const Text('Previous'),
                    ),
                    TextButton(
                      onPressed: () => _next(context),
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
