import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';
import '../widgets/incident_card.dart';
import 'list_incident_page.dart';
import '../widgets/app_scaffold.dart';

enum AdminSortOption {
  fechaDesc,
  direccionAsc,
  direccionDesc,
  estadoAsc,
  estadoDesc,
}

// PÁGINA PRINCIPAL ADMINISTRADORES: LISTADO DE TODAS LAS INCIDENCIAS CON FILTROS
// Y OPCIONES DE EDICIÓN
class AdminIncidentListPage extends StatefulWidget {
  const AdminIncidentListPage({super.key});

  @override
  State<AdminIncidentListPage> createState() => _AdminIncidentListPageState();
}

class _AdminIncidentListPageState extends State<AdminIncidentListPage> {
  bool loading = true;
  List<Incident> incidents = [];
  Map<String, String> latestCommentsByIncidentId = {};
  Map<String, int> commentCountByIncidentId = {};
  Map<String, String> reporterNameByUserId = {};
  final Set<String> updatingStatusIds = <String>{};
  String filtroEstado = "todos";
  AdminSortOption sortOption = AdminSortOption.fechaDesc;
  final incidentService = IncidentService();

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  // CARGAR INCIDENCIAS CON FILTRO DE ESTADO Y ORDEN SEGÚN OPCIÓN SELECCIONADA
  Future<void> _loadIncidents() async {
    final supabase = Supabase.instance.client;

    try {
      dynamic data;

      if (filtroEstado == "todos") {
        data = await supabase
            .from('incidencias')
            .select('*')
            .order('fecha', ascending: false);
      } else {
        data = await supabase
            .from('incidencias')
            .select('*')
            .eq('estado', filtroEstado)
            .order('fecha', ascending: false);
      }

      final loaded = (data as List)
          .map((map) => Incident.fromMap(map))
          .toList();
      _sortIncidents(loaded);

      final userIds = loaded
          .map((incident) => incident.userId)
          .toSet()
          .toList();
      final reporterMap = <String, String>{};
      if (userIds.isNotEmpty) {
        final profileRows = await supabase
            .from('profiles')
            .select('id, nombre, apellidos, email')
            .inFilter('id', userIds);

        for (final row in (profileRows as List).cast<Map<String, dynamic>>()) {
          final userId = (row['id'] ?? '').toString();
          if (userId.isEmpty) continue;

          final nombre = (row['nombre'] ?? '').toString().trim();
          final apellidos = (row['apellidos'] ?? '').toString().trim();
          final email = (row['email'] ?? '').toString().trim();
          final fullName = [
            nombre,
            apellidos,
          ].where((part) => part.isNotEmpty).join(' ').trim();

          final displayName = fullName.isNotEmpty
              ? fullName
              : (email.isNotEmpty ? email : 'Usuario');
          reporterMap[userId] = displayName;
        }
      }

      final incidentIds = loaded.map((incident) => incident.id).toList();
      final latestComments = await incidentService
          .getLatestCommentPreviewByIncidentIds(incidentIds);
      final commentCounts = await incidentService.getCommentCountByIncidentIds(
        incidentIds,
      );

      if (!mounted) return;
      setState(() {
        incidents = loaded;
        latestCommentsByIncidentId = latestComments;
        commentCountByIncidentId = commentCounts;
        reporterNameByUserId = reporterMap;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando incidencias: $e')));
    }
  }

  // MÉTODO PARA ACTUALIZAR EL ESTADO DE UNA INCIDENCIA
  Future<void> _updateIncidentStatus(
    Incident incident,
    String newStatus,
  ) async {
    if (incident.estado == newStatus ||
        updatingStatusIds.contains(incident.id)) {
      return;
    }

    setState(() {
      updatingStatusIds.add(incident.id);
    });

    try {
      await incidentService.updateIncidentStatus(
        id: incident.id,
        estado: newStatus,
      );

      if (!mounted) return;
      setState(() {
        final index = incidents.indexWhere((i) => i.id == incident.id);
        if (index != -1) {
          incidents[index] = incidents[index].copyWith(estado: newStatus);
        }

        if (filtroEstado != 'todos') {
          incidents.removeWhere(
            (i) => i.id == incident.id && i.estado != filtroEstado,
          );
        }

        _sortIncidents(incidents);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar estado: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        updatingStatusIds.remove(incident.id);
      });
    }
  }

  // MÉTODO PARA OBTENER EL ORDEN DE LOS ESTADOS
  int _estadoOrder(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 0;
      case 'en_proceso':
        return 1;
      case 'resuelta':
        return 2;
      default:
        return 99;
    }
  }

  // MÉTODO PARA ORDENAR LA LISTA DE INCIDENCIAS SEGÚN LA OPCIÓN SELECCIONADA
  void _sortIncidents(List<Incident> list) {
    switch (sortOption) {
      case AdminSortOption.fechaDesc:
        list.sort((a, b) => b.fecha.compareTo(a.fecha));
        break;
      case AdminSortOption.direccionAsc:
        list.sort(
          (a, b) => (a.direccion ?? '').toLowerCase().compareTo(
            (b.direccion ?? '').toLowerCase(),
          ),
        );
        break;
      case AdminSortOption.direccionDesc:
        list.sort(
          (a, b) => (b.direccion ?? '').toLowerCase().compareTo(
            (a.direccion ?? '').toLowerCase(),
          ),
        );
        break;
      case AdminSortOption.estadoAsc:
        list.sort(
          (a, b) => _estadoOrder(a.estado).compareTo(_estadoOrder(b.estado)),
        );
        break;
      case AdminSortOption.estadoDesc:
        list.sort(
          (a, b) => _estadoOrder(b.estado).compareTo(_estadoOrder(a.estado)),
        );
        break;
    }
  }

  // MÉTODO PARA CONFIRMAR Y ELIMINAR UNA INCIDENCIA
  Future<void> _confirmDelete(Incident incident) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar incidencia'),
        content: Text(
          'Se eliminara la incidencia "${incident.titulo ?? 'Sin titulo'}". Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await incidentService.deleteIncident(incident.id);
    if (!mounted) return;

    if (ok) {
      setState(() {
        incidents.removeWhere((i) => i.id == incident.id);
        latestCommentsByIncidentId.remove(incident.id);
        commentCountByIncidentId.remove(incident.id);
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

  // MÉTODO PARA OBTENER LA ETIQUETA DE LOS CRITERIOS DE ORDENACIÓN
  String _sortLabel(AdminSortOption option) {
    switch (option) {
      case AdminSortOption.fechaDesc:
        return 'Fecha (mas reciente)';
      case AdminSortOption.direccionAsc:
        return 'Direccion (A-Z)';
      case AdminSortOption.direccionDesc:
        return 'Direccion (Z-A)';
      case AdminSortOption.estadoAsc:
        return 'Estado (Pendiente->Resuelta)';
      case AdminSortOption.estadoDesc:
        return 'Estado (Resuelta->Pendiente)';
    }
  }

  // MÉTODO PARA OBTENER LA ETIQUETA DE LOS ESTADOS
  String _estadoLabel(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En proceso';
      case 'resuelta':
        return 'Resuelta';
      default:
        return estado;
    }
  }

  // MÉTODO PARA CONSTRUIR LOS CHIPS DE FILTRO DE ESTADO
  Widget _buildFiltroChip(String estado, String label, Color color) {
    final activo = filtroEstado == estado;

    return ChoiceChip(
      label: Text(label),
      selected: activo,
      selectedColor: color.withValues(alpha: 0.2),
      onSelected: (_) {
        setState(() {
          filtroEstado = estado;
          loading = true;
        });
        _loadIncidents();
      },
    );
  }

  // MÉTODO BUILD PARA MOSTRAR LA INTERFAZ DE LISTADO DE INCIDENCIAS CON FILTROS,
  //OPCIONES DE ORDENACIÓN, Y BOTONES DE EDICIÓN Y ELIMINACIÓN
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      isAdmin: true,
      title: "Incidencias (Admin)",
      body: Column(
        children: [
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AdminSortOption>(
                  value: sortOption,
                  isExpanded: true,
                  icon: const Icon(Icons.sort),
                  items: AdminSortOption.values
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(_sortLabel(option)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      sortOption = value;
                      _sortIncidents(incidents);
                    });
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // FILTROS DE ESTADO
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildFiltroChip("todos", "Todas", Colors.grey),
                const SizedBox(width: 8),
                _buildFiltroChip("pendiente", "Pendientes", Colors.orange),
                const SizedBox(width: 8),
                _buildFiltroChip("en_proceso", "En proceso", Colors.blue),
                const SizedBox(width: 8),
                _buildFiltroChip("resuelta", "Resueltas", Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LISTA DE INCIDENCIAS
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : incidents.isEmpty
                ? const Center(
                    child: Text(
                      'No hay incidencias para los filtros seleccionados',
                    ),
                  )
                : ListView.builder(
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      final inc = incidents[index];

                      return Stack(
                        children: [
                          IncidentCard(
                            incident: inc,
                            isAlternate: index.isEven,
                            reporterName: reporterNameByUserId[inc.userId],
                            latestComment: latestCommentsByIncidentId[inc.id],
                            commentCount: commentCountByIncidentId[inc.id] ?? 0,
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IncidentDetailPage(
                                    incident: inc.toMap(),
                                    isAdmin: true,
                                  ),
                                ),
                              );

                              if (changed == true && mounted) {
                                setState(() {
                                  loading = true;
                                });
                                _loadIncidents();
                              }
                            },
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton(
                              tooltip: 'Eliminar incidencia',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(inc),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: inc.estado,
                                  isDense: true,
                                  onChanged: updatingStatusIds.contains(inc.id)
                                      ? null
                                      : (value) {
                                          if (value == null) return;
                                          _updateIncidentStatus(inc, value);
                                        },
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'pendiente',
                                      child: Text('Pendiente'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'en_proceso',
                                      child: Text('En proceso'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'resuelta',
                                      child: Text('Resuelta'),
                                    ),
                                  ],
                                  selectedItemBuilder: (context) =>
                                      ['pendiente', 'en_proceso', 'resuelta']
                                          .map(
                                            (estado) => Text(
                                              _estadoLabel(estado),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
