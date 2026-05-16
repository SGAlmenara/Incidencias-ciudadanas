import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_scaffold.dart';
import 'list_incident_page.dart';

// Vista admin con todos los comentarios publicados por un usuario.
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
  final Set<String> _openingIncidentIds = <String>{};

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

  Future<void> _confirmDeleteComment(Map<String, dynamic> comment) async {
    final commentId = (comment['id'] ?? '').toString();
    if (commentId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('Esta seguro de eliminar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Si'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final deleted = await Supabase.instance.client
          .from('incidencia_comentarios')
          .delete()
          .eq('id', commentId)
          .select('id');

      if (!mounted) return;

      if ((deleted as List).isNotEmpty) {
        setState(() {
          _comments.removeWhere((item) => item['id'].toString() == commentId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comentario eliminado')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el comentario')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando comentario: $e')),
      );
    }
  }

  Future<void> _openIncident(Map<String, dynamic> comment) async {
    final incidentId = (comment['incidencia_id'] ?? '').toString();
    if (incidentId.isEmpty || _openingIncidentIds.contains(incidentId)) return;

    setState(() {
      _openingIncidentIds.add(incidentId);
    });

    try {
      final incident = await Supabase.instance.client
          .from('incidencias')
          .select('*')
          .eq('id', incidentId)
          .maybeSingle();

      if (!mounted) return;

      if (incident == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La incidencia ya no existe')),
        );
        return;
      }

      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentDetailPage(incident: incident, isAdmin: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error abriendo incidencia: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _openingIncidentIds.remove(incidentId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalComments = _comments.length;

    Widget statTile(String label, String value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF1D2D44),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF415A77),
              ),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      title: 'Comentarios del usuario',
      subtitle: widget.userName,
      isAdmin: true,
      showDrawer: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _comments.isEmpty
          ? const Center(child: Text('Este usuario no tiene comentarios.'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAF2FF), Color(0xFFF5F9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8E5FA)),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      statTile(
                        'Comentarios',
                        '$totalComments',
                        const Color(0xFFDDEBFF),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final incidentTitle =
                            (comment['incident_title'] ?? 'Incidencia')
                                .toString();
                        final message = (comment['mensaje'] ?? '').toString();
                        final createdAt = _formatDate(
                          (comment['created_at'] ?? '').toString(),
                        );

                        final incidentId = (comment['incidencia_id'] ?? '')
                            .toString();

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFDFE6F0)),
                          ),
                          elevation: 0,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openIncident(comment),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          incidentTitle,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2D3436),
                                          ),
                                        ),
                                      ),
                                      if (_openingIncidentIds.contains(
                                        incidentId,
                                      ))
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECEC),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFF6C9C9),
                                          ),
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          tooltip: 'Eliminar comentario',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Color(0xFFC62828),
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              _confirmDeleteComment(comment),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
