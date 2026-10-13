# MALClient v1.0.3

Login fix: PKCE now uses the `plain` method required by MyAnimeList's API.

- Fixed MyAnimeList login: PKCE code challenge now uses `plain` instead of S256, matching MAL's API specification
