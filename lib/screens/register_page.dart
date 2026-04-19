import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
  final auth = AuthService();
  String? errorMsg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(32),
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(blurRadius: 10, color: Colors.black12),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Crear cuenta",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003366),
                  ),
                ),

                const SizedBox(height: 20),

                if (errorMsg != null)
                  Text(errorMsg!, style: const TextStyle(color: Colors.red)),

                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                ),

                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña"),
                ),

                TextField(
                  controller: pass2Ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Repetir contraseña",
                  ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (passCtrl.text != pass2Ctrl.text) {
                      setState(() => errorMsg = "Las contraseñas no coinciden");
                      return;
                    }

                    final error = await auth.signUp(
                      emailCtrl.text.trim(),
                      passCtrl.text.trim(),
                    );

                    if (error == null && mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    } else {
                      setState(() => errorMsg = error);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Crear cuenta"),
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Volver al login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
