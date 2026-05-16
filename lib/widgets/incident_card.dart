import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incident.dart';
import 'status_badge.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;
  final String? latestComment;
  final int commentCount;
  final String? reporterName;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onTap,
    this.latestComment,
    this.commentCount = 0,
    this.reporterName,
  });

  // Tarjeta que muestra la información básica de una incidencia, incluyendo su título,
  //descripción, estado, fecha, una miniatura de la primera imagen (si existe),
  //y un adelanto del último comentario junto con el conteo total de comentarios.
  //El diseño usa un color de fondo según el estado de la incidencia.

  Color _getBackgroundColorByState() {
    switch (incident.estado.toLowerCase()) {
      case 'pendiente':
        return const Color(0xFFFFFAE6); // Amarillo muy claro
      case 'en_proceso':
        return const Color(0xFFE6F3FF); // Azul muy claro
      case 'resuelta':
        return const Color(0xFFE6F7E6); // Verde muy claro
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 430;
        final cardRadius = BorderRadius.circular(14);
        final thumbSize = isCompact ? 72.0 : 92.0;
        final cardPadding = isCompact ? 8.0 : 10.0;

        return Container(
          margin: EdgeInsets.symmetric(
            vertical: isCompact ? 4 : 5,
            horizontal: isCompact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: _getBackgroundColorByState(),
            borderRadius: cardRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: cardRadius,
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
                          width: thumbSize,
                          height: thumbSize,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: thumbSize,
                          height: thumbSize,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: isCompact ? 26 : 32,
                          ),
                        ),
                ),

                // TEXTO
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reporterName != null &&
                            reporterName!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: isCompact ? 12 : 13,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    reporterName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isCompact ? 11 : 12,
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
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2D3436),
                          ),
                        ),

                        const SizedBox(height: 4),

                        // DESCRIPCIÓN
                        Text(
                          incident.descripcion ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
                            color: Colors.grey[700],
                            height: 1.2,
                          ),
                        ),

                        if (incident.sector != null &&
                            incident.sector!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: isCompact ? 13 : 14,
                                  color: Colors.teal.shade700,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Sector: ${incident.sector!}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isCompact ? 11 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.teal.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (latestComment != null &&
                            latestComment!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 7 : 8,
                                vertical: isCompact ? 5 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.forum_outlined,
                                    size: isCompact ? 14 : 16,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      latestComment!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: isCompact ? 11 : 12,
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
                                fontSize: isCompact ? 10 : 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                          ),

                        SizedBox(height: isCompact ? 6 : 8),

                        // ESTADO + FECHA
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusBadge(
                              estado: incident.estado,
                              fontSize: isCompact ? 10 : 11,
                              iconSize: isCompact ? 12 : 13,
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 8 : 10,
                                vertical: isCompact ? 4 : 5,
                              ),
                            ),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: isCompact ? 13 : 14,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 4),

                                Text(
                                  incident.shortDate,
                                  style: TextStyle(
                                    fontSize: isCompact ? 11 : 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
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
      },
    );
  }
}
