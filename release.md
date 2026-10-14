# MyAL v1.3.0
- List Preferences: choose default tabs for the My List screen (anime/manga section, anime status, manga status); 'None' falls back to the last opened tab
- Fixed the detail-page airing countdown not showing aired/next episode info when MAL reports an unknown episode total
- The stepper's status flips now also apply the date auto-setters (start date on Watching, finish date on Completed)
- The stepper now asks for confirmation before auto-completing an entry at its final episode/chapter
- Fixed manga detail pages (they fetched the anime endpoint and showed the wrong title): dedicated manga detail with authors, chapters/volumes, manga characters/reviews/statistics
- Reaching the final episode/chapter now flips the entry to Completed automatically; progress can no longer exceed the known total (also capped in the edit sheet)
- Fixed pull-to-refresh on the detail page (it never triggered: NestedScrollView only overscrolls its inner tab lists, which the default indicator predicate ignores)
- My List stepper now also refreshes the detail page cache, so the status pill is never stale when opening an entry
- Stepping an episode/chapter up on a "Plan to Watch" / "Plan to Read" entry now flips it to "Watching" / "Reading" automatically
