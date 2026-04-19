import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../widgets/incident_card.dart';
import 'detail_incident_page.dart';
import '../widgets/app_scaffold.dart';

class AdminIncidentListPage extends StatefulWidget {
  const AdminIncidentListPage({super.key});

  @override
  State<AdminIncidentListPage> createState() => _AdminIncidentListPageState();
}

class _AdminIncidentListPageState extends State<AdminIncidentListPage> {
  bool loading = true;
  List<Incident> incidents = [];
  String filtroEstado = "todos";

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    final supabase = Supabase.instance.client;

    dynamic data;

    if (filtroEstado == "todos") {
      data = await supabase
          .from('incidencias')
          .select('*')
          .order('created_at', ascending: false);
    } else {
      data = await supabase
          .from('incidencias')
          .select('*')
          .eq('estado', filtroEstado)
          .order('created_at', ascending: false);
    }

    setState(() {
      incidents = (data as List).map((map) => Incident.fromMap(map)).toList();
      loading = false;
    });
  }

  Widget _buildFiltroChip(String estado, String label, Color color) {
    final activo = filtroEstado == estado;

    return ChoiceChip(
      label: Text(label),
      selected: activo,
      selectedColor: color.withOpacity(0.2),
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
                : ListView.builder(
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      final inc = incidents[index];

                      return IncidentCard(
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
