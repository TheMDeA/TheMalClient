# Changelog

All notable changes to MALClient (Flutter rewrite) are documented here.

## [1.2.2] - 2026-10-13

- New More Info tab: detailed metadata cards (media, episodes, status, premiered, aired dates, source, broadcast in your timezone, duration, rating, synonyms, alternative titles, studios, genres)
- My List rows redesigned: MAL score with list users, color-coded status badge, your score, live airing countdown, media info with genres
- Airing chip shows current episode and live countdown to the next episode, in your phone's timezone
- Synopsis tab cleaned up — detailed info moved to the More Info tab
- Fixed broadcast times showing wrong hours (timezone conversion) and countdowns not appearing
- Characters/Staff tabs: added User-Agent for Jikan requests and clearer error messages with retry

## [1.2.1] - 2026-10-13

- Settings restructured into a DailyAL-style menu with sub-screens (Theme Settings, List Preferences, About)
- In-app updater: check for updates manually or auto-check daily, download and install new versions without leaving the app
- Related tab now shows relation type badges (Sequel, Prequel, Side Story, etc.)
- New More Info tab: detailed metadata cards (media, episodes, status, premiered, aired dates, source, broadcast in local timezone, duration, rating, synonyms, alternative titles, studios, genres)
- Synopsis tab now has a full Information section (format, score, rank, popularity, members, studio, source, season, status, rating)
- Airing chip shows current episode and live countdown to the next episode, in the phone's local timezone
- My List rows redesigned: MAL score with list users, color-coded status badge (CW/C/OH/D/PTW), your score, live airing countdown, media info with genres, progress with quick steppers
- Fixed Characters/Staff tabs showing "not found" on network errors — now shows an error state with a retry button, plus automatic retry on Jikan rate limits

## [1.1.0] - 2026-10-13

**My List**
- Full list entry editor: status/progress/score pills, rewatch & reread controls, start/end dates, priority, tags, and comments
- Sort / Filter / Display panel: sort by title, list score, start date, updated date, popularity, list users, scoring users, or MAL score; filter by type, airing status, age rating, and include/exclude genres; compact row display option
- Automatic date setters: auto-fill start date when adding or starting an entry, end date when completing or dropping (configurable in Settings → List dates)

**Details**
- Characters tab with voice actors, Staff tab (anime)
- Statistics section: status distribution and score breakdown charts
- Related anime/manga and reviews

**Discover & Search**
- Advanced search filters: type, status, age rating, and genres
- Full official MAL genre/theme/demographic taxonomy (70 items)

**More**
- News browser with full article list
- History view: recently updated entries grouped by date
- Fixed blank posters in grids

## [1.0.3] - 2026-10-13

- Fixed MyAnimeList login: PKCE code challenge now uses `plain` instead of S256, matching MAL's API specification

## [1.0.2] - 2026-10-13

- Fixed MyAnimeList login: token exchange now handles MAL's strict redirect-URI check and client authentication (client secret, with automatic fallback)
- New kitsune launcher icon, also shown on the login screen
- Login errors now show MAL's actual reason instead of a generic message

## [1.0.1] - 2026-10-13

- Log in with MyAnimeList (OAuth2 PKCE) in an in-app browser — no more external browser jump
- "Logged in as" confirmation page after signing in
- New "Select a Theme" setup page: 12 accent colors, auto/light/dark/black (AMOLED) theme modes, font picker
- Theme setup also available anytime from Settings
- Fixed: OAuth redirect no longer lands on an error page; login reliably reaches Home
- Vector launcher icon (no missing-image build issues)

## [1.0.0] - 2026-10-13

A from-scratch rewrite of MALClient in Flutter.

- New warm dark theme (tan/peach accent) with light mode, 3 accent options
- Bottom navigation: Home, Discover, Schedule, My List, Profile
- Home: news rail, seasonal anime rail with score badges, suggested rail
- Discover: search with live results, genre filters, Top Anime / Top Manga / Seasonal
- Schedule: weekly airing calendar with episode countdowns
- My List: anime/manga lists, status filters, episode steppers, full edit sheet
- Title details: synopsis, media, related, reviews, add-to-list
- Profile stats and settings
- Log in with MyAnimeList (OAuth2); demo mode included for trying the UI
