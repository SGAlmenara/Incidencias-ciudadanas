import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/incident_card.dart';
import 'list_incident_page.dart';

// Vista admin con el historial de incidencias de un usuario concreto.
class AdminUserIncidentsPage extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminUserIncidentsPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminUserIncidentsPage> createState() => _AdminUserIncidentsPageState();
}

class _AdminUserIncidentsPageState extends State<AdminUserIncidentsPage> {
  final IncidentService _incidentService = IncidentService();
  bool _loading = true;
  List<Incident> _incidents = [];
  Map<String, String> _latestCommentsByIncidentId = {};
  Map<String, int> _commentCountByIncidentId = {};

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
      final data = await Supabase.instance.client
          .from('incidencias')
          .select('*')
          .eq('user_id', widget.userId)
          .order('fecha', ascending: true);

      final incidents = (data as List)
          .cast<Map<String, dynamic>>()
          .map(Incident.fromMap)
          .toList();

      final ids = incidents.map((e) => e.id).toList();
      final latest = await _incidentService
          .getLatestCommentPreviewByIncidentIds(ids);
      final counts = await _incidentService.getCommentCountByIncidentIds(ids);

      if (!mounted) return;
      setState(() {
        _incidents = incidents;
        _latestCommentsByIncidentId = latest;
        _commentCountByIncidentId = counts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando incidencias: $e')));
    }
  }

  Future<void> _confirmDeleteIncident(Incident incident) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar incidencia'),
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

    final ok = await _incidentService.deleteIncident(incident.id);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _incidents.removeWhere((i) => i.id == incident.id);
        _latestCommentsByIncidentId.remove(incident.id);
        _commentCountByIncidentId.remove(incident.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incidencia eliminada')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la incidencia')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalIncidents = _incidents.length;

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
      title: 'Incidencias del usuario',
      subtitle: widget.userName,
      isAdmin: true,
      showDrawer: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
          ? const Center(child: Text('Este usuario no tiene incidencias.'))
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
                        'Incidencias',
                        '$totalIncidents',
                        const Color(0xFFDDEBFF),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _incidents.length,
                      itemBuilder: (context, index) {
                        final incident = _incidents[index];

                        return Stack(
                          children: [
                            IncidentCard(
                              incident: incident,
                              latestComment:
                                  _latestCommentsByIncidentId[incident.id],
                              commentCount:
                                  _commentCountByIncidentId[incident.id] ?? 0,
                              reporterName: widget.userName,
                              onTap: () async {
                                await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IncidentDetailPage(
                                      incident: incident.toMap(),
                                      isAdmin: true,
                                    ),
                                  ),
                                );

                                if (mounted) {
                                  await _load();
                                }
                              },
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
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
                                  tooltip: 'Eliminar incidencia',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFC62828),
                                    size: 18,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteIncident(incident),
                                ),
                              ),
                            ),
                          ],
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
