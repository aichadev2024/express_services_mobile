import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Single shared Dio instance for the whole app: attaches the JWT (when a
/// session exists) and turns backend error bodies into [ApiException].
///
/// Features automatic fallback candidate host discovery (e.g. testing local IP
/// if localhost/ADB reverse is unreachable).
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late final Dio dio = _build();

  bool _isAttemptingFallback = false;

  Dio _build() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Always use the latest dynamic baseUrl
          options.baseUrl = ApiConfig.baseUrl;

          final token = await TokenStorage.instance.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Auto-fallback for connection errors or timeouts
          if ((error.type == DioExceptionType.connectionError ||
                  error.type == DioExceptionType.connectionTimeout) &&
              !_isAttemptingFallback) {
            _isAttemptingFallback = true;
            try {
              final workingUrl = await _findWorkingCandidateUrl(error.requestOptions.path);
              if (workingUrl != null) {
                await ApiConfig.setBaseUrl(workingUrl);
                
                // Retry the original request with the new working baseUrl
                final opts = error.requestOptions;
                opts.baseUrl = workingUrl;
                final response = await dioInstance.fetch(opts);
                return handler.resolve(response);
              }
            } catch (_) {
            } finally {
              _isAttemptingFallback = false;
            }
          }
          handler.next(error);
        },
      ),
    );

    return dioInstance;
  }

  /// Tries candidate URLs by making a fast lightweight HEAD/GET request.
  Future<String?> _findWorkingCandidateUrl(String path) async {
    final checkDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    for (final candidate in ApiConfig.candidateUrls) {
      if (candidate == ApiConfig.baseUrl) continue;
      try {
        final res = await checkDio.get('$candidate/api/quartiers');
        if (res.statusCode == 200) {
          return candidate;
        }
      } catch (_) {}
    }
    return null;
  }
}

/// Converts a [DioException] into an [ApiException] with a readable message.
ApiException toApiException(DioException e) {
  final statusCode = e.response?.statusCode;
  final data = e.response?.data;

  if (data is Map && data['error'] is String) {
    return ApiException(data['error'] as String, statusCode: statusCode);
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return ApiException(
        "Le serveur met trop de temps à répondre (Hôte: ${ApiConfig.baseUrl}). Vérifiez que le serveur est démarré.",
      );
    case DioExceptionType.connectionError:
      return ApiException(
        "Impossible de contacter le serveur sur ${ApiConfig.baseUrl}. Vérifiez votre connexion Wi-Fi / IP.",
      );
    default:
      if (statusCode == 401) {
        return const ApiException(
          "Session expirée ou identifiants invalides.",
          statusCode: 401,
        );
      }
      if (statusCode == 403) {
        return const ApiException(
          "Accès non autorisé.",
          statusCode: 403,
        );
      }
      return ApiException(
        "Une erreur est survenue. Réessayez.",
        statusCode: statusCode,
      );
  }
}
