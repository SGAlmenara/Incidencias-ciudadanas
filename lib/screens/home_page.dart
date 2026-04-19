import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident.dart';
import '../widgets/incident_card.dart';
import '../screens/create_incident_page.dart';
import 'detail_incident_page.dart';
import '../services/auth_service.dart';
import '../widgets/app_scaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  final auth = AuthService();

  String estadoFiltro = "todos";

  bool isAdmin = false;
  bool loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    isAdmin = await auth.isAdmin();
    setState(() => loadingRole = false);
  }

  Future<List<Incident>> _loadIncidents() async {
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

    return (response as List).map((map) => Incident.fromMap(map)).toList();
  }

  Widget _buildFiltro(String valor, String texto) {
    final activo = estadoFiltro == valor;

    return GestureDetector(
      onTap: () {
        setState(() {
          estadoFiltro = valor;
        });
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
            child: FutureBuilder(
              future: _loadIncidents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final incidents = snapshot.data!;

                if (incidents.isEmpty) {
                  return const Center(child: Text("No hay incidencias"));
                }

                return ListView.builder(
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
                              isAdmin: isAdmin,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateIncidentPage()),
          );
        },
      ),
    );
  }
}
