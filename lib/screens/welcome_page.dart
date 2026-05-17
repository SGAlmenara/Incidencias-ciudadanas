import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_page.dart';

// PÁGINA DE BIENVENIDA PARA USUARIOS NO AUTENTICADOS,
//Y BOTÓN PRINCIPAL PARA INICIAR SESIÓN O REGISTRARSE
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowMobile = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // FONDO DEGRADADO
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFFFFF), Color(0xFFE9ECEF)],
                ),
              ),
            ),
          ),

          // IMAGEN DE FONDO CON MÁSCARA
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/cantillana-sevilla.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // CONTENIDO PRINCIPAL
          SafeArea(
            child: Column(
              children: [
                // 4. HEADER (lo mejoramos después)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrowMobile ? 14 : 24,
                    vertical: isNarrowMobile ? 14 : 20,
                  ),
                  child: isNarrowMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: 'logo_ayto',
                              child: Image.asset(
                                "assets/images/Escudo_de_Cantillana.png",
                                height: 44,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "AYUNTAMIENTO DE",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.9,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Text(
                              "Cantillana",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2D3436),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Hero(
                              tag: 'logo_ayto',
                              child: Image.asset(
                                "assets/images/Escudo_de_Cantillana.png",
                                height: 55,
                              ),
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

                const Spacer(),

                // CARD GLASSMORPHISM
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 380, // tamaño card
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  26,
                                  86,
                                  26,
                                  26,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFC8EDD6,
                                  ).withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.50),
                                    width: 1.3,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      "Incidencias\nCiudadanas",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1A1A1A),
                                        height: 1.1,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      "Tu colaboración hace un municipio mejor.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),

                                    const SizedBox(height: 22),

                                    _buildMainButton(context),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -44,
                            child: Container(
                              width: 128,
                              height: 128,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFC8EDD6),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/c0.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // FOOTER
                Padding(
                  padding: EdgeInsets.only(bottom: isNarrowMobile ? 16 : 24),
                  child: Text(
                    "Copyright © 2026 Ayuntamiento de Cantillana",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isNarrowMobile ? 10 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir el botón principal que redirige a la página de inicio de sesión.
  // El botón tiene un estilo personalizado con colores, padding, bordes redondeados
  // y sombra para mejorar su apariencia.
  Widget _buildMainButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A90E2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF4A90E2).withOpacity(0.4),
        ),
        child: const Text(
          "Reportar incidencia",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
