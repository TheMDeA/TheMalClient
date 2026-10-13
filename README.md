# MALClient — Flutter rewrite

From-scratch Flutter rewrite of the MALClient MyAnimeList Android app
(replaces the end-of-life Xamarin codebase). DailyAL-inspired visual
language, Material 3 components skinned with a custom warm color scheme.

- Package: `com.dmda.malclient` (same as the old app, installs as an upgrade)
- State: flutter_riverpod · Routing: go_router · Network: dio
- Data: MAL API v2 (lists, search, seasonal, ranking, profile, OAuth2) +
  Jikan API v4 (reviews, recommendations, news — MAL v2 has no such endpoints)

## Run it

```bash
export PATH="$HOME/sdks/flutter/bin:$PATH"
export JAVA_HOME="$HOME/sdks/java/jdk-17.0.17+10"
export ANDROID_HOME="$HOME/sdks/android"
cd ~/workspace/malclient-flutter
flutter pub get
flutter run
```

The app starts in **demo mode** (no API key needed): the login screen has a
"Continue in demo mode" button that opens the full UI with bundled sample
data, so everything is reviewable without MyAnimeList access.

## Enable real MyAnimeList login + data

1. Go to https://myanimelist.net/apiconfig and create a new API app.
2. Set its **App Redirect URL** to exactly: `malclient://oauth`
   (already registered as an intent-filter in
   `android/app/src/main/AndroidManifest.xml`).
3. Copy the **Client ID** into `lib/src/core/config.dart`
   (`const malClientId = '...'`). That's the only place it lives.

With a Client ID set, public endpoints (seasonal, ranking, search, details)
work immediately via the `X-MAL-CLIENT-ID` header; "Log in with MyAnimeList"
does the full OAuth2 PKCE flow (browser → `malclient://oauth` redirect →
token exchange → refresh), with tokens in `flutter_secure_storage`.

## Build an APK

```bash
flutter build apk --debug    # debug
flutter build apk --release  # release (needs signing config for Play/distribution)
```

## Project layout

```
lib/
  main.dart                    # ProviderScope, OAuth deep-link listener, MaterialApp.router
  src/
    core/
      config.dart              # <-- MAL Client ID goes here
      theme/app_theme.dart     # M3 dark/light warm ColorSchemes + accents
      router.dart              # go_router, 5-tab StatefulShellRoute
      api/mal_api_client.dart  # dio + bearer/refresh interceptor
      demo/demo_data.dart      # bundled sample data for demo mode
      providers.dart           # Riverpod wiring (auth, theme, repositories)
    data/
      models/media.dart        # Anime/Manga/ListEntry/User/Review/News models
      repositories/            # auth, media (MAL), list (MAL CRUD), jikan
    features/
      login/ home/ discover/ schedule/ mylist/ detail/ profile/ settings/
    widgets/                   # poster cards, badges, section headers, app shell
```

## Notes / known limits (v1)

- Forums, clubs, messaging, articles, wallpapers from the old app are not
  in v1 — the 8 screens above are the complete v1 scope.
- Detail "Media" tab is a placeholder for a future gallery/PV section.
- Demo-mode list edits are in-memory only (session scope).
