/// MAL API configuration.
///
/// To enable real MyAnimeList login + data:
///   1. Go to https://myanimelist.net/apiconfig and create a new API app.
///   2. Set the "App Redirect URL" to: malclient://oauth
///   3. Copy the "Client ID" and paste it below.
///
/// Until a real client ID is set, the app runs in demo mode with bundled
/// sample data so the whole UI is reviewable without API access.
const malClientId = '3da8b7f2721431cd6adb3740d5c51d60';

/// Must match the "App Redirect URL" registered at myanimelist.net/apiconfig
/// AND the intent-filter in AndroidManifest.xml.
const malRedirectUri = 'malclient://oauth';

const malAuthorizeUrl = 'https://myanimelist.net/v1/oauth2/authorize';
const malTokenUrl = 'https://myanimelist.net/v1/oauth2/token';
const malApiBase = 'https://api.myanimelist.net/v2';

/// Jikan (unofficial MAL API) — free, no key. Used for reviews,
/// recommendations and news, which MAL API v2 does not provide.
const jikanApiBase = 'https://api.jikan.moe/v4';

bool get hasRealClientId =>
    malClientId != 'YOUR_CLIENT_ID' && malClientId.trim().isNotEmpty;
