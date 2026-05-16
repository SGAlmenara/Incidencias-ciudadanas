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
  static const List<String> _sectoresDisponibles = [
    'todos',
    'Alumbrado',
    'Inmobiliario Urbano',
    'Aceras',
    'Carretera',
    'Edificios',
    'Parques',
    'Limpieza viaria',
    'Señalización y tráfico',
    'Jardinería y zonas verdes',
    'Otros',
  ];

  final supabase = Supabase.instance.client;
  final auth = AuthService();
  final incidentService = IncidentService();

  String estadoFiltro = "todos";
  String sectorFiltro = "todos";
  String ordenarFecha = "reciente"; // 'reciente' o 'antigua'
  String? userEmail;
  Map<String, int> sectorCountMap = {};

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
    // Cargo rol y email una sola vez para pintar cabecera y permisos.
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

    // Estos filtros van en query para que la lista ya venga filtrada.
    var query = supabase.from('incidencias').select('*').eq('user_id', userId);

    if (estadoFiltro != 'todos') {
      query = query.eq('estado', estadoFiltro);
    }
    if (sectorFiltro != 'todos') {
      query = query.eq('sector', sectorFiltro);
    }

    // Con esto se alterna entre mas reciente y mas antigua desde UI.
    final ascending =
        ordenarFecha == 'antigua'; // true para antigua, false para reciente
    final response = await query.order('fecha', ascending: ascending);

    final incidents = (response as List)
        .map((map) => Incident.fromMap(map))
        .toList();

    final countMap = <String, int>{};
    // Se guarda conteo por sector para mostrarlo en el dropdown.
    for (final inc in incidents) {
      final sector = (inc.sector ?? 'Otros').trim();
      countMap[sector] = (countMap[sector] ?? 0) + 1;
    }

    if (mounted) {
      setState(() {
        sectorCountMap = countMap;
      });
    }

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
          (estadoFiltro == 'todos' || updatedIncident.estado == estadoFiltro) &&
          (sectorFiltro == 'todos' || updatedIncident.sector == sectorFiltro);

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
        (estadoFiltro == 'todos' || updatedIncident.estado == estadoFiltro) &&
        (sectorFiltro == 'todos' || updatedIncident.sector == sectorFiltro)) {
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
    return ChoiceChip(
      label: Text(texto),
      selected: activo,
      selectedColor: const Color(0xFFDDEBFF),
      side: const BorderSide(color: Color(0xFFD7DFEA)),
      labelStyle: TextStyle(
        color: activo ? const Color(0xFF1F3B63) : Colors.black87,
        fontWeight: activo ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() {
          estadoFiltro = valor;
          loadingIncidents = true;
        });
        _reloadIncidents();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleIncidents = incidentsData?.incidents ?? const <Incident>[];
    final totalIncidents = visibleIncidents.length;
    final pendientes = visibleIncidents
        .where((i) => i.estado == 'pendiente')
        .length;
    final enProceso = visibleIncidents
        .where((i) => i.estado == 'en_proceso')
        .length;
    final resueltas = visibleIncidents
        .where((i) => i.estado == 'resuelta')
        .length;

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

    if (loadingRole) {
      return AppScaffold(
        title: 'Mis incidencias',
        isAdmin: isAdmin,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: "Mis incidencias",
      subtitle: "Bienvenido, ${userEmail ?? 'usuario'}",
      isAdmin: isAdmin,
      body: Column(
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
                statTile('Total', '$totalIncidents', const Color(0xFFDDEBFF)),
                statTile('Pendientes', '$pendientes', const Color(0xFFFFF2CC)),
                statTile('En proceso', '$enProceso', const Color(0xFFE2F4FF)),
                statTile('Resueltas', '$resueltas', const Color(0xFFE8F8EC)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFiltro("todos", "Todas"),
                _buildFiltro("pendiente", "Pendientes"),
                _buildFiltro("en_proceso", "En proceso"),
                _buildFiltro("resuelta", "Resueltas"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD7DFEA)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sectorFiltro,
                  isExpanded: true,
                  items: _sectoresDisponibles.map((sector) {
                    final label = sector == 'todos'
                        ? 'Sector: Todos'
                        : '$sector (${sectorCountMap[sector] ?? 0})';
                    return DropdownMenuItem<String>(
                      value: sector,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      sectorFiltro = value;
                      loadingIncidents = true;
                    });
                    _reloadIncidents();
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD7DFEA)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: ordenarFecha,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String>(
                      value: 'reciente',
                      child: const Text('Fecha (más reciente)'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'antigua',
                      child: const Text('Fecha (más antigua)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      ordenarFecha = value;
                      loadingIncidents = true;
                    });
                    _reloadIncidents();
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: loadingIncidents
                ? const Center(child: CircularProgressIndicator())
                : incidentsData == null || incidentsData!.incidents.isEmpty
                ? const Center(child: Text("No hay incidencias"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: incidentsData!.incidents.length,
                    itemBuilder: (context, index) {
                      final inc = incidentsData!.incidents[index];

                      return IncidentCard(
                        incident: inc,
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
