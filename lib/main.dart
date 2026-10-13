import 'package:app_links/app_links.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final fontKey = ref.watch(appFontProvider);
    final wantDynamic = ref.watch(dynamicColorProvider);
    // Triggers the Google Fonts download on first use; the family name is
    // then applied to the whole text theme (null = system font).
    final fontFamily =
        fontKey == 'system' ? null : GoogleFonts.getFont(fontKey).fontFamily;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // Publish availability for the settings UI (Android 12+ only).
        final available = lightDynamic != null || darkDynamic != null;
        if (ref.read(dynamicColorAvailableProvider) != available) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(dynamicColorAvailableProvider.notifier).available =
                available;
          });
        }
        final lightScheme = wantDynamic ? lightDynamic : null;
        final darkScheme = wantDynamic ? darkDynamic : null;

        // Keep the system gesture bar in sync with the theme instead of the
        // default black/white. The status bar is left to the AppBar.
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final dark = themeMode.flutterMode == ThemeMode.dark ||
            (themeMode.flutterMode == ThemeMode.system &&
                platformBrightness == Brightness.dark);
        final effectiveBrightness = dark ? Brightness.dark : Brightness.light;
        final activeScheme = dark ? darkScheme : lightScheme;
        final navBarColor = activeScheme != null
            ? (themeMode.amoled && dark ? Colors.black : activeScheme.surface)
            : appSurface(accent, effectiveBrightness,
                amoled: themeMode.amoled);
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            systemNavigationBarColor: navBarColor,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp.router(
          title: 'MyAL',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(
            Brightness.light,
            accent,
            fontFamily: fontFamily,
            dynamicScheme: lightScheme,
          ),
          darkTheme: buildAppTheme(
            Brightness.dark,
            accent,
            amoled: themeMode.amoled,
            fontFamily: fontFamily,
            dynamicScheme: darkScheme,
          ),
          themeMode: themeMode.flutterMode,
          routerConfig: router,
        );
      },
    );
  }
}
