# MyAL v1.2.9
- Fixed manga detail pages (they fetched the anime endpoint and showed the wrong title): dedicated manga detail with authors, chapters/volumes, manga characters/reviews/statistics
- Reaching the final episode/chapter now flips the entry to Completed automatically; progress can no longer exceed the known total (also capped in the edit sheet)
- Fixed pull-to-refresh on the detail page (it never triggered: NestedScrollView only overscrolls its inner tab lists, which the default indicator predicate ignores)
- My List stepper now also refreshes the detail page cache, so the status pill is never stale when opening an entry

- Stepping an episode/chapter up on a "Plan to Watch" / "Plan to Read" entry now flips it to "Watching" / "Reading" automatically
- Material You dynamic colors: optional system wallpaper colors (Android 12+) in Theme Settings, replacing the accent presets when on

- Performance batch: News screen loads ~5x faster (parallel requests)
- My List: one shared ticker instead of a timer per row, minute-precision countdowns
- Search: 400ms debounce, queries only the visible tab
- My List status chips filter instantly, no refetch
- Episode/chapter stepper updates instantly with no reload flash
- Malformed deep links redirect home instead of crashing
- Detail gallery/viewer/banner use the disk image cache
- Poster color extraction moved off the UI thread


- Detail banner now glows with the poster's dominant color
- Detail pages have a full-width banner header again (poster cover with title overlay), keeping all info: score, rank, popularity, episodes, format, aired date, studios, members
- Fixed the accent picker checkmark being invisible on light accent colors
- List status colors (Watching, Completed…) now adapt to light/dark theme
- Removed the duplicate theme-mode picker from the theme setup screen
- System navigation bar now matches the app theme
- App background now takes a subtle tint of the chosen accent color
