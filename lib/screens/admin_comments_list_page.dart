import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_scaffold.dart';
import 'list_incident_page.dart';

class AdminCommentsListPage extends StatefulWidget {
  const AdminCommentsListPage({super.key});

  @override
  State<AdminCommentsListPage> createState() => _AdminCommentsListPageState();
}

class _AdminCommentsListPageState extends State<AdminCommentsListPage> {
  bool _loading = true;
  final Set<String> _openingIncidentIds = <String>{};
  List<Map<String, dynamic>> _comments = [];
  String _searchQuery = '';
  String _dateFilter = 'all';

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
          .select('id, incidencia_id, autor_id, mensaje, created_at')
          .order('created_at', ascending: false);

      final comments = (commentsRaw as List).cast<Map<String, dynamic>>();

      final incidentIds = comments
          .map((row) => (row['incidencia_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final authorIds = comments
          .map((row) => (row['autor_id'] ?? '').toString())
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

      final authorNameById = <String, String>{};
      if (authorIds.isNotEmpty) {
        final profilesRaw = await supabase
            .from('profiles')
            .select('id, nombre, apellidos, email')
            .inFilter('id', authorIds);

        for (final row in (profilesRaw as List).cast<Map<String, dynamic>>()) {
          final id = (row['id'] ?? '').toString();
          if (id.isEmpty) continue;

          final nombre = (row['nombre'] ?? '').toString().trim();
          final apellidos = (row['apellidos'] ?? '').toString().trim();
          final email = (row['email'] ?? '').toString().trim();
          final fullName = [
            nombre,
            apellidos,
          ].where((part) => part.isNotEmpty).join(' ').trim();

          authorNameById[id] = fullName.isNotEmpty
              ? fullName
              : (email.isNotEmpty ? email : 'Usuario');
        }
      }

      final merged = comments.map((row) {
        final incidentId = (row['incidencia_id'] ?? '').toString();
        final authorId = (row['autor_id'] ?? '').toString();
        return {
          ...row,
          'incident_title': titleByIncidentId[incidentId] ?? 'Incidencia',
          'author_name': authorNameById[authorId] ?? 'Usuario',
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
        _comments = [];
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

  bool _matchesDateFilter(String createdAtRaw) {
    if (_dateFilter == 'all') return true;

    final createdAt = DateTime.parse(createdAtRaw).toLocal();
    final now = DateTime.now();

    if (_dateFilter == 'today') {
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }

    if (_dateFilter == '7d') {
      return createdAt.isAfter(now.subtract(const Duration(days: 7)));
    }

    if (_dateFilter == '30d') {
      return createdAt.isAfter(now.subtract(const Duration(days: 30)));
    }

    return true;
  }

  List<Map<String, dynamic>> get _filteredComments {
    final query = _searchQuery.trim().toLowerCase();

    return _comments.where((comment) {
      final incidentTitle = (comment['incident_title'] ?? 'Incidencia')
          .toString()
          .toLowerCase();
      final authorName = (comment['author_name'] ?? 'Usuario')
          .toString()
          .toLowerCase();
      final message = (comment['mensaje'] ?? '').toString().toLowerCase();
      final createdAtRaw = (comment['created_at'] ?? '').toString();

      final matchesSearch = query.isEmpty
          ? true
          : incidentTitle.contains(query) ||
                authorName.contains(query) ||
                message.contains(query);

      final matchesDate = createdAtRaw.isEmpty
          ? _dateFilter == 'all'
          : _matchesDateFilter(createdAtRaw);

      return matchesSearch && matchesDate;
    }).toList();
  }

  Widget _buildDateChip(String value, String label) {
    final selected = _dateFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFDDEBFF),
      side: const BorderSide(color: Color(0xFFD7DFEA)),
      onSelected: (_) {
        setState(() {
          _dateFilter = value;
        });
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredComments;
    final totalComments = _comments.length;
    final shownComments = filtered.length;

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
      title: 'Comentarios (Admin)',
      subtitle: 'Todos los comentarios',
      isAdmin: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _comments.isEmpty
          ? const Center(child: Text('No hay comentarios registrados.'))
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
                        'Mostrados',
                        '$shownComments',
                        const Color(0xFFE8F8EC),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText:
                          'Buscar por incidencia, autor o texto del comentario',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF003366),
                          width: 1.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDateChip('all', 'Todas las fechas'),
                      _buildDateChip('today', 'Hoy'),
                      _buildDateChip('7d', 'Ultimos 7 dias'),
                      _buildDateChip('30d', 'Ultimos 30 dias'),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text('No hay comentarios para esos filtros.'),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final comment = filtered[index];
                              final incidentId =
                                  (comment['incidencia_id'] ?? '').toString();
                              final incidentTitle =
                                  (comment['incident_title'] ?? 'Incidencia')
                                      .toString();
                              final authorName =
                                  (comment['author_name'] ?? 'Usuario')
                                      .toString();
                              final message = (comment['mensaje'] ?? '')
                                  .toString();
                              final createdAt = _formatDate(
                                (comment['created_at'] ?? '').toString(),
                              );

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(
                                    color: Color(0xFFDFE6F0),
                                  ),
                                ),
                                elevation: 0,
                                child: ListTile(
                                  onTap: () => _openIncident(comment),
                                  contentPadding: const EdgeInsets.all(12),
                                  title: Text(
                                    incidentTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2D3436),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Autor: $authorName'),
                                        const SizedBox(height: 4),
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
                                  trailing: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
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
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              _confirmDeleteComment(comment),
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
                                    ],
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
