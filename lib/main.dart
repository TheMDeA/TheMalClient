import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/core/router.dart';
import 'package:malclient/src/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MalClientApp(),
    ),
  );
}

class MalClientApp extends ConsumerStatefulWidget {
  const MalClientApp({super.key});

  @override
  ConsumerState<MalClientApp> createState() => _MalClientAppState();
}

class _MalClientAppState extends ConsumerState<MalClientApp> {
  /// OAuth codes already handed to the token exchange. The redirect can be
  /// delivered twice (initial link + stream); MAL codes are single-use, so
  /// each code must be exchanged exactly once.
  final _handledCodes = <String>{};

  @override
  void initState() {
    super.initState();
    _listenForOAuthRedirect();
  }

  /// Captures the `malclient://oauth?code=...` redirect after the user
  /// authorizes in the browser, then completes the token exchange.
  Future<void> _listenForOAuthRedirect() async {
    final appLinks = AppLinks();

    void handle(Uri? uri) {
      if (uri == null) return;
      if (uri.scheme == 'malclient' && uri.host == 'oauth') {
        final code = uri.queryParameters['code'];
        final error = uri.queryParameters['error'];
        if (code != null && code.isNotEmpty && _handledCodes.add(code)) {
          ref.read(authControllerProvider.notifier).completeOAuth(code);
        } else if (error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login cancelled: $error')),
          );
        }
      }
    }

    handle(await appLinks.getInitialLink());
    appLinks.uriLinkStream.listen(handle);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentProvider);

    return MaterialApp.router(
      title: 'MALClient',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light, accent),
      darkTheme: buildAppTheme(Brightness.dark, accent),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
