import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:malclient/src/core/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MAL OAuth2 (PKCE) + token storage.
///
/// The full login flow:
///   1. [beginLogin] builds the authorize URL (generating + storing the
///      PKCE verifier) — the app opens it in the browser.
///   2. MAL redirects to `malclient://oauth?code=...` (intent-filter in
///      AndroidManifest.xml); the app captures it via app_links.
///   3. [exchangeCode] trades the code for access/refresh tokens.
///   4. [getValidAccessToken] / [refresh] keep the token usable.
class AuthRepository {
  final FlutterSecureStorage _storage;
  final SharedPreferences _prefs;
  final Dio _tokenDio = Dio();

  static const _kAccess = 'mal_access_token';
  static const _kRefresh = 'mal_refresh_token';
  static const _kExpiry = 'mal_token_expiry_ms';
  static const _kVerifier = 'mal_code_verifier';
  static const _kDemo = 'demo_mode';

  AuthRepository(this._storage, this._prefs);

  // ---------- demo mode ----------

  Future<bool> isDemoMode() async => _prefs.getBool(_kDemo) ?? false;

  Future<void> setDemoMode(bool value) => _prefs.setBool(_kDemo, value);

  // ---------- tokens ----------

  Future<String?> getAccessToken() => _storage.read(key: _kAccess);

  Future<DateTime?> _expiry() async {
    final ms = await _storage.read(key: _kExpiry);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.tryParse(ms) ?? 0);
  }

  /// Returns a usable access token, refreshing first if it is expired.
  /// Returns null when the user is not logged in.
  Future<String?> getValidAccessToken() async {
    final token = await getAccessToken();
    if (token == null) return null;
    final expiry = await _expiry();
    if (expiry != null &&
        DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 2)))) {
      final ok = await refresh();
      if (!ok) return null;
      return getAccessToken();
    }
    return token;
  }

  Future<bool> hasTokens() async => await getAccessToken() != null;

  Future<void> _saveTokens(Map<String, dynamic> json) async {
    final access = json['access_token'] as String?;
    final refresh = json['refresh_token'] as String?;
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 0;
    if (access == null) throw const FormatException('No access_token');
    await _storage.write(key: _kAccess, value: access);
    if (refresh != null) await _storage.write(key: _kRefresh, value: refresh);
    await _storage.write(
      key: _kExpiry,
      value: DateTime.now()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch
          .toString(),
    );
  }

  /// Tries to refresh the access token. Returns false when there is no
  /// refresh token or the refresh failed (caller should log out).
  Future<bool> refresh() async {
    final refreshToken = await _storage.read(key: _kRefresh);
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final res = await _tokenDio.post(
        malTokenUrl,
        data: {
          'grant_type': 'refresh_token',
          'client_id': malClientId,
          'refresh_token': refreshToken,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      await _saveTokens(res.data as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- PKCE login ----------

  String _makeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(96, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  String _challengeFor(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Builds the MAL authorize URL and stores the PKCE verifier for the
  /// later token exchange.
  Future<Uri> beginLogin() async {
    final verifier = _makeVerifier();
    await _storage.write(key: _kVerifier, value: verifier);
    return Uri.parse(malAuthorizeUrl).replace(queryParameters: {
      'response_type': 'code',
      'client_id': malClientId,
      'redirect_uri': malRedirectUri,
      'code_challenge': _challengeFor(verifier),
      'code_challenge_method': 'S256',
    });
  }

  /// Exchanges the `code` from the `malclient://oauth` redirect for tokens.
  Future<void> exchangeCode(String code) async {
    final verifier = await _storage.read(key: _kVerifier);
    if (verifier == null) {
      throw StateError('No PKCE verifier stored; restart login.');
    }
    final res = await _tokenDio.post(
      malTokenUrl,
      data: {
        'grant_type': 'authorization_code',
        'client_id': malClientId,
        'code': code,
        'code_verifier': verifier,
        'redirect_uri': malRedirectUri,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    await _storage.delete(key: _kVerifier);
    await setDemoMode(false);
    await _saveTokens(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kExpiry);
    await _storage.delete(key: _kVerifier);
    await setDemoMode(false);
  }
}
