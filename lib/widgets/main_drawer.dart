import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/screens/user_incidents_page.dart';
import '/screens/user_home_page.dart';
import '/screens/admin_home_page.dart';
import '/screens/admin_incident_list_page.dart';
import '/screens/create_incident_page.dart';
import '/screens/user_comments_page.dart';
import '/screens/user_list_page.dart';
import '/screens/welcome_page.dart';
import '/screens/profile_settings_page.dart';

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

          // SOLO PARA USUARIOS NORMALES
          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Inicio"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const UserHomePage()),
                );
              },
            ),

          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text("Mis incidencias"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserIncidentsPage()),
                );
              },
            ),

          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text("Nueva incidencia"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateIncidentPage()),
                );
              },
            ),

          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text("Mis comentarios"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserCommentsPage()),
                );
              },
            ),

          if (!isAdmin)
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text("Ajustes de perfil"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsPage(),
                  ),
                );
              },
            ),

          // SOLO PARA ADMINISTRADORES
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Panel de administración"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminHomePage()),
                );
              },
            ),

          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text("Lista de incidencias"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminIncidentListPage(),
                  ),
                );
              },
            ),

          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Lista de usuarios"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserListPage()),
                );
              },
            ),

          const Divider(),

          // CERRAR SESIÓN
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
