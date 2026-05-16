import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';
import '../widgets/incident_card.dart';
import 'list_incident_page.dart';
import '../widgets/app_scaffold.dart';

enum AdminSortOption {
  fechaDesc,
  fechaAsc,
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

  bool loading = true;
  List<Incident> incidents = [];
  Map<String, String> latestCommentsByIncidentId = {};
  Map<String, int> commentCountByIncidentId = {};
  Map<String, String> reporterNameByUserId = {};
  final Set<String> updatingStatusIds = <String>{};
  String filtroEstado = "todos";
  String filtroSector = "todos";
  AdminSortOption sortOption = AdminSortOption.fechaDesc;
  final incidentService = IncidentService();
  Map<String, int> sectorCountMap = {};

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  // CARGAR INCIDENCIAS CON FILTRO DE ESTADO Y ORDEN SEGÚN OPCIÓN SELECCIONADA
  Future<void> _loadIncidents() async {
    final supabase = Supabase.instance.client;

    try {
      // Primero aplico filtros en SQL para no traer datos de mas.
      var query = supabase.from('incidencias').select('*');
      if (filtroEstado != 'todos') {
        query = query.eq('estado', filtroEstado);
      }
      if (filtroSector != 'todos') {
        query = query.eq('sector', filtroSector);
      }

      final ascending = sortOption == AdminSortOption.fechaAsc;
      final data = await query.order('fecha', ascending: ascending);

      final loaded = (data as List)
          .map((map) => Incident.fromMap(map))
          .toList();
      _sortIncidents(loaded);

      final countMap = <String, int>{};
      // Este contador se usa para mostrar (cantidad) junto al sector.
      for (final inc in loaded) {
        final sector = (inc.sector ?? 'Otros').trim();
        countMap[sector] = (countMap[sector] ?? 0) + 1;
      }

      final userIds = loaded
          .map((incident) => incident.userId)
          .toSet()
          .toList();
      final reporterMap = <String, String>{};
      if (userIds.isNotEmpty) {
        try {
          final profileRows = await supabase
              .from('profiles')
              .select('id, nombre, apellidos, email')
              .inFilter('id', userIds);

          for (final row
              in (profileRows as List).cast<Map<String, dynamic>>()) {
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
        } catch (e) {
          print('Error cargando perfiles: $e');
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
        sectorCountMap = countMap;
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
        if (filtroSector != 'todos') {
          incidents.removeWhere(
            (i) => i.id == incident.id && i.sector != filtroSector,
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
      if (mounted) {
        setState(() {
          updatingStatusIds.remove(incident.id);
        });
      }
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
      case AdminSortOption.fechaAsc:
        list.sort((a, b) => a.fecha.compareTo(b.fecha));
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
    const labels = <AdminSortOption, String>{
      AdminSortOption.fechaDesc: 'Fecha (mas reciente)',
      AdminSortOption.fechaAsc: 'Fecha (mas antigua)',
      AdminSortOption.direccionAsc: 'Direccion (A-Z)',
      AdminSortOption.direccionDesc: 'Direccion (Z-A)',
      AdminSortOption.estadoAsc: 'Estado (Pendiente->Resuelta)',
      AdminSortOption.estadoDesc: 'Estado (Resuelta->Pendiente)',
    };
    return labels[option] ?? 'Orden';
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

  // MÉTODO BUILD PARA MOSTRAR LA INTERFAZ DE LISTADO DE INCIDENCIAS CON FILTROS,
  //OPCIONES DE ORDENACIÓN, Y BOTONES DE EDICIÓN Y ELIMINACIÓN
  @override
  Widget build(BuildContext context) {
    final totalIncidents = incidents.length;
    final pendientes = incidents.where((i) => i.estado == 'pendiente').length;
    final enProceso = incidents.where((i) => i.estado == 'en_proceso').length;
    final resueltas = incidents.where((i) => i.estado == 'resuelta').length;

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
      isAdmin: true,
      title: "Incidencias (Admin)",
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD7DFEA)),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  value: filtroSector,
                  isExpanded: true,
                  icon: const Icon(Icons.category_outlined),
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
                      filtroSector = value;
                      loading = true;
                    });
                    _loadIncidents();
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // BOTONES FILTRO ESTADO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              alignment: WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final estado in [
                  'todos',
                  'pendiente',
                  'en_proceso',
                  'resuelta',
                ])
                  ChoiceChip(
                    label: Text(
                      estado == 'todos'
                          ? 'Todas'
                          : estado == 'en_proceso'
                          ? 'En proceso'
                          : estado == 'pendiente'
                          ? 'Pendientes'
                          : 'Resueltas',
                    ),
                    selected: filtroEstado == estado,
                    selectedColor: const Color(0xFFDDEBFF),
                    side: const BorderSide(color: Color(0xFFD7DFEA)),
                    labelStyle: TextStyle(
                      color: filtroEstado == estado
                          ? const Color(0xFF1F3B63)
                          : Colors.black87,
                      fontWeight: filtroEstado == estado
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      setState(() {
                        filtroEstado = estado;
                        loading = true;
                      });
                      _loadIncidents();
                    },
                  ),
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
                                onPressed: () => _confirmDelete(inc),
                              ),
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
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFCFE0FF),
                                ),
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
                                                color: Color(0xFF1F3B63),
                                                fontWeight: FontWeight.w600,
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
