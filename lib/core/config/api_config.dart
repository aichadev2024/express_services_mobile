import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ApiConfig {
  static const String _productionUrl = 'https://api.express-services-mali.com/api';

  static String get baseUrl => _productionUrl;

  static Future<void> init() async {}

  static Future<void> setBaseUrl(String newUrl) async {}
}
