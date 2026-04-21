import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  String _safeAuthErrorMessage(Object error, {required String fallback}) {
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

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
      debugPrint('signUp error: $e');
      return _safeAuthErrorMessage(
        e,
        fallback: 'No se pudo crear la cuenta. Intentalo de nuevo.',
      );
    }
  }

  // Login con email
  Future<String?> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } catch (e) {
      debugPrint('signIn error: $e');
      return _safeAuthErrorMessage(
        e,
        fallback: 'No se pudo iniciar sesion. Revisa tus credenciales.',
      );
    }
  }

  // Login con Google
  Future<String?> signInWithGoogle() async {
    try {
      final redirectTo = kIsWeb
          ? Uri.base.origin
          : 'com.example.incidencias_app://login-callback/';

      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      return null;
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      return _safeAuthErrorMessage(
        e,
        fallback: 'No se pudo iniciar sesion con Google. Intentalo de nuevo.',
      );
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
