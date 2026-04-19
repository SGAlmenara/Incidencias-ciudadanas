import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incident.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;

  const IncidentCard({super.key, required this.incident, this.onTap});

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFE67E22); // naranja institucional
      case 'en_proceso':
        return const Color(0xFF2980B9); // azul institucional
      case 'resuelta':
        return const Color(0xFF27AE60); // verde institucional
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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

                    const SizedBox(height: 12),

                    // ESTADO + FECHA
                    Row(
                      children: [
                        // ESTADO
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _estadoColor(incident.estado),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            incident.estado.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
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
