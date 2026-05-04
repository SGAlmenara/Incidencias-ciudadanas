import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_scaffold.dart';

class AdminUserCommentsPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserCommentsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserCommentsPage> createState() => _AdminUserCommentsPageState();
}

class _AdminUserCommentsPageState extends State<AdminUserCommentsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final commentsRaw = await supabase
          .from('incidencia_comentarios')
          .select('id, incidencia_id, mensaje, created_at')
          .eq('autor_id', widget.userId)
          .order('created_at', ascending: false);

      final comments = (commentsRaw as List).cast<Map<String, dynamic>>();
      final incidentIds = comments
          .map((row) => (row['incidencia_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final titleByIncidentId = <String, String>{};
      if (incidentIds.isNotEmpty) {
        final incidentsRaw = await supabase
            .from('incidencias')
            .select('id, titulo')
            .inFilter('id', incidentIds);

        for (final row in (incidentsRaw as List).cast<Map<String, dynamic>>()) {
          final id = (row['id'] ?? '').toString();
          if (id.isEmpty) continue;

          final title = (row['titulo'] ?? '').toString().trim();
          titleByIncidentId[id] = title.isEmpty ? 'Incidencia' : title;
        }
      }

      final merged = comments.map((row) {
        final incidentId = (row['incidencia_id'] ?? '').toString();
        return {
          ...row,
          'incident_title': titleByIncidentId[incidentId] ?? 'Incidencia',
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _comments = merged;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando comentarios: $e')));
    }
  }

  String _formatDate(String value) {
    final date = DateTime.parse(value).toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Comentarios del usuario',
      subtitle: widget.userName,
      isAdmin: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _comments.isEmpty
          ? const Center(child: Text('Este usuario no tiene comentarios.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  final incidentTitle =
                      (comment['incident_title'] ?? 'Incidencia').toString();
                  final message = (comment['mensaje'] ?? '').toString();
                  final createdAt = _formatDate(
                    (comment['created_at'] ?? '').toString(),
                  );

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incidentTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3436),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(message),
                          const SizedBox(height: 8),
                          Text(
                            createdAt,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
