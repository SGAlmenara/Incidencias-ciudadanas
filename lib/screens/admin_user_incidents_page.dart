import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/incident_card.dart';
import 'list_incident_page.dart';

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
          .order('fecha', ascending: false);

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Incidencias del usuario',
      subtitle: widget.userName,
      isAdmin: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
          ? const Center(child: Text('Este usuario no tiene incidencias.'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _incidents.length,
                itemBuilder: (context, index) {
                  final incident = _incidents[index];

                  return IncidentCard(
                    incident: incident,
                    isAlternate: index.isEven,
                    latestComment: _latestCommentsByIncidentId[incident.id],
                    commentCount: _commentCountByIncidentId[incident.id] ?? 0,
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
                  );
                },
              ),
            ),
    );
  }
}
