import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';

import '../../../models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? username;
  final String? role;
  final AppUser? user;

  const AuthState({
    this.isLoading = true,
    this.isAuthenticated = false,
    this.username,
    this.role,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? username,
    String? role,
    AppUser? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      role: role ?? this.role,
      user: user ?? this.user,
    );
  }
}

/// Tracks whether a Livreur session is active, restored from secure storage
/// on startup. Drives route guarding for the /livreur/* screens.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _restore();
    return const AuthState();
  }

  Future<void> _restore() async {
    final token = await TokenStorage.instance.readToken();
    final username = await TokenStorage.instance.readUsername();
    final role = await TokenStorage.instance.readRole();
    AppUser? user;
    if (token != null) {
      try {
        user = await ref.read(authRepositoryProvider).getProfile();
      } catch (_) {}
    }
    state = AuthState(
      isLoading: false,
      isAuthenticated: token != null,
      username: username,
      role: role,
      user: user,
    );
  }

  Future<LoginResult> login(String username, String password) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(username, password);
    if (!result.otpRequired) {
      AppUser? user;
      try {
        user = await repo.getProfile();
      } catch (_) {}
      state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        username: result.username,
        role: result.role,
        user: user,
      );
    }
    return result;
  }

  Future<LoginResult> verifyOtp(String username, String otpCode) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.verifyOtp(username, otpCode);
    AppUser? user;
    try {
      user = await repo.getProfile();
    } catch (_) {}
    state = AuthState(
      isLoading: false,
      isAuthenticated: true,
      username: result.username,
      role: result.role,
      user: user,
    );
    return result;
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.changePassword(oldPassword, newPassword);
  }

  Future<AppUser> uploadProfilePhoto(dynamic imageFile) async {
    final repo = ref.read(authRepositoryProvider);
    final updatedUser = await repo.uploadProfilePhoto(imageFile);
    state = state.copyWith(user: updatedUser);
    return updatedUser;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState(isLoading: false, isAuthenticated: false);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
