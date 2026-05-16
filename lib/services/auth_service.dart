import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<bool> isEmailBlocked(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return false;

    try {
      final blocked = await supabase
          .from('blocked_emails')
          .select('email')
          .eq('email', normalizedEmail)
          .maybeSingle();
      return blocked != null;
    } catch (e) {
      debugPrint('isEmailBlocked error: $e');
      return false;
    }
  }

  Future<void> ensureCurrentUserProfile({
    String? nombre,
    String? apellidos,
    String? telefono,
    String? email,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final existing = await supabase
        .from('profiles')
        .select('id, email, nombre, apellidos, telefono')
        .eq('id', user.id)
        .maybeSingle();

    String firstNonEmpty(List<String?> values) {
      for (final value in values) {
        final normalized = (value ?? '').trim();
        if (normalized.isNotEmpty) return normalized;
      }
      return '';
    }

    final normalizedEmail = firstNonEmpty([
      email,
      user.email,
      existing?['email']?.toString(),
    ]).toLowerCase();

    final firstName = firstNonEmpty([
      nombre,
      metadata['nombre']?.toString(),
      metadata['name']?.toString(),
      existing?['nombre']?.toString(),
    ]);

    final lastName = firstNonEmpty([
      apellidos,
      metadata['apellidos']?.toString(),
      existing?['apellidos']?.toString(),
    ]);
    final safeLastName = lastName.isNotEmpty ? lastName : 'Sin apellido';

    final phone = firstNonEmpty([
      telefono,
      metadata['telefono']?.toString(),
      user.phone,
      existing?['telefono']?.toString(),
    ]);

    final payload = <String, dynamic>{
      'id': user.id,
      // Keep required profile fields non-null when creating missing rows.
      'nombre': firstName.isNotEmpty ? firstName : 'Usuario',
      'apellidos': safeLastName,
    };
    if (normalizedEmail.isNotEmpty) payload['email'] = normalizedEmail;
    if (phone.isNotEmpty) payload['telefono'] = phone;

    await supabase.from('profiles').upsert(payload);
  }

  String _safeAuthErrorMessage(Object error, {required String fallback}) {
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    return fallback;
  }

  // Registro con email
  Future<String?> signUp({
    required String email,
    required String password,
    required String nombre,
    required String apellidos,
    String? telefono,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      final blocked = await isEmailBlocked(normalizedEmail);
      if (blocked) {
        return 'Este correo esta bloqueado y no puede volver a registrarse.';
      }

      final response = await supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {'nombre': nombre, 'apellidos': apellidos, 'telefono': telefono},
      );

      final user = response.user;

      if (user != null) {
        try {
          await ensureCurrentUserProfile(
            email: normalizedEmail,
            nombre: nombre,
            apellidos: apellidos,
            telefono: telefono,
          );
        } catch (profileError) {
          debugPrint('Profile upsert error: $profileError');
          return 'No se pudo completar el perfil del usuario.';
        }

        return null;
      }
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
      final normalizedEmail = email.trim().toLowerCase();

      await supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      try {
        await ensureCurrentUserProfile(email: normalizedEmail);
      } catch (profileError) {
        debugPrint('Profile sync on signIn error: $profileError');
      }

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

    try {
      await ensureCurrentUserProfile();
    } catch (e) {
      debugPrint('ensureCurrentUserProfile in isAdmin error: $e');
    }

    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    final role = (data?['role'] ?? 'user').toString().trim().toLowerCase();
    return role == 'admin';
  }
}
