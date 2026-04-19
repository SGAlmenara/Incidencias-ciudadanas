import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_page.dart';

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

  Future<void> _loginEmail() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    final result = await auth.signIn(email, pass);

    if (result != null) {
      setState(() => errorMsg = result);
    }
    // NO navegamos aquí → lo hace main.dart automáticamente
  }

  Future<void> _loginGoogle() async {
    final result = await auth.signInWithGoogle();

    if (result != null) {
      setState(() => errorMsg = result);
    }
    // NO navegamos aquí → lo hace main.dart automáticamente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Iniciar sesión",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

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

              if (errorMsg != null)
                Text(errorMsg!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loginEmail,
                  child: const Text("Entrar"),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Image.asset("assets/google.png", height: 24),
                  label: const Text("Iniciar sesión con Google"),
                  onPressed: _loginGoogle,
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: const Text("¿No tienes cuenta? Regístrate"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
