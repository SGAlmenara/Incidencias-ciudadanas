import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../widgets/incident_card.dart';
import '../screens/create_incident_page.dart';
import 'list_incident_page.dart';
import '../services/auth_service.dart';
import '../services/incident_service.dart';
import '../widgets/app_scaffold.dart';

class _IncidentsWithComments {
  final List<Incident> incidents;
  final Map<String, String> latestCommentsByIncidentId;
  final Map<String, int> commentCountByIncidentId;

  _IncidentsWithComments({
    required this.incidents,
    required this.latestCommentsByIncidentId,
    required this.commentCountByIncidentId,
  });
}

class UserIncidentsPage extends StatefulWidget {
  const UserIncidentsPage({super.key});

  @override
  State<UserIncidentsPage> createState() => _UserIncidentsPageState();
}

// PÁGINA DE USUARIO: LISTADO DE SUS INCIDENCIAS
class _UserIncidentsPageState extends State<UserIncidentsPage> {
  final supabase = Supabase.instance.client;
  final auth = AuthService();
  final incidentService = IncidentService();

  String estadoFiltro = "todos";
  String? userEmail;

  bool isAdmin = false;
  bool loadingRole = true;
  bool loadingIncidents = true;
  _IncidentsWithComments? incidentsData;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    isAdmin = await auth.isAdmin();
    userEmail = supabase.auth.currentUser?.email;
    setState(() => loadingRole = false);
    await _reloadIncidents();
  }

  Future<void> _reloadIncidents() async {
    final data = await _loadIncidents();
    if (!mounted) return;

    setState(() {
      incidentsData = data;
      loadingIncidents = false;
    });
  }

  Future<_IncidentsWithComments> _loadIncidents() async {
    final userId = supabase.auth.currentUser!.id;

    dynamic response;

    if (estadoFiltro == "todos") {
      response = await supabase
          .from('incidencias')
          .select('*')
          .eq('user_id', userId)
          .order('fecha', ascending: false);
    } else {
      response = await supabase
          .from('incidencias')
          .select('*')
          .eq('user_id', userId)
          .eq('estado', estadoFiltro)
          .order('fecha', ascending: false);
    }

    final incidents = (response as List)
        .map((map) => Incident.fromMap(map))
        .toList();

    final latestCommentsByIncidentId = await incidentService
        .getLatestCommentPreviewByIncidentIds(
          incidents.map((incident) => incident.id).toList(),
        );
    final commentCountByIncidentId = await incidentService
        .getCommentCountByIncidentIds(
          incidents.map((incident) => incident.id).toList(),
        );

    return _IncidentsWithComments(
      incidents: incidents,
      latestCommentsByIncidentId: latestCommentsByIncidentId,
      commentCountByIncidentId: commentCountByIncidentId,
    );
  }

  Future<void> _refreshSingleIncident(String incidentId) async {
    final updatedIncident = await incidentService.getIncidentById(incidentId);
    final latestComment = await incidentService
        .getLatestCommentPreviewByIncidentIds([incidentId]);
    final commentCount = await incidentService.getCommentCountByIncidentIds([
      incidentId,
    ]);

    if (!mounted || incidentsData == null) return;

    final updatedIncidents = List<Incident>.from(incidentsData!.incidents);
    final idx = updatedIncidents.indexWhere((inc) => inc.id == incidentId);

    if (updatedIncident == null) {
      if (idx != -1) {
        updatedIncidents.removeAt(idx);
      }
    } else {
      final matchesFilter =
          estadoFiltro == 'todos' || updatedIncident.estado == estadoFiltro;

      if (!matchesFilter) {
        if (idx != -1) {
          updatedIncidents.removeAt(idx);
        }
      } else if (idx == -1) {
        updatedIncidents.insert(0, updatedIncident);
      } else {
        updatedIncidents[idx] = updatedIncident;
      }
    }

    final updatedLatestComments = Map<String, String>.from(
      incidentsData!.latestCommentsByIncidentId,
    );
    final updatedCommentCounts = Map<String, int>.from(
      incidentsData!.commentCountByIncidentId,
    );

    final latestText = latestComment[incidentId];
    if (latestText == null || latestText.trim().isEmpty) {
      updatedLatestComments.remove(incidentId);
    } else {
      updatedLatestComments[incidentId] = latestText;
    }

    final countValue = commentCount[incidentId] ?? 0;
    if (countValue <= 0) {
      updatedCommentCounts.remove(incidentId);
    } else {
      updatedCommentCounts[incidentId] = countValue;
    }

    if (updatedIncident != null &&
        (estadoFiltro == 'todos' || updatedIncident.estado == estadoFiltro)) {
      updatedIncidents.sort((a, b) => b.fecha.compareTo(a.fecha));
    }

    setState(() {
      incidentsData = _IncidentsWithComments(
        incidents: updatedIncidents,
        latestCommentsByIncidentId: updatedLatestComments,
        commentCountByIncidentId: updatedCommentCounts,
      );
    });
  }

  Widget _buildFiltro(String valor, String texto) {
    final activo = estadoFiltro == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          estadoFiltro = valor;
          loadingIncidents = true;
        });
        _reloadIncidents();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: activo ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AppScaffold(
      title: "Mis incidencias",
      subtitle: "Bienvenido, ${userEmail ?? 'usuario'}",
      isAdmin: isAdmin,
      body: Column(
        children: [
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFiltro("todos", "Todas"),
              _buildFiltro("pendiente", "Pendientes"),
              _buildFiltro("en_proceso", "En proceso"),
              _buildFiltro("resuelta", "Resueltas"),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: loadingIncidents
                ? const Center(child: CircularProgressIndicator())
                : incidentsData == null || incidentsData!.incidents.isEmpty
                ? const Center(child: Text("No hay incidencias"))
                : ListView.builder(
                    itemCount: incidentsData!.incidents.length,
                    itemBuilder: (context, index) {
                      final inc = incidentsData!.incidents[index];

                      return IncidentCard(
                        incident: inc,
                        isAlternate: index.isEven,
                        latestComment:
                            incidentsData!.latestCommentsByIncidentId[inc.id],
                        commentCount:
                            incidentsData!.commentCountByIncidentId[inc.id] ??
                            0,
                        onTap: () async {
                          await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IncidentDetailPage(
                                incident: inc.toMap(),
                                isAdmin: isAdmin,
                              ),
                            ),
                          );

                          if (mounted) {
                            await _refreshSingleIncident(inc.id);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CreateIncidentPage()),
          );

          if (created == true && mounted) {
            setState(() {
              loadingIncidents = true;
            });
            await _reloadIncidents();
          }
        },
      ),
    );
  }
}
