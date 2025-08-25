import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/failure.dart';
import '../data/auth_repository.dart';
import '../data/models.dart';

class AuthState {
  final User? user;
  final bool loading;
  final Failure? error;
  final bool isAuthenticated;
  
  const AuthState({
    this.user, 
    this.loading = false, 
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user, 
    bool? loading, 
    Failure? error,
    bool? isAuthenticated,
  }) =>
      AuthState(
        user: user ?? this.user, 
        loading: loading ?? this.loading, 
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repo;
  AuthNotifier(this.repo) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await repo.isAuthenticated();
    state = state.copyWith(isAuthenticated: isAuth);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await repo.login(email, password);
      state = state.copyWith(
        user: user, 
        loading: false, 
        isAuthenticated: true,
      );
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
    }
  }

  Future<void> register(String email, String password, String name, String phoneNumber) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await repo.register(email, password, name, phoneNumber);
      state = state.copyWith(
        user: user, 
        loading: false, 
        isAuthenticated: true,
      );
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
    }
  }

  Future<void> sendEmailVerification() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await repo.sendEmailVerification();
      state = state.copyWith(loading: false);
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await repo.forgotPassword(email);
      state = state.copyWith(loading: false);
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
    }
  }

  Future<void> refreshToken() async {
    try {
      await repo.refreshToken();
      await _checkAuthStatus();
    } on Failure {
      // If refresh fails, user is no longer authenticated
      state = state.copyWith(isAuthenticated: false);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await repo.logout();
      state = state.copyWith(
        user: null, 
        loading: false, 
        isAuthenticated: false,
      );
    } on Failure catch (e) {
      state = state.copyWith(error: e, loading: false);
    } catch (e) {
      state = state.copyWith(
        error: UnknownFailure(e.toString()), 
        loading: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  throw UnimplementedError('Provide AuthRepository via override at app start');
});