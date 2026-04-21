import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                255,
                                201,
                                248,
                                217,
                              ).withOpacity(0.38),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.50),
                                width: 1.3,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      23,
                                      118,
                                      250,
                                    ).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    size: 36,
                                    color: Color.fromARGB(255, 23, 118, 250),
                                  ),
                                ),

                                const SizedBox(height: 18),

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
                    ),
                  ),
                ),

                const Spacer(),

                // FOOTER
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    "Copyright © 2026 Ayuntamiento de Cantillana, todos los derechos reservados",
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
        ],
      ),
    );
  }

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
