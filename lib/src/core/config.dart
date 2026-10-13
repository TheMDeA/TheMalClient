/// MAL API configuration.
///
/// To enable real MyAnimeList login + data:
///   1. Go to https://myanimelist.net/apiconfig and create a new API app.
///   2. Set the "App Redirect URL" to: malclient://oauth
///   3. Copy the "Client ID" and "Client Secret" and paste them below.
///
/// Until a real client ID is set, the app runs in demo mode with bundled
/// sample data so the whole UI is reviewable without API access.
const malClientId = '1389acd530b4ad395a643ebaa77c8f14';

/// MAL client secret (MAL Scheme 2). For a mobile/public client this is not
/// truly secret — it ships in the app — but MAL's token endpoint requires it
/// whenever the registered app has one ("Client authentication failed"
/// otherwise).
const malClientSecret = '7a4bc7eb6080f0201f908faa5abffd12d44ac39f3ca331dfa32980950b36804e';

/// Must match the "App Redirect URL" registered at myanimelist.net/apiconfig
/// AND the intent-filter in AndroidManifest.xml.
const malRedirectUri = 'malclient://oauth';

const malAuthorizeUrl = 'https://myanimelist.net/v1/oauth2/authorize';
const malTokenUrl = 'https://myanimelist.net/v1/oauth2/token';
const malApiBase = 'https://api.myanimelist.net/v2';

/// Jikan (unofficial MAL API) — free, no key. Used for reviews,
/// recommendations and news, which MAL API v2 does not provide.
const tenraiApiBase = 'https://api.tenrai.org/v1';

bool get hasRealClientId =>
    malClientId != 'YOUR_CLIENT_ID' && malClientId.trim().isNotEmpty;
