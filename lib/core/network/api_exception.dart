/// Thrown by repositories when a backend call fails, carrying a
/// user-facing message extracted from the response body when possible.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
