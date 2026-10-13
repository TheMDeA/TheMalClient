import 'package:dio/dio.dart';
import 'package:malclient/src/core/config.dart';

/// All MAL API v2 traffic goes through this one client.
///
/// Auth strategy:
/// - Logged in: `Authorization: Bearer <access_token>` (auto-refreshed).
/// - Not logged in but a Client ID is configured:
///   `X-MAL-CLIENT-ID` header — enough for public endpoints
///   (seasonal, ranking, search, details). User lists still need OAuth.
class MalApiClient {
  final Dio dio;

  MalApiClient({
    required Future<String?> Function() getAccessToken,
    required Future<bool> Function() refreshToken,
  }) : dio = Dio(BaseOptions(
          baseUrl: malApiBase,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else if (hasRealClientId) {
            options.headers['X-MAL-CLIENT-ID'] = malClientId;
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final req = error.requestOptions;
          final alreadyRetried = req.extra['retried_after_401'] == true;
          if (error.response?.statusCode == 401 && !alreadyRetried) {
            final refreshed = await refreshToken();
            if (refreshed) {
              final token = await getAccessToken();
              req.extra['retried_after_401'] = true;
              if (token != null && token.isNotEmpty) {
                req.headers['Authorization'] = 'Bearer $token';
              }
              try {
                final response = await dio.fetch(req);
                return handler.resolve(response);
              } catch (_) {
                // fall through to the original error
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }
}
