import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/user.dart';

class LoginResult {
  final String? token;
  final String username;
  final String role;
  final bool otpRequired;
  final bool firstLogin;

  const LoginResult({
    this.token,
    required this.username,
    required this.role,
    required this.otpRequired,
    required this.firstLogin,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String?,
      username: json['username'] as String,
      role: json['role'] as String,
      otpRequired: json['otpRequired'] as bool? ?? false,
      firstLogin: json['firstLogin'] as bool? ?? false,
    );
  }
}

/// Handles the Livreur login flow (username/password, optional OTP,
/// session persistence). Admin login is out of scope for mobile.
class AuthRepository {
  final Dio _dio = DioClient.instance.dio;

  Future<LoginResult> login(String username, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });
      final result = LoginResult.fromJson(response.data as Map<String, dynamic>);
      if (!result.otpRequired && result.token != null) {
        await TokenStorage.instance.saveSession(
          token: result.token!,
          username: result.username,
          role: result.role,
        );
      }
      return result;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<LoginResult> verifyOtp(String username, String otpCode) async {
    try {
      final response = await _dio.post('/api/auth/verify-otp', data: {
        'username': username,
        'otpCode': otpCode,
      });
      final result = LoginResult.fromJson(response.data as Map<String, dynamic>);
      if (result.token != null) {
        await TokenStorage.instance.saveSession(
          token: result.token!,
          username: result.username,
          role: result.role,
        );
      }
      return result;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> resendOtp(String username) async {
    try {
      await _dio.post('/api/auth/resend-otp', data: {'username': username});
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<AppUser> getProfile() async {
    try {
      final response = await _dio.get('/api/auth/profile');
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _dio.post('/api/auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<AppUser> uploadProfilePhoto(dynamic imageFile) async {
    try {
      final String filePath = imageFile.path;
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _dio.post('/api/auth/profile-photo', data: formData);
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> logout() => TokenStorage.instance.clear();
}
