import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Registro con email
  Future<String?> signUp(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) return null;
      return "No se pudo crear la cuenta.";
    } catch (e) {
      return e.toString();
    }
  }

  // Login con email
  Future<String?> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Login con Google
  Future<String?> signInWithGoogle() async {
    try {
      final origin = Uri.base.origin;

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: origin,
      );

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Logout
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Verificar si el usuario es administrador
  Future<bool> isAdmin() async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return false;

    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return data != null && data['role'] == 'admin';
  }
}
