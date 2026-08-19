import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiConfig {
  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://express-services-backend.onrender.com',
  );

  static const _storageKey = 'custom_api_base_url';
  static final _storage = const FlutterSecureStorage();

  static String _currentBaseUrl = _defaultUrl;

  /// Candidate URLs for automatic fallback attempt when primary fails
  static final List<String> candidateUrls = [
    'https://express-services-backend.onrender.com',
    'http://localhost:8080',
    'http://172.20.14.187:8080',
    'http://10.0.2.2:8080',
  ];

  static String get baseUrl => _currentBaseUrl;

  /// Initializes the base URL from local storage if previously saved.
  static Future<void> init() async {
    try {
      final savedUrl = await _storage.read(key: _storageKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _currentBaseUrl = savedUrl.trim();
      }
    } catch (_) {}
  }

  /// Sets a new base URL and persists it.
  static Future<void> setBaseUrl(String newUrl) async {
    final formatted = newUrl.trim().replaceAll(RegExp(r'/$'), '');
    _currentBaseUrl = formatted;
    try {
      await _storage.write(key: _storageKey, value: formatted);
    } catch (_) {}
  }
}
