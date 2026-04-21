import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_incident_list_page.dart';
import 'home_page.dart';
import 'welcome_page.dart';

// PÁGINA INTERMEDIA PARA REDIRIGIR SEGÚN ROL
class RoleGate extends StatefulWidget {
  const RoleGate({super.key});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

// Página que se muestra después del login para redirigir al usuario a la página
//correspondiente según su rol (administrador o usuario normal).
//Carga el rol del usuario desde la base de datos y muestra un indicador de carga
// mientras se obtiene la información. Si el usuario es administrador,
//se muestra la página de administración; si es un usuario normal, se muestra la página principal.
class _RoleGateState extends State<RoleGate> {
  bool loading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  // Método para cargar el rol del usuario desde la base de datos. Si no hay un usuario autenticado,
  //se redirige a la página de bienvenida. Si se obtiene el rol correctamente,
  //se actualiza el estado para mostrar la página correspondiente.
  Future<void> _loadRole() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (route) => false,
      );
      return;
    }

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    final role = data?['role'];

    setState(() {
      isAdmin = role == 'admin';
      loading = false;
    });
  }

  // Método build para mostrar la interfaz de carga mientras se obtiene el rol del usuario.
  //Una vez que se carga el rol, se redirige a la página correspondiente según si el usuario
  //es administrador o no.
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isAdmin) {
      return const AdminIncidentListPage();
    }

    return const HomePage();
  }
}
