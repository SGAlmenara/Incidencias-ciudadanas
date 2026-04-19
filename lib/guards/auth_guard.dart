import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_page.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    // Si no hay sesión → enviar al login
    if (session == null) {
      return const LoginPage();
    }

    // Si hay sesión → mostrar la pantalla protegida
    return child;
  }
}
