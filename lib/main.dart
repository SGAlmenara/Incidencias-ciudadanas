import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_page.dart';
import 'screens/home_page.dart';
import 'screens/admin_incident_list_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fttirjxddahuiurvgkzk.supabase.co',
    anonKey: 'sb_publishable_xLdmpjFD4Nkkdl-uLGDFJw_nlhgEQoL',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session =
              snapshot.data?.session ??
              Supabase.instance.client.auth.currentSession;

          // Si NO hay sesión → WelcomePage
          if (session == null) {
            return const WelcomePage();
          }

          // Si hay sesión → comprobar rol
          return FutureBuilder<bool>(
            future: AuthService().isAdmin(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final esAdmin = snap.data!;
              return esAdmin ? const AdminIncidentListPage() : const HomePage();
            },
          );
        },
      ),
    );
  }
}
