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
  String blockFilter = 'all';

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
          .order('fecha', ascending: true);

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

      final blockedEmails = <String>{};
      try {
        final blockedRows = await supabase
            .from('blocked_emails')
            .select('email');
        for (final row in (blockedRows as List).cast<Map<String, dynamic>>()) {
          final email = (row['email'] ?? '').toString().trim().toLowerCase();
          if (email.isNotEmpty) blockedEmails.add(email);
        }
      } catch (_) {
        // If table/policies are not ready yet, list still works without blocked state.
      }

      final allUserIds = <String>{
        ...profileById.keys,
        ...incidentCountByUserId.keys,
      };

      final mergedUsers = allUserIds.map((userId) {
        final profile = profileById[userId] ?? const <String, dynamic>{};
        final direccionPerfil = (profile['direccion'] ?? '').toString().trim();
        final email = (profile['email'] ?? '').toString().trim().toLowerCase();

        return {
          'id': userId,
          'nombre': profile['nombre'],
          'apellidos': profile['apellidos'],
          'email': profile['email'],
          'telefono': profile['telefono'],
          'role': profile['role'] ?? 'user',
          'is_blocked': blockedEmails.contains(email),
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
    final byBlock = users.where((u) {
      final isBlocked = u['is_blocked'] == true;
      if (blockFilter == 'blocked') return isBlocked;
      if (blockFilter == 'active') return !isBlocked;
      return true;
    }).toList();

    if (searchQuery.trim().isEmpty) return byBlock;
    final q = searchQuery.trim().toLowerCase();
    return byBlock.where((u) {
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

    String typedToken = '';
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
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: token,
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      typedToken = value;
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
                    if (typedToken.trim().toLowerCase() != token) {
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

    if (confirmed != true || !mounted) return;

    try {
      final updated = await Supabase.instance.client
          .from('profiles')
          .update({'role': targetRole})
          .eq('id', userId)
          .select('id, role')
          .maybeSingle();

      if (updated == null) {
        throw PostgrestException(
          message:
              'No se pudo actualizar el rol. Revisa las politicas RLS para UPDATE en profiles.',
          code: 'PGRST116',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successLabel)));
      await _loadUsers();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = (e.message).isNotEmpty
          ? e.message
          : 'Error de permisos al cambiar rol.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cambiar rol: $msg')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cambiar rol: $e')));
    }
  }

  Future<void> _confirmDeleteUser({
    required String userId,
    required String displayName,
  }) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar tu propio usuario administrador.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          'Se eliminara el usuario "$displayName" y sus datos asociados. Esta accion no se puede deshacer.',
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

    if (confirm != true || !mounted) return;

    try {
      final supabase = Supabase.instance.client;

      final userIncidentRows = await supabase
          .from('incidencias')
          .select('id')
          .eq('user_id', userId);

      final incidentIds = (userIncidentRows as List)
          .map((row) => (row['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      if (incidentIds.isNotEmpty) {
        await supabase
            .from('incidencia_comentarios')
            .delete()
            .inFilter('incidencia_id', incidentIds);
      }

      await supabase
          .from('incidencia_comentarios')
          .delete()
          .eq('autor_id', userId);

      await supabase.from('incidencias').delete().eq('user_id', userId);

      final deletedProfile = await supabase
          .from('profiles')
          .delete()
          .eq('id', userId)
          .select('id');

      if (!mounted) return;

      if ((deletedProfile as List).isNotEmpty) {
        setState(() {
          users.removeWhere((u) => (u['id'] ?? '').toString() == userId);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el usuario')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar usuario: $e')));
    }
  }

  Future<void> _confirmToggleEmailBlock({
    required String email,
    required String displayName,
    required bool isBlocked,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede gestionar: el usuario no tiene email.'),
        ),
      );
      return;
    }

    final token = isBlocked ? 'desbloquear' : 'bloquear';
    final title = isBlocked
        ? 'Desbloquear registro por email'
        : 'Bloquear registro por email';
    final actionVerb = isBlocked ? 'desbloquear' : 'bloquear';
    final effectMessage = isBlocked
        ? 'Este correo podra volver a registrarse en la app.'
        : 'Este correo no podra volver a registrarse en la app.';
    final confirmButtonLabel = isBlocked ? 'Desbloquear' : 'Bloquear';
    final successMessage = isBlocked
        ? 'Email desbloqueado correctamente.'
        : 'Email bloqueado correctamente.';

    String typedToken = '';
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vas a $actionVerb el email de "$displayName".'),
                  const SizedBox(height: 6),
                  Text(
                    normalizedEmail,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isBlocked
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(effectMessage),
                  const SizedBox(height: 16),
                  Text(
                    'Escribe "$token" para confirmar:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: token,
                      errorText: errorText,
                    ),
                    onChanged: (value) {
                      typedToken = value;
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
                    if (typedToken.trim().toLowerCase() != token) {
                      setDialogState(
                        () => errorText = 'Debes escribir exactamente "$token"',
                      );
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBlocked
                        ? Colors.green.shade700
                        : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(confirmButtonLabel),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      if (isBlocked) {
        final deleted = await Supabase.instance.client
            .from('blocked_emails')
            .delete()
            .eq('email', normalizedEmail)
            .select('email');

        if ((deleted as List).isEmpty) {
          throw PostgrestException(
            message:
                'No se pudo desbloquear el email. Revisa la tabla/politicas de blocked_emails.',
            code: 'PGRST116',
          );
        }
      } else {
        final inserted = await Supabase.instance.client
            .from('blocked_emails')
            .upsert({'email': normalizedEmail})
            .select('email')
            .maybeSingle();

        if (inserted == null) {
          throw PostgrestException(
            message:
                'No se pudo bloquear el email. Revisa la tabla/politicas de blocked_emails.',
            code: 'PGRST116',
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
      await _loadUsers();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final msg = e.message.isNotEmpty
          ? e.message
          : isBlocked
          ? 'Error de permisos al desbloquear email.'
          : 'Error de permisos al bloquear email.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlocked
                ? 'Error al desbloquear: $msg'
                : 'Error al bloquear: $msg',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBlocked ? 'Error al desbloquear: $e' : 'Error al bloquear: $e',
          ),
        ),
      );
    }
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color backgroundColor = const Color(0xFFF2F5FA),
    Color borderColor = const Color(0xFFD7DFEA),
    Color iconColor = const Color(0xFF1F3B63),
  }) {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        splashRadius: 18,
        tooltip: tooltip,
        icon: Icon(icon, size: 18, color: iconColor),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;
    final totalUsers = users.length;
    final blockedUsers = users.where((u) => u['is_blocked'] == true).length;
    final adminUsers = users
        .where((u) => (u['role'] ?? 'user').toString() == 'admin')
        .length;

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
      title: 'Lista de usuarios',
      isAdmin: true,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
                statTile('Usuarios', '$totalUsers', const Color(0xFFDDEBFF)),
                statTile('Admins', '$adminUsers', const Color(0xFFE2F4FF)),
                statTile(
                  'Bloqueados',
                  '$blockedUsers',
                  const Color(0xFFFFE7E7),
                ),
                statTile(
                  'Mostrados',
                  '${filteredUsers.length}',
                  const Color(0xFFE8F8EC),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF003366),
                    width: 1.4,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: blockFilter == 'all',
                  selectedColor: const Color(0xFFDDEBFF),
                  side: const BorderSide(color: Color(0xFFD7DFEA)),
                  onSelected: (_) => setState(() => blockFilter = 'all'),
                ),
                ChoiceChip(
                  label: const Text('No bloqueados'),
                  selected: blockFilter == 'active',
                  selectedColor: const Color(0xFFE8F8EC),
                  side: const BorderSide(color: Color(0xFFD7DFEA)),
                  onSelected: (_) => setState(() => blockFilter = 'active'),
                ),
                ChoiceChip(
                  label: const Text('Bloqueados'),
                  selected: blockFilter == 'blocked',
                  selectedColor: const Color(0xFFFFE7E7),
                  side: const BorderSide(color: Color(0xFFD7DFEA)),
                  onSelected: (_) => setState(() => blockFilter = 'blocked'),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? const Center(child: Text('No se encontraron usuarios.'))
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
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
                        final isBlocked = user['is_blocked'] == true;
                        final userId = (user['id'] ?? '').toString();
                        final displayName = nombre.isEmpty
                            ? (email.toString().trim().isEmpty
                                  ? 'Sin nombre'
                                  : email.toString())
                            : nombre;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Color(0xFFDFE6F0)),
                          ),
                          elevation: 0,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
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
                                    if (isBlocked)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Chip(
                                          label: const Text(
                                            'Bloqueado',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          backgroundColor: Colors.red.shade700,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!isAdmin)
                                          _buildActionIcon(
                                            icon: Icons.shield_outlined,
                                            tooltip: 'Hacer administrador',
                                            backgroundColor: const Color(
                                              0xFFEAF2FF,
                                            ),
                                            borderColor: const Color(
                                              0xFFCFE0FF,
                                            ),
                                            iconColor: const Color(0xFF1F3B63),
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
                                            backgroundColor: const Color(
                                              0xFFEAF2FF,
                                            ),
                                            borderColor: const Color(
                                              0xFFCFE0FF,
                                            ),
                                            iconColor: const Color(0xFF1F3B63),
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
                                          backgroundColor: const Color(
                                            0xFFEAF2FF,
                                          ),
                                          borderColor: const Color(0xFFCFE0FF),
                                          iconColor: const Color(0xFF1F3B63),
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
                                          backgroundColor: const Color(
                                            0xFFEAF2FF,
                                          ),
                                          borderColor: const Color(0xFFCFE0FF),
                                          iconColor: const Color(0xFF1F3B63),
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
                                        _buildActionIcon(
                                          icon: isBlocked
                                              ? Icons.lock_open_outlined
                                              : Icons.block_outlined,
                                          tooltip: isBlocked
                                              ? 'Desbloquear registro por email'
                                              : 'Bloquear registro por email',
                                          backgroundColor: isBlocked
                                              ? const Color(0xFFE8F8EC)
                                              : const Color(0xFFFFF2CC),
                                          borderColor: isBlocked
                                              ? const Color(0xFFC8EBD1)
                                              : const Color(0xFFF2D994),
                                          iconColor: isBlocked
                                              ? const Color(0xFF1C7C3E)
                                              : const Color(0xFF8A6B00),
                                          onTap: () {
                                            _confirmToggleEmailBlock(
                                              email: email.toString(),
                                              displayName: displayName,
                                              isBlocked: isBlocked,
                                            );
                                          },
                                        ),
                                        _buildActionIcon(
                                          icon: Icons.delete_outline,
                                          tooltip: 'Eliminar usuario',
                                          backgroundColor: const Color(
                                            0xFFFFECEC,
                                          ),
                                          borderColor: const Color(0xFFF6C9C9),
                                          iconColor: const Color(0xFFC62828),
                                          onTap: () {
                                            if (userId.isEmpty) return;
                                            _confirmDeleteUser(
                                              userId: userId,
                                              displayName: displayName,
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
