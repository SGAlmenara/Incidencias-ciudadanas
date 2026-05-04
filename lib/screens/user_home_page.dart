import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_scaffold.dart';
import 'create_incident_page.dart';
import 'user_incidents_page.dart';
import 'user_comments_page.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  String _displayName(User? user) {
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final nombre = (metadata['nombre'] ?? metadata['name'] ?? '')
        .toString()
        .trim();
    final apellidos = (metadata['apellidos'] ?? '').toString().trim();
    final fullName = [
      nombre,
      apellidos,
    ].where((part) => part.isNotEmpty).join(' ').trim();

    if (fullName.isNotEmpty) return fullName;
    final email = (user?.email ?? '').trim();
    if (email.isNotEmpty) return email;
    return 'usuario';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = _displayName(user);

    return AppScaffold(
      title: 'Inicio',
      subtitle: 'Bienvenido, $name',
      isAdmin: false,
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
                  colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/cantillana-sevilla.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // CONTENIDO
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.waving_hand_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Bienvenido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '¿Qué deseas hacer hoy?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: 360,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Nueva incidencia'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateIncidentPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 360,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text('Mis incidencias'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(
                            color: Colors.blue.shade700,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserIncidentsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 360,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.forum_outlined),
                        label: const Text('Mis comentarios'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade700,
                          side: BorderSide(
                            color: Colors.teal.shade700,
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserCommentsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
