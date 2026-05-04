import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';
import 'role_gate.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final auth = AuthService();
  String? errorMsg;
  bool isGoogleLoading = false;

  Future<void> _loginEmail() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    final result = await auth.signIn(email, pass);

    if (result != null) {
      setState(() => errorMsg = result);
      return;
    }

    if (!mounted) return;

    // LOGIN OK, RoleGate decide destino según rol
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleGate()),
    );
  }

  // Método para iniciar sesión con Google, utilizando el servicio de autenticación. Si ocurre un error, se muestra un mensaje; si el inicio de sesión es exitoso, se navega a la página RoleGate para redirigir según el rol del usuario.
  Future<void> _loginGoogle() async {
    if (isGoogleLoading) return;

    setState(() {
      isGoogleLoading = true;
      errorMsg = null;
    });

    final result = await auth.signInWithGoogle();

    if (result != null && mounted) {
      setState(() => errorMsg = result);
    }

    if (mounted) {
      setState(() => isGoogleLoading = false);
    }

    if (result != null) {
      return;
    }

    // En OAuth, la navegación la resuelve el stream de sesión en main.dart
    // cuando Supabase termina de establecer la sesión tras el callback.
  }

  // Método build para mostrar la interfaz de inicio de sesión,
  //con campos para correo electrónico y contraseña,
  //así como botones para iniciar sesión con email o Google.
  //También incluye un enlace para registrarse si no se tiene una cuenta.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Image.asset(
                    "assets/images/Escudo_de_Cantillana.png",
                    height: 55,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AYUNTAMIENTO DE",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Text(
                        "Cantillana",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2D3436),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CARD CENTRADA
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 12,
                        color: Colors.black12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Iniciar sesión",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003366),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (errorMsg != null)
                        Text(
                          errorMsg!,
                          style: const TextStyle(color: Colors.red),
                        ),

                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: "Correo electrónico",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Contraseña",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loginEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text("Entrar"),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: isGoogleLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Image.asset("assets/google.png", height: 24),
                          label: Text(
                            isGoogleLoading
                                ? "Abriendo Google..."
                                : "Iniciar sesión con Google",
                          ),
                          onPressed: isGoogleLoading ? null : _loginGoogle,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.black54),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text("¿No tienes cuenta? Regístrate"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FOOTER
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                "Copyright © 2026 Ayuntamiento de Cantillana",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
