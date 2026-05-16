import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;
        final horizontalPadding = isCompact ? 20.0 : 24.0;
        final verticalPadding = isCompact ? 14.0 : 24.0;

        Widget section(String title, List<String> lines) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isCompact ? 13 : 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      color: Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final sections = [
          section('Sistema de Incidencias', const [
            'Plataforma para reportar y gestionar incidencias urbanas',
          ]),
          section('Enlaces', const [
            'Reportar incidencia',
            'Ver incidencias',
            'Mi perfil',
          ]),
          section('Contacto', const [
            'Email: info@ejemploincidencias.es',
            'Teléfono: +34 111 222 333',
          ]),
        ];

        final compactSections = [
          section('Enlaces', const ['Reportar incidencia', 'Mis incidencias']),
          section('Contacto', const ['info@incidencias.es', '+34 111 222 333']),
        ];

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                children: [
                  isCompact
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sistema de Incidencias',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ayuntamiento de Cantillana',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: compactSections[0]),
                                const SizedBox(width: 16),
                                Expanded(child: compactSections[1]),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: sections[0]),
                            const SizedBox(width: 32),
                            Expanded(child: sections[1]),
                            const SizedBox(width: 32),
                            Expanded(child: sections[2]),
                          ],
                        ),
                  SizedBox(height: isCompact ? 14 : 24),
                  Divider(color: Colors.grey.shade700),
                  const SizedBox(height: 12),
                  Text(
                    '© 2026 Ayuntamiento de Cantillana. Todos los derechos reservados.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
