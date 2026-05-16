import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_scaffold.dart';
import '../models/incident_comment.dart';
import '../models/incident.dart';
import 'edit_incident_page.dart';
import '../services/incident_service.dart';
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
        content: const Text("Esta seguro de eliminar?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Si"),
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

                      if (inc.sector != null && inc.sector!.trim().isNotEmpty)
                        _buildInfoCard(
                          icon: Icons.category_outlined,
                          iconColor: Colors.teal,
                          title: "Sector",
                          content: inc.sector!,
                        ),

                      if (inc.sector != null && inc.sector!.trim().isNotEmpty)
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

                      const SizedBox(height: 24),

                      _CommentsSection(incidentId: inc.id, isAdmin: isAdmin),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // BOTÓN FLOTANTE ABAJO A LA IZQUIERDA
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.blue,
            child: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
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

class _CommentsSection extends StatefulWidget {
  final String incidentId;
  final bool isAdmin;

  const _CommentsSection({required this.incidentId, required this.isAdmin});

  @override
  State<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final IncidentService _incidentService = IncidentService();
  final TextEditingController _commentCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  List<IncidentComment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final comments = await _incidentService.getIncidentComments(
      widget.incidentId,
    );

    if (!mounted) return;
    setState(() {
      _comments = comments;
      _loading = false;
    });
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
    });

    try {
      await _incidentService.addIncidentComment(
        incidentId: widget.incidentId,
        message: text,
      );
      _commentCtrl.clear();
      await _loadComments();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el comentario')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _sending = false;
      });
    }
  }

  String _formatCreatedAt(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comentarios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_comments.isEmpty)
            Text(
              'Aun no hay comentarios en esta incidencia.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else
            Column(
              children: _comments.map((comment) {
                final isAdminComment =
                    comment.authorRole.trim().toLowerCase() == 'admin';

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAdminComment
                        ? Colors.blue.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3436),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isAdminComment
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade600,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isAdminComment ? 'Admin' : 'Usuario',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(comment.message),
                      const SizedBox(height: 6),
                      Text(
                        _formatCreatedAt(comment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Escribe un comentario',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _sending ? null : _sendComment,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text('Enviar'),
              ),
            ],
          ),

          if (widget.isAdmin) ...[
            const SizedBox(height: 8),
            Text(
              'Tus comentarios aparecerán identificados como administrador.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
            ),
          ],
        ],
      ),
    );
  }
}
