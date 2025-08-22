import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/models.dart';

class AuthState {
  final User? user;
  final bool loading;
  final String? error;
  const AuthState({this.user, this.loading = false, this.error});

  AuthState copyWith({User? user, bool? loading, String? error}) =>
      AuthState(user: user ?? this.user, loading: loading ?? this.loading, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repo;
  AuthNotifier(this.repo) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = await repo.login(email, password);
      state = state.copyWith(user: user, loading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), loading: false);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  throw UnimplementedError('Provide AuthRepository via override at app start');
});