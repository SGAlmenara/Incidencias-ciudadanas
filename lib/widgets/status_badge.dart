import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String estado;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.estado,
    this.fontSize = 12,
    this.iconSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  Color _estadoColor(String value) {
    switch (value.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'en_proceso':
        return Colors.blue;
      case 'resuelta':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _estadoIcon(String value) {
    switch (value.toLowerCase()) {
      case 'pendiente':
        return Icons.schedule;
      case 'en_proceso':
        return Icons.work;
      case 'resuelta':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _estadoLabel(String value) {
    switch (value.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En proceso';
      case 'resuelta':
        return 'Resuelta';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(estado);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_estadoIcon(estado), size: iconSize, color: color),
          const SizedBox(width: 6),
          Text(
            _estadoLabel(estado),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
