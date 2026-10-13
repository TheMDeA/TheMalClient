# MyAL 🦊

A MyAnimeList client for Android, rewritten from scratch in Flutter.
Track what you watch, find what to watch next, and never miss an airing episode.

The fox in the icon is a kitsune — and if you look closely, it's also the letter M.

## What's inside

- **Home** — seasonal anime, airing spotlights, and the latest news
- **Discover** — search with real filters (type, status, rating, 70 genres), top anime/manga charts
- **Schedule** — weekly airing calendar with live countdowns to the next episode
- **My List** — your anime & manga lists with a full entry editor (score, progress, dates, tags, rewatch tracking), search, sort & filter
- **Profile** — your MAL stats and account
- **Anime/Manga details** — synopsis, characters, staff, reviews, related titles, recommendations, and a "More Info" tab with everything else
- Warm dark theme (light mode too), 12 accent colors, AMOLED black option
- Demo mode — poke around the whole app without a MAL account

Data comes from the official MAL API, plus the Tenrai API for characters, staff, reviews, and news.

## Try it

```bash
flutter pub get
flutter run
```

No API key needed to look around: hit **"Continue in demo mode"** on the login screen and the full UI loads with sample data.

## Connect your MyAnimeList account

1. Create an app at https://myanimelist.net/apiconfig
2. Set the **App Redirect URL** to exactly `malclient://oauth`
3. Paste the **Client ID** into `lib/src/core/config.dart` (`const malClientId = '...'`)

That's it. Public stuff (seasonal, rankings, search, details) works right away; logging in unlocks your lists via OAuth2 PKCE, with tokens kept in secure storage.

## Build an APK

```bash
flutter build apk --debug    # quick test build
flutter build apk --release  # release (needs signing set up)
```

Tagged `v*` releases are built automatically by the `build-apk.yml` workflow.

## Project layout

```
lib/
  main.dart                  # app entry, OAuth deep-link listener
  src/
    core/                    # config, theme, router, API clients, demo data, providers
    data/                    # models + repositories (auth, media, lists, Tenrai)
    features/                # login, home, discover, schedule, mylist, detail, profile, settings
    widgets/                 # poster cards, badges, skeletons, section headers
```

State is Riverpod, routing is go_router, networking is dio. Nothing exotic.

## Honest notes

- This is a rewrite — forums, clubs, and messaging from the old Xamarin app aren't here (yet?).
- The detail "Media" tab is a placeholder for a future gallery section.
- List edits in demo mode only live as long as the session.
