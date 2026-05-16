import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/profile_settings_page.dart';

// Cabecera principal reutilizable para pantallas con titulo y subtitulo.
class MainHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showUserAvatar;

  const MainHeader({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.showUserAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    final trailingActions = <Widget>[
      ...?actions,
      if (showUserAvatar) const _UserAvatarHeaderAction(),
    ];

    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: trailingActions.isEmpty ? null : trailingActions,
      title: Row(
        children: [
          Image.asset("assets/images/Escudo_de_Cantillana.png", height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? "Cantillana",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF2D3436),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF636E72),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _UserAvatarHeaderAction extends StatefulWidget {
  const _UserAvatarHeaderAction();

  @override
  State<_UserAvatarHeaderAction> createState() =>
      _UserAvatarHeaderActionState();
}

class _UserAvatarHeaderActionState extends State<_UserAvatarHeaderAction> {
  final _supabase = Supabase.instance.client;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _readAvatarFromCurrentUser();
  }

  void _readAvatarFromCurrentUser() {
    final metadata = _supabase.auth.currentUser?.userMetadata;
    final value = (metadata?['avatar_url'] ?? '').toString().trim();
    if (!mounted) return;
    setState(() {
      _avatarUrl = value.isNotEmpty ? value : null;
    });
  }

  Future<void> _openProfileSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileSettingsPage()));
    _readAvatarFromCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = (_avatarUrl != null)
        ? NetworkImage(_avatarUrl!)
        : null;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: _openProfileSettings,
        child: CircleAvatar(
          radius: 17,
          backgroundColor: Colors.blue.shade50,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(Icons.person, color: Colors.blueGrey)
              : null,
        ),
      ),
    );
  }
}
