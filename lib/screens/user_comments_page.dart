import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/back_fab.dart';

class UserCommentsPage extends StatefulWidget {
  const UserCommentsPage({super.key});

  @override
  State<UserCommentsPage> createState() => _UserCommentsPageState();
}

class _UserCommentView {
  final String incidentId;
  final String incidentTitle;
  final String message;
  final DateTime createdAt;
  final bool hasAdminResponse;
  final String? adminResponsePreview;

  _UserCommentView({
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
          roleByAuthorId[id] = (row['role'] ?? 'user').toString();
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
          final role = roleByAuthorId[authorId] ?? 'user';
          final threadCreatedAt = DateTime.parse(
            threadRow['created_at'].toString(),
          );

          if (role == 'admin' && threadCreatedAt.isAfter(createdAt)) {
            firstAdminReply = threadRow;
            break;
          }
        }

        return _UserCommentView(
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
          : RefreshIndicator(
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
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
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
    );
  }
}
