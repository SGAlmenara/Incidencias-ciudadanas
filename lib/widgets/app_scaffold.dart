import 'package:flutter/material.dart';

import 'main_header.dart';
import 'main_drawer.dart';

// Scaffold comun de la app con header, drawer opcional y FAB configurable.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final List<Widget>? actions;
  final String? title;
  final String? subtitle;
  final bool isAdmin;
  final Widget? floatingActionButton;
  final bool showDrawer;
  final Widget? footer;

  const AppScaffold({
    super.key,
    required this.body,
    this.actions,
    this.title,
    this.subtitle,
    this.isAdmin = false,
    this.floatingActionButton,
    this.showDrawer = true,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainHeader(
        title: title,
        subtitle: subtitle,
        actions: actions,
        showUserAvatar: !isAdmin,
      ),
      drawer: showDrawer ? MainDrawer(isAdmin: isAdmin) : null,
      body: footer != null
          ? Column(
              children: [
                Expanded(child: body),
                footer!,
              ],
            )
          : body,
      floatingActionButton: floatingActionButton,
    );
  }
}
