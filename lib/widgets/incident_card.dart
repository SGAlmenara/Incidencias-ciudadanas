import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incident.dart';
import 'status_badge.dart';

enum IncidentStripeIntensity { soft, medium, strong }

const IncidentStripeIntensity kIncidentStripeIntensity =
    IncidentStripeIntensity.medium;

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;
  final String? latestComment;
  final int commentCount;
  final bool isAlternate;
  final String? reporterName;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onTap,
    this.latestComment,
    this.commentCount = 0,
    this.isAlternate = false,
    this.reporterName,
  });

  // Tarjeta que muestra la información básica de una incidencia, incluyendo su título,
  //descripción, estado, fecha, una miniatura de la primera imagen (si existe),
  //y un adelanto del último comentario junto con el conteo total de comentarios.
  //El diseño incluye un fondo alternado para mejorar la legibilidad en listas largas.
  @override
  Widget build(BuildContext context) {
    Color alternateColor;
    switch (kIncidentStripeIntensity) {
      case IncidentStripeIntensity.soft:
        alternateColor = const Color.fromARGB(255, 170, 168, 168);
        break;
      case IncidentStripeIntensity.medium:
        alternateColor = const Color(0xFFEFEFEF);
        break;
      case IncidentStripeIntensity.strong:
        alternateColor = const Color(0xFFE6E6E6);
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: isAlternate ? alternateColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Row(
          children: [
            // MINIATURA
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: incident.hasImages
                  ? Image.memory(
                      base64Decode(incident.firstImage!),
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported, size: 32),
                    ),
            ),

            // TEXTO
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reporterName != null && reporterName!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 13,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                reporterName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // TÍTULO
                    Text(
                      incident.titulo ?? "Sin título",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3436),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // DESCRIPCIÓN
                    Text(
                      incident.descripcion ?? "",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),

                    if (latestComment != null &&
                        latestComment!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 16,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  latestComment!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (commentCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          commentCount == 1
                              ? '1 comentario'
                              : '$commentCount comentarios',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // ESTADO + FECHA
                    Row(
                      children: [
                        // ESTADO
                        StatusBadge(
                          estado: incident.estado,
                          fontSize: 11,
                          iconSize: 13,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                        ),

                        const SizedBox(width: 12),

                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 4),

                        Text(
                          incident.shortDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
