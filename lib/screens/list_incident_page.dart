import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_scaffold.dart';
import '../models/incident.dart';
import 'edit_incident_page.dart';
import '../services/incident_service.dart';
import '../widgets/back_fab.dart';
import '../widgets/status_badge.dart';

// PÁGINA DE DETALLE DE INCIDENCIA (ACCESIBLE DESDE LIST_INCIDENT_PAGE Y ADMIN_INCIDENT_LIST_PAGE)
class IncidentDetailPage extends StatelessWidget {
  final Map<String, dynamic> incident;
  final bool isAdmin;

  const IncidentDetailPage({
    super.key,
    required this.incident,
    required this.isAdmin,
  });

  // MÉTODO PARA MOSTRAR IMAGEN AMPLIADA EN UNA NUEVA PANTALLA
  void _mostrarImagenAmpliada(BuildContext context, String base64img) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1,
                maxScale: 4,
                child: Image.memory(
                  base64Decode(base64img),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MÉTODO PARA CONFIRMAR ELIMINACIÓN DE INCIDENCIA
  Future<void> _confirmarEliminar(BuildContext context, String id) async {
    final bool? confirmar = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar incidencia"),
        content: const Text(
          "¿Seguro que deseas eliminar esta incidencia? Esta acción no se puede deshacer.",
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final ok = await IncidentService().deleteIncident(id);
      if (!context.mounted) return;

      if (ok) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar en base de datos')),
        );
      }
    }
  }

  // MÉTODO PARA CREAR CARDS DE INFORMACIÓN (UBICACIÓN, DESCRIPCIÓN, ETC.)
  @override
  Widget build(BuildContext context) {
    final inc = Incident.fromMap(incident);

    return Stack(
      children: [
        AppScaffold(
          title: "Detalle de incidencia",
          isAdmin: isAdmin,
          body: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Incidente reportado",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildIncidentReportedCard(context, inc),

                      const SizedBox(height: 24),

                      // CARRUSEL DE IMÁGENES
                      if (inc.hasImages) ...[
                        const Text(
                          "Imágenes",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 240,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: inc.imgUrls.map((img) {
                              return GestureDetector(
                                onTap: () =>
                                    _mostrarImagenAmpliada(context, img),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 280,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.memory(
                                        base64Decode(img),
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.7,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.touch_app,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "Toca para ampliar",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // INFORMACIÓN PRINCIPAL EN CARDS
                      _buildInfoCard(
                        icon: Icons.location_on,
                        iconColor: Colors.red,
                        title: "Ubicación",
                        content: inc.direccion ?? "Sin dirección especificada",
                      ),

                      const SizedBox(height: 16),

                      _buildInfoCard(
                        icon: Icons.description,
                        iconColor: Colors.blue,
                        title: "Descripción",
                        content: inc.descripcion ?? "Sin descripción",
                      ),

                      const SizedBox(height: 24),

                      // MAPA
                      if (inc.latitud != null && inc.longitud != null) ...[
                        const Text(
                          "Ubicación en mapa",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(inc.latitud!, inc.longitud!),
                              zoom: 16,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("incident"),
                                position: LatLng(inc.latitud!, inc.longitud!),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueRed,
                                ),
                              ),
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // BOTONES DE ACCIÓN
                      const Text(
                        "Acciones",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButtons(context, inc),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // BOTÓN FLOTANTE ABAJO A LA IZQUIERDA
        const Positioned(bottom: 20, left: 20, child: BackFAB()),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MÉTODO PARA CREAR BOTONES DE ACCIÓN (VER EN MAPA, EDITAR, ELIMINAR)
  Widget _buildActionButtons(BuildContext context, Incident inc) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text("Ver en Google Maps"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            onPressed: () async {
              final url =
                  "https://www.google.com/maps/search/?api=1&query=${inc.latitud},${inc.longitud}";
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text("Editar incidencia"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Colors.amber, width: 2),
              foregroundColor: Colors.amber.shade700,
            ),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditIncidentPage(incident: inc.toMap()),
                ),
              );

              if (updated == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ),

        if (isAdmin) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever),
              label: const Text("Eliminar incidencia"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: () => _confirmarEliminar(context, inc.id),
            ),
          ),
        ],
      ],
    );
  }

  // MÉTODO PARA CREAR CARD PRINCIPAL CON INFORMACIÓN DESTACADA
  //(TÍTULO, ESTADO, FECHA, BOTÓN DE EDICIÓN)
  Widget _buildIncidentReportedCard(BuildContext context, Incident inc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  inc.titulo ?? "Incidencia",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: "Editar incidencia",
                    icon: Icon(Icons.edit_note, color: Colors.amber.shade700),
                    splashRadius: 20,
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditIncidentPage(incident: inc.toMap()),
                        ),
                      );

                      if (updated == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(estado: inc.estado),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Creada: ${_formatFecha(inc.fecha)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // MÉTODO PARA FORMATEAR FECHA DE CREACIÓN DE LA INCIDENCIA
  //(HOY, AYER, HACE X DÍAS, O FECHA COMPLETA)
  String _formatFecha(DateTime fecha) {
    final now = DateTime.now();
    final difference = now.difference(fecha);

    if (difference.inDays == 0) {
      return "Hoy";
    } else if (difference.inDays == 1) {
      return "Ayer";
    } else if (difference.inDays < 7) {
      return "Hace ${difference.inDays} días";
    } else {
      return "${fecha.day}/${fecha.month}/${fecha.year}";
    }
  }
}
