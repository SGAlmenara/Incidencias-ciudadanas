import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_user_comments_page.dart';
import 'admin_user_incidents_page.dart';
import '../widgets/app_scaffold.dart';

// PÁGINA EXCLUSIVA PARA ADMINISTRADORES: LISTADO DE TODOS LOS USUARIOS
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  bool loading = true;
  List<Map<String, dynamic>> users = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => loading = true);
    try {
      final supabase = Supabase.instance.client;

      final incidentRows = await supabase
          .from('incidencias')
          .select('user_id, direccion, fecha')
          .order('fecha', ascending: false);

      final incidentCountByUserId = <String, int>{};
      final latestAddressByUserId = <String, String>{};

      for (final row in (incidentRows as List).cast<Map<String, dynamic>>()) {
        final userId = (row['user_id'] ?? '').toString();
        if (userId.isEmpty) continue;

        incidentCountByUserId[userId] =
            (incidentCountByUserId[userId] ?? 0) + 1;

        final direccion = (row['direccion'] ?? '').toString().trim();
        if (direccion.isNotEmpty &&
            !latestAddressByUserId.containsKey(userId)) {
          latestAddressByUserId[userId] = direccion;
        }
      }

      List<Map<String, dynamic>> profileRows;
      try {
        final data = await supabase
            .from('profiles')
            .select('id, nombre, apellidos, email, telefono, direccion, role')
            .order('nombre', ascending: true);
        profileRows = (data as List).cast<Map<String, dynamic>>();
      } catch (_) {
        final data = await supabase
            .from('profiles')
            .select('id, nombre, apellidos, email, telefono, role')
            .order('nombre', ascending: true);
        profileRows = (data as List)
            .cast<Map<String, dynamic>>()
            .map((row) => {...row, 'direccion': null})
            .toList();
      }

      final profileById = <String, Map<String, dynamic>>{};
      for (final row in profileRows) {
        final id = (row['id'] ?? '').toString();
        if (id.isEmpty) continue;
        profileById[id] = row;
      }

      final allUserIds = <String>{
        ...profileById.keys,
        ...incidentCountByUserId.keys,
      };

      final mergedUsers = allUserIds.map((userId) {
        final profile = profileById[userId] ?? const <String, dynamic>{};
        final direccionPerfil = (profile['direccion'] ?? '').toString().trim();

        return {
          'id': userId,
          'nombre': profile['nombre'],
          'apellidos': profile['apellidos'],
          'email': profile['email'],
          'telefono': profile['telefono'],
          'role': profile['role'] ?? 'user',
          'direccion': direccionPerfil.isNotEmpty
              ? direccionPerfil
              : latestAddressByUserId[userId],
          'incidencias_total': incidentCountByUserId[userId] ?? 0,
        };
      }).toList();

      mergedUsers.sort((a, b) {
        final nombreA = '${a['nombre'] ?? ''} ${a['apellidos'] ?? ''}'
            .trim()
            .toLowerCase();
        final nombreB = '${b['nombre'] ?? ''} ${b['apellidos'] ?? ''}'
            .trim()
            .toLowerCase();
        if (nombreA.isNotEmpty && nombreB.isNotEmpty) {
          return nombreA.compareTo(nombreB);
        }

        final emailA = (a['email'] ?? '').toString().toLowerCase();
        final emailB = (b['email'] ?? '').toString().toLowerCase();
        return emailA.compareTo(emailB);
      });

      if (!mounted) return;
      setState(() {
        users = mergedUsers;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando usuarios: $e')));
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (searchQuery.trim().isEmpty) return users;
    final q = searchQuery.trim().toLowerCase();
    return users.where((u) {
      final nombre = '${u['nombre'] ?? ''} ${u['apellidos'] ?? ''}'
          .toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      return nombre.contains(q) || email.contains(q);
    }).toList();
  }

  Future<void> _changeUserRole({
    required String userId,
    required String displayName,
    required String targetRole,
  }) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (targetRole == 'user' && currentUserId == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes quitarte a ti mismo el rol de admin.'),
        ),
      );
      return;
    }

    final token = targetRole == 'admin' ? 'admin' : 'user';
    final actionLabel = targetRole == 'admin'
        ? 'otorgar permisos de administrador'
        : 'cambiar a usuario normal';
    final successLabel = targetRole == 'admin'
        ? '$displayName ahora es administrador.'
        : '$displayName ahora es usuario normal.';

    final confirmController = TextEditingController();
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Confirmar cambio de rol'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vas a $actionLabel a:\n"$displayName".'),
                  const SizedBox(height: 16),
                  Text(
                    'Escribe "$token" para confirmar:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: token,
                      errorText: errorText,
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (confirmController.text.trim().toLowerCase() != token) {
                      setDialogState(
                        () => errorText = 'Debes escribir exactamente "$token"',
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );

    confirmController.dispose();
    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'role': targetRole})
          .eq('id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successLabel)));
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cambiar rol: $e')));
    }
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        splashRadius: 18,
        tooltip: tooltip,
        icon: Icon(icon, size: 18),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Lista de usuarios',
      isAdmin: true,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? const Center(child: Text('No se encontraron usuarios.'))
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final nombre =
                            '${user['nombre'] ?? ''} ${user['apellidos'] ?? ''}'
                                .trim();
                        final email = user['email'] ?? 'Sin email';
                        final telefono = user['telefono'] ?? 'Sin teléfono';
                        final direccion = user['direccion'] ?? 'Sin dirección';
                        final incidenciasTotal =
                            (user['incidencias_total'] ?? 0) as int;
                        final role = user['role'] ?? 'user';
                        final isAdmin = role == 'admin';
                        final userId = (user['id'] ?? '').toString();
                        final displayName = nombre.isEmpty
                            ? (email.toString().trim().isEmpty
                                  ? 'Sin nombre'
                                  : email.toString())
                            : nombre;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: isAdmin
                                      ? Colors.blue.shade700
                                      : Colors.grey.shade400,
                                  child: Icon(
                                    isAdmin
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(email.toString()),
                                      Text(telefono.toString()),
                                      Text(direccion.toString()),
                                      Text(
                                        'Incidencias totales: $incidenciasTotal',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Chip(
                                      label: Text(
                                        isAdmin ? 'Admin' : 'Usuario',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: isAdmin
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade500,
                                      padding: EdgeInsets.zero,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isAdmin)
                                          _buildActionIcon(
                                            icon: Icons.shield_outlined,
                                            tooltip: 'Hacer administrador',
                                            onTap: () {
                                              if (userId.isEmpty) return;
                                              _changeUserRole(
                                                userId: userId,
                                                displayName: displayName,
                                                targetRole: 'admin',
                                              );
                                            },
                                          ),
                                        if (isAdmin)
                                          _buildActionIcon(
                                            icon: Icons.shield_moon_outlined,
                                            tooltip: 'Quitar administrador',
                                            onTap: () {
                                              if (userId.isEmpty) return;
                                              _changeUserRole(
                                                userId: userId,
                                                displayName: displayName,
                                                targetRole: 'user',
                                              );
                                            },
                                          ),
                                        _buildActionIcon(
                                          icon: Icons.assignment_outlined,
                                          tooltip: 'Ver incidencias',
                                          onTap: () {
                                            if (userId.isEmpty) return;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AdminUserIncidentsPage(
                                                      userId: userId,
                                                      userName: displayName,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                        _buildActionIcon(
                                          icon: Icons.forum_outlined,
                                          tooltip: 'Ver comentarios',
                                          onTap: () {
                                            if (userId.isEmpty) return;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AdminUserCommentsPage(
                                                      userId: userId,
                                                      userName: displayName,
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
