import 'package:flutter/material.dart';

// Boton flotante de retroceso rapido para pantallas secundarias.
class BackFAB extends StatelessWidget {
  const BackFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.blue,
      child: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    );
  }
}
