import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT and the logged-in user's role/username across app
/// restarts, for the Livreur (and Admin, if ever needed) auth flow.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  final _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _usernameKey = 'auth_username';
  static const _roleKey = 'auth_role';

  Future<void> saveSession({
    required String token,
    required String username,
    required String role,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);
  Future<String?> readUsername() => _storage.read(key: _usernameKey);
  Future<String?> readRole() => _storage.read(key: _roleKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _roleKey);
  }
}
