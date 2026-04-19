import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_scaffold.dart';
import '../models/incident.dart';
import 'edit_incident_page.dart';
import '../services/incident_service.dart';

class IncidentDetailPage extends StatelessWidget {
  final Map<String, dynamic> incident;
  final bool isAdmin;

  const IncidentDetailPage({
    super.key,
    required this.incident,
    required this.isAdmin,
  });

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
      await IncidentService().deleteIncident(id);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inc = Incident.fromMap(incident);

    return AppScaffold(
      title: "Detalle de incidencia",
      isAdmin: isAdmin,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TÍTULO DE LA INCIDENCIA
            Text(
              inc.titulo ?? "Incidencia",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // CARRUSEL DE IMÁGENES
            if (inc.hasImages)
              SizedBox(
                height: 220,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: inc.imgUrls.map((img) {
                    return GestureDetector(
                      onTap: () => _mostrarImagenAmpliada(context, img),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 260,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[200],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Image.memory(
                          base64Decode(img),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 20),

            // DIRECCIÓN
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    inc.direccion ?? "Sin dirección",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ESTADO
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  "Estado: ${inc.estado}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // DESCRIPCIÓN
            const Text(
              "Descripción:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(inc.descripcion ?? "", style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 20),

            // MAPA
            if (inc.latitud != null && inc.longitud != null)
              SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(inc.latitud!, inc.longitud!),
                    zoom: 16,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("incident"),
                      position: LatLng(inc.latitud!, inc.longitud!),
                    ),
                  },
                ),
              ),

            const SizedBox(height: 30),

            // BOTONES
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Abrir en Google Maps"),
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

                  const SizedBox(height: 15),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text("Editar incidencia"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditIncidentPage(incident: inc.toMap()),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  if (isAdmin)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text("Eliminar incidencia"),
                      onPressed: () => _confirmarEliminar(context, inc.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
