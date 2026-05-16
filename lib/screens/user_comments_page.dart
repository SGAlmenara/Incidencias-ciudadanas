import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/back_fab.dart';

// Pantalla donde el usuario revisa sus comentarios y respuestas admin.
class UserCommentsPage extends StatefulWidget {
  const UserCommentsPage({super.key});

  @override
  State<UserCommentsPage> createState() => _UserCommentsPageState();
}

class _UserCommentView {
  final String commentId;
  final String incidentId;
  final String incidentTitle;
  final String message;
  final DateTime createdAt;
  final bool hasAdminResponse;
  final String? adminResponsePreview;

  _UserCommentView({
    required this.commentId,
    required this.incidentId,
    required this.incidentTitle,
    required this.message,
    required this.createdAt,
    required this.hasAdminResponse,
    this.adminResponsePreview,
  });
}

class _UserCommentsPageState extends State<UserCommentsPage> {
  bool _loading = true;
  List<_UserCommentView> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _items = [];
      });
      return;
    }

    try {
      final myCommentsRaw = await supabase
          .from('incidencia_comentarios')
          .select('id, incidencia_id, autor_id, mensaje, created_at')
          .eq('autor_id', userId)
          .order('created_at', ascending: false);

      final myComments = (myCommentsRaw as List).cast<Map<String, dynamic>>();
      if (myComments.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _items = [];
        });
        return;
      }

      final incidentIds = myComments
          .map((row) => (row['incidencia_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final incidentTitlesById = <String, String>{};
      if (incidentIds.isNotEmpty) {
        final incidentsRaw = await supabase
            .from('incidencias')
            .select('id, titulo')
            .inFilter('id', incidentIds);

        for (final row in (incidentsRaw as List).cast<Map<String, dynamic>>()) {
          final id = (row['id'] ?? '').toString();
          if (id.isEmpty) continue;
          final title = (row['titulo'] ?? '').toString().trim();
          incidentTitlesById[id] = title.isEmpty ? 'Incidencia' : title;
        }
      }

      final allCommentsRaw = await supabase
          .from('incidencia_comentarios')
          .select('incidencia_id, autor_id, mensaje, created_at')
          .inFilter('incidencia_id', incidentIds)
          .order('created_at', ascending: true);

      final allComments = (allCommentsRaw as List).cast<Map<String, dynamic>>();
      final authorIds = allComments
          .map((row) => (row['autor_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final roleByAuthorId = <String, String>{};
      if (authorIds.isNotEmpty) {
        final profileRaw = await supabase
            .from('profiles')
            .select('id, role')
            .inFilter('id', authorIds);

        for (final row in (profileRaw as List).cast<Map<String, dynamic>>()) {
          final id = (row['id'] ?? '').toString();
          if (id.isEmpty) continue;
          roleByAuthorId[id] = (row['role'] ?? 'user')
              .toString()
              .trim()
              .toLowerCase();
        }
      }

      final commentsByIncident = <String, List<Map<String, dynamic>>>{};
      for (final row in allComments) {
        final incidentId = (row['incidencia_id'] ?? '').toString();
        if (incidentId.isEmpty) continue;
        commentsByIncident.putIfAbsent(incidentId, () => []).add(row);
      }

      final items = myComments.map((row) {
        final incidentId = (row['incidencia_id'] ?? '').toString();
        final message = (row['mensaje'] ?? '').toString();
        final createdAt = DateTime.parse(row['created_at'].toString());
        final incidentTitle = incidentTitlesById[incidentId] ?? 'Incidencia';

        final incidentThread = commentsByIncident[incidentId] ?? const [];
        Map<String, dynamic>? firstAdminReply;

        for (final threadRow in incidentThread) {
          final authorId = (threadRow['autor_id'] ?? '').toString();
          final role = (roleByAuthorId[authorId] ?? 'user')
              .trim()
              .toLowerCase();
          final threadCreatedAt = DateTime.parse(
            threadRow['created_at'].toString(),
          );

          if (role == 'admin' && threadCreatedAt.isAfter(createdAt)) {
            firstAdminReply = threadRow;
            break;
          }
        }

        return _UserCommentView(
          commentId: (row['id'] ?? '').toString(),
          incidentId: incidentId,
          incidentTitle: incidentTitle,
          message: message,
          createdAt: createdAt,
          hasAdminResponse: firstAdminReply != null,
          adminResponsePreview: firstAdminReply == null
              ? null
              : (firstAdminReply['mensaje'] ?? '').toString(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando comentarios: $e')));
    }
  }

  Future<void> _confirmDeleteComment(_UserCommentView item) async {
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

    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || item.commentId.isEmpty) return;

    try {
      final deleted = await supabase
          .from('incidencia_comentarios')
          .delete()
          .eq('id', item.commentId)
          .eq('autor_id', userId)
          .select('id');

      if (!mounted) return;

      if ((deleted as List).isNotEmpty) {
        setState(() {
          _items.removeWhere((comment) => comment.commentId == item.commentId);
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

  String _formatDate(DateTime value) {
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
    final totalComments = _items.length;
    final withResponse = _items.where((item) => item.hasAdminResponse).length;
    final withoutResponse = totalComments - withResponse;

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
      title: 'Mis comentarios',
      subtitle: 'Revisa si hay respuesta del admin',
      isAdmin: false,
      floatingActionButton: const BackFAB(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Center(
              child: Text('Aún no tienes comentarios en incidencias.'),
            )
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
                      statTile(
                        'Con respuesta',
                        '$withResponse',
                        const Color(0xFFE8F8EC),
                      ),
                      statTile(
                        'Sin respuesta',
                        '$withoutResponse',
                        const Color(0xFFFFF2CC),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFDFE6F0)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.incidentTitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2D3436),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.hasAdminResponse
                                          ? Colors.green.shade600
                                          : Colors.orange.shade600,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      item.hasAdminResponse
                                          ? 'Con respuesta'
                                          : 'Sin respuesta',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFECEC),
                                      borderRadius: BorderRadius.circular(10),
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
                                          _confirmDeleteComment(item),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.message,
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (item.hasAdminResponse &&
                                  item.adminResponsePreview != null &&
                                  item.adminResponsePreview!.trim().isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Respuesta admin: ${item.adminResponsePreview}',
                                    style: TextStyle(
                                      color: Colors.blue.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(item.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
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
