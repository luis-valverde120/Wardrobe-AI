import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // SOLO usamos .auth.signUp. Nada de .from('profiles')
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
    } catch (e) {
      throw Exception('Error al registrarse: ${e.toString()}');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Credenciales incorrectas: ${e.toString()}');
    }
  }
}
