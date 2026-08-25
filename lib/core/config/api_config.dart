import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiConfig {
  static const String _productionUrl = 'https://express-services-backend.onrender.com';

  static String get baseUrl => _productionUrl;

  static Future<void> init() async {}

  static Future<void> setBaseUrl(String newUrl) async {}
}
