import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';
import '../widgets/incident_card.dart';
import 'detail_incident_page.dart';
import '../widgets/app_scaffold.dart';

enum AdminSortOption {
  fechaDesc,
  direccionAsc,
  direccionDesc,
  estadoAsc,
  estadoDesc,
}

class AdminIncidentListPage extends StatefulWidget {
  const AdminIncidentListPage({super.key});

  @override
  State<AdminIncidentListPage> createState() => _AdminIncidentListPageState();
}

class _AdminIncidentListPageState extends State<AdminIncidentListPage> {
  bool loading = true;
  List<Incident> incidents = [];
  final Set<String> updatingStatusIds = <String>{};
  String filtroEstado = "todos";
  AdminSortOption sortOption = AdminSortOption.fechaDesc;
  final incidentService = IncidentService();

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

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

      if (!mounted) return;
      setState(() {
        incidents = loaded;
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

          // FILTROS
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

          // LISTA
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IncidentDetailPage(
                                    incident: inc.toMap(),
                                    isAdmin: true,
                                  ),
                                ),
                              );
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
