import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp(String email, String password) async {
    final res = await _client.auth.signUp(
      AuthSignUpOptions(
        email: email,
        password: password,
      ),
    );
    return res;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return res;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
