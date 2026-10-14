# Changelog

All notable changes to MALClient (Flutter rewrite) are documented here.

## [1.3.0] - 2026-10-14
- The stepper's status flips now also apply the date auto-setters (start date on Watching, finish date on Completed)
- The stepper now asks for confirmation before auto-completing an entry at its final episode/chapter
- Fixed manga detail pages (they fetched the anime endpoint and showed the wrong title): dedicated manga detail with authors, chapters/volumes, manga characters/reviews/statistics
- Reaching the final episode/chapter now flips the entry to Completed automatically; progress can no longer exceed the known total (also capped in the edit sheet)
- Fixed pull-to-refresh on the detail page (it never triggered: NestedScrollView only overscrolls its inner tab lists, which the default indicator predicate ignores)
- My List stepper now also refreshes the detail page cache, so the status pill is never stale when opening an entry

- Stepping an episode/chapter up on a "Plan to Watch" / "Plan to Read" entry now flips it to "Watching" / "Reading" automatically

## [1.2.8] - 2026-10-14
- Removed the countdown bounce animation in My List (the airing countdown now updates silently)
- Material You dynamic colors: optional system wallpaper colors (Android 12+) in Theme Settings, replacing the accent presets when on

- Performance batch: News screen loads ~5x faster (parallel requests instead of 12 sequential with delays)
- My List no longer runs a timer per row — one shared ticker, countdowns now minute-precision
- Search waits until you stop typing (400ms debounce) and only queries the visible Anime/Manga tab
- My List status chips filter instantly (list fetched once, filtered locally)
- Episode/chapter stepper updates instantly with no reload flash, rolls back if the update fails
- Malformed deep links redirect home instead of crashing
- Detail gallery, fullscreen viewer, and banner now use the disk image cache (less data, less memory)
- Poster color extraction moved off the UI thread

## [1.2.7] - 2026-10-14

- Detail banner now glows with the poster's dominant color
- Detail pages have a full-width banner header again (poster cover with title overlay), keeping all info: score, rank, popularity, episodes, format, aired date, studios, members
- Fixed the accent picker checkmark being invisible on light accent colors
- List status colors (Watching, Completed…) now adapt to light/dark theme
- Removed the duplicate theme-mode picker from the theme setup screen
- System navigation bar now matches the app theme
- App background now takes a subtle tint of the chosen accent color

## [1.2.6] - 2026-10-13

- Fixed score badges on Discover posters being unreadable (dark text on dark background)
- Detail list-entry button now shows your status and episode progress ("Watching • 12/64")
- Detail page refreshes itself right after you save a list entry (no more stale status pill)

## [1.2.5] - 2026-10-13

- New character pages: photo, about bio, favorites, and a tappable animeography grid
- New staff pages: photo, biography, birthday, and a works grid with their positions
- Character and staff cards are now tappable (they did nothing before)
- Removed dead "coming soon" buttons on Home (notifications bell, Categories/Genres chips)
- Media tab gallery now works for manga too
- Fixed About dialog crediting Jikan instead of Tenrai
- Settings → Storage now actually clears the cached posters (it showed a fake confirmation before)
- Character/staff photos now fly into their detail pages (Hero transition)
- Bottom-nav tabs fade in softly when switching
- Detail bookmark button now shows the correct 'Edit list entry' state
- About screen uses the kitsune logo and shows the real version
- Profile supports pull-to-refresh
- Schedule marks today's weekday and its countdowns tick every minute
- Fixed the fullscreen picture viewer leaking memory on every open
- Removed the duplicate About entry from Profile (About now lives only in Settings)
- About → What's new now shows the real release notes from GitHub (cached 24h)

## [1.2.4] - 2026-10-13

- App renamed to MyAL (new name, same fox)
- Detail airing countdown now shows the latest aired and upcoming episode ("Ep 2 aired • Ep 3 Fri 22:00 • in 3d 1h 14m")
- Schedule rows now show the upcoming episode number ("Ep 3 in 5d 2h 35m")
- "Open in MyAnimeList" and "Share" buttons in the detail menu now work
- Media tab is now a real picture gallery (fullscreen viewer with pinch-to-zoom)
- Pull-to-refresh on Discover, Schedule, and Detail
- Fixed schedule countdowns drifting by the timezone gap (MAL broadcast times are JST)
- Fixed episode numbers never appearing on the detail page (start date was dropped from the detail data)

## [1.2.3] - 2026-10-13

- Detail header redesigned: poster with title language switcher (TI/EN/JA), bookmark and info buttons, plus an info panel (rank, score, format, aired, popularity, studios, members)
- My List search: filter your list by title as you type
- Posters now animate into the detail page (Hero transition)
- Haptic feedback on episode steppers, filter chips, and the Anime/Manga toggle
- Skeleton loading placeholders in My List and Discover
- Staggered entrance animations on lists, grids, and rails
- New page transitions (fade + slide) for detail, settings, news, and history
- Parallax collapsing header on the detail page
- Airing countdowns pulse gently each second
- Fixed profile statistics showing 0 entries/days and manga stats always empty
- Fixed profile picture not loading from MyAnimeList
- Fixed TI/EN/JA title switcher not changing the title (alt titles were dropped)
- Fixed countdown chip overlapping the tab bar
- Characters, Staff, Reviews, News, and Statistics now use the Tenrai API (Jikan's public API was discontinued)

## [1.2.2] - 2026-10-13

- New More Info tab: detailed metadata cards (media, episodes, status, premiered, aired dates, source, broadcast in your timezone, duration, rating, synonyms, alternative titles, studios, genres)
- My List rows redesigned: MAL score with list users, color-coded status badge, your score, live airing countdown, media info with genres
- Airing chip shows current episode and live countdown to the next episode, in your phone's timezone
- Synopsis tab cleaned up — detailed info moved to the More Info tab
- Fixed broadcast times showing wrong hours (timezone conversion) and countdowns not appearing
- Characters/Staff tabs: added User-Agent for Jikan requests and clearer error messages with retry
- Fixed Characters/Staff tabs showing empty lists on network errors — errors now surface with a retry button, plus automatic retry on rate limits

## [1.2.1] - 2026-10-13

- Settings restructured into a DailyAL-style menu with sub-screens (Theme Settings, List Preferences, About)
- In-app updater: check for updates manually or auto-check daily, download and install new versions without leaving the app
- Related tab now shows relation type badges (Sequel, Prequel, Side Story, etc.)

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
