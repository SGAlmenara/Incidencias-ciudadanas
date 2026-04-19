import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainDrawer extends StatelessWidget {
  final bool isAdmin;

  const MainDrawer({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "Menú",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),

          // OPCIÓN USUARIO NORMAL
          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Mis incidencias"),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),

          // OPCIÓN ADMIN
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Panel de administración"),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/admin');
              },
            ),

          const Divider(),

          // CERRAR SESIÓN
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
