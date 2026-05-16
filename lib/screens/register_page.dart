import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

// PÁGINA DE REGISTRO: SIMILAR A LOGIN PERO CON VALIDACIÓNES DE CONTRASEÑA
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const double _formSpacing = 20;

  final nombreCtrl = TextEditingController();
  final apellidosCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
  final auth = AuthService();
  String? errorMsg;
  bool registrationSuccess = false;

  // Método para crear una nueva cuenta utilizando el servicio de autenticación.
  // Valida que las contraseñas coincidan antes de intentar registrarse.
  //Si el registro es exitoso, se navega a la página de inicio de sesión;
  //si ocurre un error, se muestra un mensaje.
  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidosCtrl.dispose();
    telefonoCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    pass2Ctrl.dispose();
    super.dispose();
  }

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
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
                      child: registrationSuccess
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mark_email_read_outlined,
                                  size: 64,
                                  color: Color(0xFF003366),
                                ),
                                const SizedBox(height: _formSpacing),
                                const Text(
                                  "Revisa tu correo",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003366),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Te hemos enviado un enlace de confirmación. Debes verificar tu correo antes de poder iniciar sesión.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF2D3436),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginPage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003366),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text("Ir al login"),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Crear cuenta",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003366),
                                  ),
                                ),

                                const SizedBox(height: _formSpacing),

                                if (errorMsg != null)
                                  Text(
                                    errorMsg!,
                                    style: const TextStyle(color: Colors.red),
                                  ),

                                TextField(
                                  controller: nombreCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Nombre",
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(height: _formSpacing),

                                TextField(
                                  controller: apellidosCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Apellidos",
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(height: _formSpacing),

                                TextField(
                                  controller: telefonoCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: "Teléfono (opcional)",
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(height: _formSpacing),

                                TextField(
                                  controller: emailCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Correo electrónico",
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(height: _formSpacing),

                                TextField(
                                  controller: passCtrl,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: "Contraseña",
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(height: _formSpacing),

                                TextField(
                                  controller: pass2Ctrl,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: "Repetir contraseña",
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (nombreCtrl.text.trim().isEmpty) {
                                        setState(
                                          () => errorMsg =
                                              "El nombre es obligatorio",
                                        );
                                        return;
                                      }

                                      if (apellidosCtrl.text.trim().isEmpty) {
                                        setState(
                                          () => errorMsg =
                                              "Los apellidos son obligatorios",
                                        );
                                        return;
                                      }

                                      if (emailCtrl.text.trim().isEmpty) {
                                        setState(
                                          () => errorMsg =
                                              "El correo es obligatorio",
                                        );
                                        return;
                                      }

                                      if (passCtrl.text.trim().isEmpty) {
                                        setState(
                                          () => errorMsg =
                                              "La contraseña es obligatoria",
                                        );
                                        return;
                                      }

                                      if (passCtrl.text != pass2Ctrl.text) {
                                        setState(
                                          () => errorMsg =
                                              "Las contraseñas no coinciden",
                                        );
                                        return;
                                      }

                                      final error = await auth.signUp(
                                        email: emailCtrl.text.trim(),
                                        password: passCtrl.text.trim(),
                                        nombre: nombreCtrl.text.trim(),
                                        apellidos: apellidosCtrl.text.trim(),
                                        telefono:
                                            telefonoCtrl.text.trim().isEmpty
                                            ? null
                                            : telefonoCtrl.text.trim(),
                                      );

                                      if (error == null && mounted) {
                                        setState(
                                          () => registrationSuccess = true,
                                        );
                                      } else {
                                        setState(() => errorMsg = error);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003366),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text("Crear cuenta"),
                                  ),
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
