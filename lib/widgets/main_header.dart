import 'package:flutter/material.dart';

class MainHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  const MainHeader({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
      title: Row(
        children: [
          Image.asset("assets/images/Escudo_de_Cantillana.png", height: 40),
          const SizedBox(width: 12),
          Text(
            title ?? "Cantillana",
            style: const TextStyle(
              color: Color(0xFF2D3436),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
