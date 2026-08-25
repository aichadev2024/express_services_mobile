import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Single shared Dio instance for the whole app: attaches the JWT (when a
/// session exists) and turns backend error bodies into [ApiException].
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late final Dio dio = _build();

  Dio _build() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dioInstance.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          options.baseUrl = ApiConfig.baseUrl;

          final token = await TokenStorage.instance.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return dioInstance;
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
