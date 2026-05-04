import 'package:flutter/material.dart';

import 'main_header.dart';
import 'main_drawer.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final List<Widget>? actions;
  final String? title;
  final String? subtitle;
  final bool isAdmin;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    this.actions,
    this.title,
    this.subtitle,
    this.isAdmin = false,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainHeader(title: title, subtitle: subtitle),
      drawer: MainDrawer(isAdmin: isAdmin),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
